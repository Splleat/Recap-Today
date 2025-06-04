package com.tangsuyukisbumeok.recap_today

import android.app.AppOpsManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Bundle
import android.app.usage.UsageStatsManager
import android.app.usage.UsageStats
import android.provider.Settings
import android.util.Log
import android.webkit.WebView
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    private val CHANNEL = "app_usage_channel"
    private val TAG = "AppUsageChannel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 알림 채널 생성 (Android 8.0+)
        createNotificationChannel()
        
        // WebView 디버깅 활성화 (디버그 빌드에서만)
        try {
            val appInfo = applicationInfo
            if ((appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
                WebView.setWebContentsDebuggingEnabled(true)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to enable WebView debugging", e)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // flutter_background_service가 사용하는 채널 ID와 동일하게 설정
            val channelId = "recap_today_location"
            val channelName = "위치 추적 서비스"
            val channelDescription = "백그라운드에서 위치를 추적합니다"
            val importance = NotificationManager.IMPORTANCE_LOW
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                // 사용자가 알림음이나 진동을 원하지 않을 경우
                enableVibration(false)
                setSound(null, null)
            }
            
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created: $channelId")
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d(TAG, "Method called: ${call.method}")
            
            when (call.method) {
                "getAppUsage" -> {
                    val startTime = call.argument<Long>("startTime") ?: 0
                    val endTime = call.argument<Long>("endTime") ?: System.currentTimeMillis()
                    Log.d(TAG, "getAppUsage from $startTime to $endTime")
                    
                    if (hasUsageStatsPermission()) {
                        try {
                            Log.d(TAG, "Permission granted, querying usage stats")
                            val usageStatsList = getUsageStatistics(startTime, endTime)
                            Log.d(TAG, "Got ${usageStatsList.size} usage stats records")
                            
                            val usageList = mutableListOf<Map<String, Any>>()
                            val packageManager = context.packageManager
                            
                            for (usageStats in usageStatsList) {
                                val packageName = usageStats.packageName
                                val usageTime = usageStats.totalTimeInForeground
                                
                                if (usageTime > 0) {
                                    try {
                                        // 앱 정보 가져오기
                                        val appName = try {
                                            val appInfo = packageManager.getApplicationInfo(packageName, 0)
                                            packageManager.getApplicationLabel(appInfo).toString()
                                        } catch (e: Exception) {
                                            packageName // 앱 이름을 가져올 수 없는 경우 패키지 이름 사용
                                        }
                                        
                                        val appUsageMap = mapOf(
                                            "packageName" to packageName,
                                            "appName" to appName,
                                            "usageTime" to usageTime
                                        )
                                        usageList.add(appUsageMap)
                                        
                                        // 상위 앱 로깅
                                        if (usageList.size <= 5) {
                                            Log.d(TAG, "App: $appName, Usage: ${usageTime/1000/60} minutes")
                                        }
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Error processing app $packageName: ${e.message}")
                                        // 문제가 있는 앱은 건너뛰기
                                        continue
                                    }
                                }
                            }
                            
                            Log.d(TAG, "Returning ${usageList.size} app usage records to Flutter")
                            result.success(usageList)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error getting app usage stats: ${e.message}", e)
                            result.error("ERROR", "Failed to get app usage stats: ${e.message}", e.toString())
                        }
                    } else {
                        Log.w(TAG, "Usage stats permission not granted")
                        result.error("PERMISSION_DENIED", "Usage access permission not granted", null)
                    }
                }
                "openUsageAccessSettings" -> {
                    try {
                        Log.d(TAG, "Opening usage access settings")
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to open settings: ${e.message}", e)
                        result.error("ERROR", "Failed to open usage access settings", e.message)
                    }
                }
                "hasUsageStatsPermission" -> {
                    val hasPermission = hasUsageStatsPermission()
                    Log.d(TAG, "Checking usage stats permission: $hasPermission")
                    result.success(hasPermission)
                }
                "getAppInfo" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        try {
                            val packageManager = context.packageManager
                            val appInfo = packageManager.getApplicationInfo(packageName, 0)
                            val appName = packageManager.getApplicationLabel(appInfo).toString()
                            
                            val appInfoMap = mapOf(
                                "packageName" to packageName,
                                "appName" to appName
                            )
                            result.success(appInfoMap)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to get app info for $packageName: ${e.message}", e)
                            result.error("ERROR", "Failed to get app info", e.message)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Package name is required", null)
                    }
                }
                else -> {
                    Log.w(TAG, "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun hasUsageStatsPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
    
    private fun getUsageStatistics(startTime: Long, endTime: Long): List<UsageStats> {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        
        // Flutter에서 전달받은 startTime을 사용하도록 수정
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_BEST, 
            startTime, // Flutter에서 전달받은 startTime으로 수정
            endTime
        )
        
        Log.d(TAG, "Raw stats count for period: ${stats.size}") // 로그 메시지 수정하여 기간 명시
        
        // 사용 시간이 있는 앱만 필터링하고 정렬
        return stats
                .filter { it.totalTimeInForeground > 0 }
                .sortedByDescending { it.totalTimeInForeground }
    }
}
