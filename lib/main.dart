import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/provider/checklist_provider.dart';
import 'package:recap_today/provider/schedule_provider.dart';
import 'package:recap_today/screens/main_screen.dart';
import 'package:recap_today/theme/lightTheme.dart';
import 'package:recap_today/theme/darkTheme.dart';
import 'router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChecklistProvider()),
        ChangeNotifierProvider(create: (context) => ScheduleProvider()),
      ],
      child: const RecapToday(),
    ),
  );
}

class RecapToday extends StatelessWidget {
  const RecapToday({super.key});

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recap Today',
      //theme: lightTheme,
      //darkTheme: darkTheme,
      home: const MainScreen(),
      onGenerateRoute: AppRouter.generateRoute,
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
