import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recap_today/constants.dart';
import 'package:recap_today/provider/checklist_provider.dart';
import 'package:recap_today/provider/diary_provider.dart';
import 'package:recap_today/provider/login_provider.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:recap_today/repository/auth_repository.dart';
import 'package:recap_today/repository/impl/auth_repository_impl.dart';
import 'package:recap_today/screens/main_screen.dart';
import 'package:recap_today/theme/darkTheme.dart';
import 'package:recap_today/theme/lightTheme.dart';

import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChecklistProvider()),
        ChangeNotifierProvider(create: (context) => ScheduleProvider()),
        ChangeNotifierProvider(create: (context) => DiaryProvider()),
        ChangeNotifierProvider(
          create: (context) => LoginProvider(authRepository),
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recap Today',
      theme: lightTheme,
      //darkTheme: darkTheme,
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
