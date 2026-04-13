import 'package:flutter_pack/flutter_pack.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHelper {
  AppHelper._();
  static Future<void> openUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      AppUtility.log("Invalid URL: $urlString");
      return;
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          AppUtility.log("Cannot launch URL even in browser: $urlString");
        }
      }
    } catch (e) {
      AppUtility.log("Error launching URL: $e");
    }
  }

  static Future<void> openWhatsApp({required  String phoneNumber,  String? message}) async {
    final whatsappUrl = 'https://wa.me/$phoneNumber';
    if (message==null)return  await openUrl(whatsappUrl);
    await openUrl('$whatsappUrl?text=$message');

  }
  static Future<void> openEmail({required String email, String? message}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: message == null ? null : {'body': message},
    );
  
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      AppUtility.log("Cannot launch email client for: $email");
    }
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      AppUtility.log("Phone number is empty");
      return;
    }
    // Ensure the phone number starts with a valid scheme
    final uri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (!await launchUrl(uri)) {
        AppUtility.log("Cannot launch phone call to: $phoneNumber");
      }
    } catch (e) {
      AppUtility.log("Error launching phone call: $e");
    }
  }
}
