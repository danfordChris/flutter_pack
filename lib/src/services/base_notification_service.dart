import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_pack/flutter_pack.dart';
import 'package:timezone/data/latest_all.dart' as timezone;
import 'package:timezone/timezone.dart' as tz_methods;

abstract class BaseNotificationService {
  BaseNotificationService(this._appIcon);
  final String _appIcon;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void init() async {
    AndroidFlutterLocalNotificationsPlugin? plugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    bool? permitted = await plugin?.requestNotificationsPermission();
    if (permitted != null && permitted) AppUtility.log("Notification Service Permitted");
    final AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(_appIcon);
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      // onDidReceiveLocalNotification: _didReceiveNotification,
      notificationCategories: <DarwinNotificationCategory>[],
    );
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    bool? initialized = await _flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
    if (initialized == null && !initialized!) AppUtility.log("Notification Service Not Initialized!");
  }

  void _didReceiveNotification(int id, String? title, String? body, String? payload) {
    AppUtility.log(payload);
  }

  void selectNotification(BuildContext context, NotificationResponse response);

  NotificationDetails _notificationDetails(int id) {
    String androidId = id.toString();
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(androidId, androidId);
    DarwinNotificationDetails iOSNotificationDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
    return NotificationDetails(android: androidNotificationDetails, iOS: iOSNotificationDetails);
  }

  void showNotification({
    required int id,
    required String title,
    required String subtitle,
    NotificationDetails? notificationDetails,
  }) async {
    NotificationDetails platformNotificationDetails = notificationDetails ?? _notificationDetails(id);
    await _flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: subtitle,
      notificationDetails: platformNotificationDetails,
    );
  }

  void setupScheduled(
      {required int id,
      String? title,
      required String body,
      required DateTime dateTime,
      String? payload,
      DateTimeComponents? matchDateTimeComponents}) async {
    timezone.initializeTimeZones();
    tz_methods.Location location = tz_methods.getLocation("Africa/Dar_es_Salaam");
    tz_methods.setLocalLocation(location);
    tz_methods.TZDateTime tzDateTime = tz_methods.TZDateTime.from(dateTime, location);
    NotificationDetails platformNotificationDetails = _notificationDetails(id);
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body, scheduledDate: tzDateTime, notificationDetails: platformNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }
}
