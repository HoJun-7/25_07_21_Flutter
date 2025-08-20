import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb; // Web 체크용
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalPushNotifications {
  // 플러그인 인스턴스 생성
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // 푸시 알림 스트림 생성
  static final StreamController<String?> notificationStream =
      StreamController<String?>.broadcast();

  // 푸시 알림을 탭했을 때 호출되는 콜백 함수
  static void onNotificationTap(NotificationResponse notificationResponse) {
    notificationStream.add(notificationResponse.payload);
  }

  // 플러그인 초기화
  static Future init() async {
    if (kIsWeb) {
      // Web에서는 Flutter Local Notifications를 지원하지 않음
      print("Web platform detected: Local notifications are not supported.");
      return;
    }

    // Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();
    // Linux
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    // Android 푸시 알림 권한 요청
    if (!kIsWeb) {
      try {
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()!
            .requestNotificationsPermission();
      } catch (e) {
        print("Android notification permission request failed: $e");
      }
    }

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
  }

  // 일반 푸시 알림 보내기
  static Future showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'channel 1',
      'channel 1 name',
      channelDescription: 'channel 1 description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // 매분마다 주기적인 푸시 알림 보내기
  static Future showPeriodicNotifications({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'channel 2',
      'channel 2 name',
      channelDescription: 'channel 2 description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.periodicallyShow(
      1,
      title,
      body,
      RepeatInterval.everyMinute,
      notificationDetails,
      payload: payload,
    );
  }

  // 지정된 스케줄에 맞춰 알람 보내기
  static Future showScheduleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (kIsWeb) return;

    tz.initializeTimeZones();

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'channel 3',
          'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // 채널 id에 해당하는 푸시 알림 취소
  static Future cancel(int id) async {
    if (kIsWeb) return;
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // 푸시 알림 전체 취소
  static Future cancelAll() async {
    if (kIsWeb) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
