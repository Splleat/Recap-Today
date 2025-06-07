import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/weather_provider.dart';
import '../provider/login_provider.dart';
import '../data/sqflite_database.dart';
// Import other necessary providers for data fetching
// e.g., import '../provider/diary_provider.dart';
// e.g., import '../provider/schedule_provider.dart';
// e.g., import '../provider/checklist_provider.dart';
// e.g., import '../provider/photo_summary_provider.dart';
// e.g., import '../provider/app_usage_provider.dart';
// e.g., import '../provider/location_history_provider.dart'; // 하루 동선
// e.g., import '../provider/health_metrics_provider.dart'; // 걸음 수, 이동 거리

class PromptService {
  Future<String> generateFeedbackPrompt(
    BuildContext context,
    DateTime date,
  ) async {
    // Format the date to a string if needed for your providers
    final dateString =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    // --- 1. Fetch Data from various providers ---
    // You'll need to replace these with actual calls to your providers
    // Make sure to handle cases where data might be null or empty.

    // 하루 동선 (Location History)
    // final locationHistoryProvider = Provider.of<LocationHistoryProvider>(context, listen: false);
    // final pathData = await locationHistoryProvider.getPathForDate(dateString);
    String dailyPathSummary = "오늘의 주요 동선 기록이 없습니다.";
    // if (pathData != null && pathData.isNotEmpty) {
    //   dailyPathSummary = "오늘의 주요 동선:\n${pathData.map((p) => "${p.time}: ${p.locationName} (머문 시간: ${p.durationMinutes}분)").join("\n")}";
    // }

    // 걸음 수 및 이동 거리 (Health Metrics)
    // final healthMetricsProvider = Provider.of<HealthMetricsProvider>(context, listen: false);
    // final steps = await healthMetricsProvider.getStepsForDate(dateString);
    // final distance = await healthMetricsProvider.getDistanceForDate(dateString);
    String healthMetricsSummary = "오늘의 걸음 수 및 이동 거리 기록이 없습니다.";
    // String stepsStr = steps != null ? "${steps}보" : "걸음 수 정보 없음";
    // String distanceStr = distance != null ? "${(distance / 1000).toStringAsFixed(2)}km" : "이동 거리 정보 없음";
    // if (steps != null || distance != null) {
    //   healthMetricsSummary = "활동량: ${stepsStr} / ${distanceStr}";
    // }

    // 앱 사용시간 (App Usage)
    // final appUsageProvider = Provider.of<AppUsageProvider>(context, listen: false);
    // final appUsageStats = await appUsageProvider.getAppUsageForDate(dateString);
    String appUsageSummary = "오늘 앱 사용 기록이 없습니다.";
    // if (appUsageStats.isNotEmpty) {
    //   appUsageSummary = "오늘의 주요 앱 사용:\n${appUsageStats.map((usage) => "${usage.appName}: ${usage.durationInMinutes}분").join("\n")}";
    // }

    // 체크리스트 (Checklist)
    // final checklistProvider = Provider.of<ChecklistProvider>(context, listen: false);
    // final checklists = await checklistProvider.getChecklistsByDate(dateString);
    String checklistSummary = "오늘의 체크리스트 항목이 없습니다.";
    // if (checklists.isNotEmpty) {
    //   final completedItems = checklists.where((item) => item.isCompleted).toList();
    //   final pendingItems = checklists.where((item) => !item.isCompleted).toList();
    //   checklistSummary = "";
    //   if (completedItems.isNotEmpty) {
    //     checklistSummary += "완료한 항목: ${completedItems.map((item) => item.task).join(', ')}\n";
    //   } else {
    //     checklistSummary += "완료한 항목이 없습니다.\n";
    //   }
    //   if (pendingItems.isNotEmpty) {
    //     checklistSummary += "남은 항목: ${pendingItems.map((item) => item.task).join(', ')}";
    //   } else {
    //     checklistSummary += "남은 항목이 없습니다.";
    //   }
    // }

    // 스케줄 (Schedule)
    // final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    // final schedules = await scheduleProvider.getSchedulesByDate(dateString);
    String scheduleSummary = "오늘 등록된 일정이 없습니다.";
    // if (schedules.isNotEmpty) {
    //   scheduleSummary = "오늘의 일정:\n${schedules.map((s) => "${s.time}: ${s.title}").join("\n")}";
    // }

    // 감정 변화 그래프 (Mood) using database
    final userId =
        Provider.of<LoginProvider>(context, listen: false).activeUserId;
    final db = Provider.of<SqfliteDatabase>(context, listen: false);
    final moodChanges = await db.getEmotionsByDate(dateString, userId);
    String? moodChartSummary;
    if (moodChanges.isNotEmpty) {
      moodChartSummary =
          "오늘의 감정 변화:\n${moodChanges.map((m) => "${m.hour.toString().padLeft(2, '0')}:00 - ${m.emotionType}" + (m.notes != null && m.notes!.isNotEmpty ? " (메모: ${m.notes})" : "")).join("\n")}";
    }

    // 내일의 날씨 예보 (Weather)
    final weatherProv = Provider.of<WeatherProvider>(context, listen: false);
    final tomorrow = date.add(Duration(days: 1));
    await weatherProv.fetchWeather(tomorrow);
    final weatherData = weatherProv.getWeather(tomorrow);
    String? weatherSummary;
    if (weatherData != null && weatherData.isNotEmpty) {
      weatherSummary =
          "내일의 시간별 날씨:\n${weatherData.map((w) => "${w.time}: ${w.temperature}°, ${w.sky} (강수확률: ${w.precipitationProbability})").join("\n")}";
    }

    // --- 2. Construct the Prompt ---
    // This is a basic template. You should refine it based on how you want the AI to respond.
    StringBuffer promptBuffer = StringBuffer();
    promptBuffer.writeln(
      "다음은 사용자의 ${date.month}월 ${date.day}일 하루 활동 및 기록 요약입니다.",
    );
    promptBuffer.writeln(
      "이 정보를 바탕으로 사용자가 하루를 의미있게 돌아보고, 내일을 더 잘 계획할 수 있도록 건설적이고 통찰력 있는 피드백을 제공해주세요.",
    );
    promptBuffer.writeln(
      "피드백은 친근하고 격려하는 어투로 작성해주세요. 각 항목에 대해 개별적으로 언급하기보다는 전체적인 내용을 종합하여 조언해주세요.",
    );
    promptBuffer.writeln("--------------------");
    promptBuffer.writeln("### 하루 동선");
    promptBuffer.writeln(dailyPathSummary);
    promptBuffer.writeln("--------------------");
    promptBuffer.writeln("### 걸음 수 및 이동 거리");
    promptBuffer.writeln(healthMetricsSummary);
    promptBuffer.writeln("--------------------");
    promptBuffer.writeln("### 앱 사용 시간");
    promptBuffer.writeln(appUsageSummary);
    promptBuffer.writeln("--------------------");
    promptBuffer.writeln("### 체크리스트 현황");
    promptBuffer.writeln(checklistSummary);
    promptBuffer.writeln("--------------------");
    promptBuffer.writeln("### 주요 일정");
    promptBuffer.writeln(scheduleSummary);
    promptBuffer.writeln("--------------------");
    if (moodChartSummary != null) {
      promptBuffer.writeln("--------------------");
      promptBuffer.writeln("### 감정 변화 기록");
      promptBuffer.writeln(moodChartSummary);
    }
    if (weatherSummary != null) {
      promptBuffer.writeln("### 내일 날씨 예보");
      promptBuffer.writeln(weatherSummary);
      promptBuffer.writeln("--------------------");
    }
    promptBuffer.writeln(
      "위 정보를 종합적으로 분석하여 사용자에게 가장 도움이 될 만한 조언, 격려, 또는 자기 성찰 질문을 2-3문장으로 요약하여 전달해주세요.",
    );
    promptBuffer.writeln(
      "만약 특정 데이터가 부족하거나 없다면, 해당 부분은 언급하지 않거나 기록을 독려하는 방식으로 부드럽게 넘어갈 수 있습니다.",
    );

    return promptBuffer.toString();
  }
}
