import 'package:flutter/material.dart';
import 'package:recap_today/widget/background.dart';
import 'package:recap_today/router.dart';
import 'package:recap_today/widget/home/home_checklist.dart';
import 'package:recap_today/widget/home/home_schedule.dart';
import 'package:recap_today/widget/home/hourly_emotion_logger.dart';
import 'package:recap_today/provider/weather_provider.dart';
import 'package:provider/provider.dart';
import 'package:recap_today/widget/summary/step_counter.dart';
import 'package:recap_today/settings/setting_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final today = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final weatherProvider = context.read<WeatherProvider>();
      await weatherProvider.fetchWeather(today);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Recap Today'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: commonTabDecoration(context)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                // Wrap Column with SingleChildScrollView
                child: Column(
                  children: [
                    HomeSchedule(date: DateTime.now()),
                    const SizedBox(height: 16),
                    StepWidget(),
                    const SizedBox(height: 16),
                    SettingsCard(
                      children: [
                        ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeChecklist(),
                              ),
                            );
                          },
                          title: const Text('할 일을 확인하세요'),
                          trailing: const Icon(Icons.arrow_forward),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          tileColor: Theme.of(context).colorScheme.surface, // 기본 테마 색상 사용
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    HourlyEmotionLogger(initialDate: DateTime.now()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
