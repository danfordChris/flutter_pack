import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:database_manager_package/extensions/date_axtensions.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class AppUtility {
  AppUtility._();

  static void log<T>(T message) {
    if (kReleaseMode) return;
    DateTime now = DateTime.now();
    String formattedTime = now.toFormat("dd MMM yyyy - HH:mm");
    developer.log("$message", name: "[ $formattedTime ]");
  }

  static Future<bool> get networkConnected async {
    Connectivity connectivity = Connectivity();
    List<ConnectivityResult> results = await connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  static String get newUuid => Uuid().v4();

  static Future<bool> launchURL(String target) async {
    Uri uri = Uri.parse(target);
    if (!await canLaunchUrl(uri)) throw Exception("Not able to launch URL");
    return await launchUrl(uri);
  }

  static Future<String> get appVersion async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return "Version ${packageInfo.version} Build ${packageInfo.buildNumber}";
  }
}
