import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/weather_provider.dart';
import '../provider/login_provider.dart';
import '../data/sqflite_database.dart';
import 'app_usage_service.dart';

class PromptService {
  Future<String> generateFeedbackPrompt(
    BuildContext context,
    DateTime date,
  ) async {
    final dateString =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    // 사용자 및 DB 인스턴스 초기화
    final userId =
        Provider.of<LoginProvider>(context, listen: false).activeUserId;
    final db = Provider.of<SqfliteDatabase>(context, listen: false);

    // 걸음 수 및 이동 거리 (Health Metrics)
    final stepModel = await db.getStepsByDate(dateString, userId);
    String? healthMetricsSummary;
    if (stepModel != null) {
      healthMetricsSummary = "걸음 수: ${stepModel.stepCount}보";
    }

    // 앱 사용시간 (App Usage)
    final appUsageService = AppUsageService(db);
    final appUsageSummaryData = await appUsageService.getAppUsageSummaryForDate(
      dateString,
      userId,
    );
    // 앱 사용 기록 요약 문자열 생성
    String? appUsageSummary;
    if (appUsageSummaryData != null) {
      final sb = StringBuffer();
      final totalStr = AppUsageService.formatUsageTime(
        appUsageSummaryData.totalUsageTimeInMillis,
      );
      sb.writeln('총 사용 시간: $totalStr');
      if (appUsageSummaryData.topApps.isNotEmpty) {
        sb.writeln('상위 앱 사용:');
        for (var app in appUsageSummaryData.topApps) {
          sb.writeln(
            '- ${app.appName}: ${AppUsageService.formatUsageTime(app.usageTimeInMillis)}',
          );
        }
      }
      appUsageSummary = sb.toString().trim();
    }

    // 체크리스트 (Checklist)
    final completedItems = await db.getChecklistItemsByCompletedDate(
      dateString,
      userId,
    );
    final pendingItems = await db.getIncompleteChecklistItems(userId);
    String? checklistSummary;
    if (completedItems.isNotEmpty || pendingItems.isNotEmpty) {
      final sb = StringBuffer();
      if (completedItems.isNotEmpty) {
        sb.writeln(
          "완료한 항목: ${completedItems.map((item) => item.text).join(', ')}",
        );
      }
      if (pendingItems.isNotEmpty) {
        sb.writeln(
          "남은 항목: ${pendingItems.map((item) => item.text).join(', ')}",
        );
      }
      checklistSummary = sb.toString().trim();
    }

    // 스케줄 (Schedule)
    String? scheduleSummary;
    final schedules = await db.getScheduleItemsByDate(dateString, userId);
    if (schedules.isNotEmpty) {
      scheduleSummary =
          "오늘의 일정:\n${schedules.map((s) => "${s.startTime.format(context)} - ${s.text}${s.subText != null ? ' (${s.subText})' : ''}").join("\n")}";
    }

    // 감정 변화 그래프 (Mood) using database
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

    // 프롬프트 생성
    StringBuffer promptBuffer = StringBuffer();
    promptBuffer.writeln(
      "다음은 사용자의 ${date.month}월 ${date.day}일 하루 활동 및 기록 요약입니다.",
    );
    promptBuffer.writeln(
      "이 정보를 바탕으로 사용자가 하루를 의미있게 돌아보고, 내일을 더 잘 계획할 수 있도록 건설적이고 통찰력 있는 피드백이 필요합니다.",
    );
    promptBuffer.writeln(
      "피드백은 친근하고 격려하는 어투로 작성해주세요. 아래 각 정보 항목에 대해 개별적으로 구체적인 조언이나 생각을 아주 간결하게 전달해주세요.",
    );
    promptBuffer.writeln(
      "예를 들어, '내일 날씨 예보' 항목이 있다면 내일의 옷차림이나 우산 필요 여부에 대해 언급하고, '앱 사용 시간'이 많았다면 사용 시간 조절에 대한 팁을 주는 것처럼요.",
    );
    if (healthMetricsSummary != null) {
      promptBuffer.writeln("### 걸음 수 및 이동 거리");
      promptBuffer.writeln(healthMetricsSummary);
    }
    if (appUsageSummary != null) {
      promptBuffer.writeln("### 앱 사용 시간");
      promptBuffer.writeln(appUsageSummary);
    }
    if (checklistSummary != null) {
      promptBuffer.writeln("### 체크리스트 현황");
      promptBuffer.writeln(checklistSummary);
    }
    if (scheduleSummary != null) {
      promptBuffer.writeln("### 주요 일정");
      promptBuffer.writeln(scheduleSummary);
    }
    if (moodChartSummary != null) {
      promptBuffer.writeln("### 감정 변화 기록");
      promptBuffer.writeln(moodChartSummary);
    }
    if (weatherSummary != null) {
      promptBuffer.writeln("### 내일 날씨 예보");
      promptBuffer.writeln(weatherSummary);
    }
    promptBuffer.writeln(
      "모든 항목에 대한 개별적인 피드백을 제공한 후, 전체 내용을 바탕으로 오늘 하루를 위한 짧은 일기를 쓰는 데 도움이 될만한 질문들을 3개 미만으로 추가해주세요.",
    );
    promptBuffer.writeln("피드백은 마크업을 사용하지 말고 플레인 텍스트만을 사용해 휴대폰에서의 가독성을 생각해주세요.");

    return promptBuffer.toString();
  }
}
