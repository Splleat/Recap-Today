import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao_map;

import 'package:recap_today/constants.dart';
import 'package:recap_today/data/abstract_database.dart';
import 'package:recap_today/data/sqflite_database.dart';
import 'package:recap_today/provider/checklist_provider.dart';
import 'package:recap_today/provider/diary_provider.dart';
import 'package:recap_today/provider/login_provider.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:recap_today/provider/signup_provider.dart'; // SignupProvider import
import 'package:recap_today/provider/user_profile_provider.dart'; // UserProfileProvider import
import 'package:recap_today/repository/abstract_emotion_repository.dart'; // 추가
import 'package:recap_today/repository/auth_repository.dart';
import 'package:recap_today/repository/emotion_repository.dart'; // 추가
import 'package:recap_today/repository/impl/auth_repository_impl.dart';
import 'package:recap_today/screens/main_screen.dart';
import 'package:recap_today/service/date_change_service.dart';
import 'package:recap_today/theme/lightTheme.dart';
import 'package:recap_today/theme/darkTheme.dart';
import 'package:recap_today/provider/weather_provider.dart';
import 'package:recap_today/api/weather_service.dart';
import 'package:recap_today/api/location_service.dart';
import 'package:recap_today/service/location_tracking_service.dart';
import 'package:recap_today/provider/step_provider.dart';
import 'package:recap_today/provider/theme_provider.dart';
import 'package:recap_today/provider/location_provider.dart';

import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Kakao Map with error handling
  try {
    kakao_map.AuthRepository.initialize(
      appKey: '7341c18ac0804aea8c7b1f26fdda3569',
    );
    print('Kakao Map initialized successfully');
  } catch (e) {
    print('Kakao Map initialization failed: $e');
  }

  // Initialize Location Tracking Service
  LocationTrackingService.instance.initialize();

  // [추가] 앱 라이프사이클 감지 및 종료 시 dispose 호출
  WidgetsBinding.instance.addObserver(MyAppLifecycleObserver());

  final dio = Dio(BaseOptions(baseUrl: kBaseUrl));
  final sharedPreferences = await SharedPreferences.getInstance();
  final database = SqfliteDatabase();
  final locationService = LocationService(database);

  final AuthRepository authRepository = AuthRepositoryImpl(
    dio,
    sharedPreferences,
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = authRepository.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
    ),
  );

  // Provider 초기화
  final checklistProvider = ChecklistProvider();

  runApp(
    MultiProvider(
      providers: [
        // 데이터베이스 Provider 추가
        Provider<AbstractDatabase>(create: (_) => database),
        // LocationService Provider 추가
        Provider<LocationService>(create: (_) => locationService),
        // EmotionRepository Provider 추가
        ProxyProvider<AbstractDatabase, AbstractEmotionRepository>(
          update: (context, db, previous) {
            // EmotionRepository now accepts AbstractDatabase directly.
            return EmotionRepository(db);
          },
        ),
        ChangeNotifierProvider(
          create: (context) => StepProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => WeatherProvider(WeatherService()),
        ),
        ChangeNotifierProvider(create: (context) => checklistProvider),
        ChangeNotifierProvider(create: (context) => ScheduleProvider()),
        ChangeNotifierProvider(create: (context) => DiaryProvider()),
        ChangeNotifierProvider(
          create: (context) => LoginProvider(authRepository),
        ),
        ChangeNotifierProvider(
          // Add SignupProvider
          create: (context) => SignupProvider(authRepository),
        ),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProxyProvider<LoginProvider, UserProfileProvider>(
          create: (context) => UserProfileProvider(authRepository),
          update:
              (context, loginProvider, previous) =>
                  UserProfileProvider(authRepository, loginProvider),
        ),
        Provider<AuthRepository>(create: (_) => authRepository),
        ChangeNotifierProvider(
          create:
              (context) => LocationProvider(
                Provider.of<LocationService>(context, listen: false),
                LocationTrackingService.instance,
              ),
        ),
      ],
      child: const RecapToday(),
    ),
  );

  // 앱 시작 후 위치 추적 자동 시작 (local_user 기준)
  Future.microtask(() async {
    try {
      const userId = 'local_user';
      await LocationTrackingService.instance.startTracking(userId);
    } catch (e) {
      debugPrint('위치 추적 자동 시작 중 오류 발생: $e');
    }
  });

  // 앱 시작 후 날짜 변경 확인 (비동기적으로 실행하여 앱 시작 지연 방지)
  Future.microtask(() async {
    try {
      await DateChangeService.checkForDateChange(checklistProvider);
    } catch (e) {
      debugPrint('날짜 변경 확인 중 오류 발생: $e');
    }
  });
}

// [추가] 앱 라이프사이클 감지용 Observer
class MyAppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // 앱 완전 종료 시 리소스 해제
      LocationTrackingService.instance.dispose();
    }
  }
}

class RecapToday extends StatelessWidget {
  const RecapToday({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recap Today',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.themeMode,
      home: const MainScreen(),
      onGenerateRoute: AppRouter.generateRoute,
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
