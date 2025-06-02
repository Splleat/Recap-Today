import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' as kakao_map;

import 'package:recap_today/constants.dart';
import 'package:recap_today/provider/checklist_provider.dart';
import 'package:recap_today/provider/diary_provider.dart';
import 'package:recap_today/provider/login_provider.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:recap_today/provider/signup_provider.dart'; // SignupProvider import
import 'package:recap_today/provider/user_profile_provider.dart'; // UserProfileProvider import
import 'package:recap_today/repository/auth_repository.dart';
import 'package:recap_today/repository/impl/auth_repository_impl.dart';
import 'package:recap_today/screens/main_screen.dart';
import 'package:recap_today/theme/lightTheme.dart';
import 'package:recap_today/theme/darkTheme.dart';
import 'package:recap_today/provider/weather_provider.dart';
import 'package:recap_today/api/weather_service.dart';
import 'package:recap_today/api/location_service.dart';
import 'package:recap_today/service/location_tracking_service.dart';
import 'package:recap_today/provider/step_provider.dart';
import 'package:recap_today/provider/theme_provider.dart';
import 'package:recap_today/provider/login_provider.dart';
import 'package:recap_today/repository/emotion_repository.dart';
import 'package:recap_today/dao/emotion_dao.dart';
import 'package:recap_today/repository/abstract_emotion_repository.dart';

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

  final dio = Dio(BaseOptions(baseUrl: kBaseUrl));
  final sharedPreferences = await SharedPreferences.getInstance();

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
        Provider<AuthRepository>(
          create: (_) => authRepository,
        ),
        ChangeNotifierProvider(create: (context) => LoginProvider(authRepository)..initTemporaryUserId()),
        // EmotionRepository Provider 추가
        ChangeNotifierProvider(create: (context) => StepProvider()..initialize(context)),
        ChangeNotifierProvider(
          create: (context) => WeatherProvider(WeatherService()),
        ),
        ChangeNotifierProvider(create: (context) => checklistProvider),
        ChangeNotifierProvider(create: (context) => ScheduleProvider()),
        ChangeNotifierProvider(create: (context) => DiaryProvider()),
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
        Provider<AbstractEmotionRepository>(
          create: (_) => EmotionRepository(EmotionDao()), // EmotionRepository 제공
        ),
      ],
      child: const RecapToday(),
    ),
  );
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
