import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/provided/ndn_api_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
/// Wrapper class around the apps settings. Provides functions to load and store it
class AppSettings with ChangeNotifier {
  final NDNApiWrapper apiWrapper;

  bool initiallyConfigured = false;
  bool useNfd = true;
  String remoteNfdIp = "";
  int remoteNfdPort = 6363;

  AppSettings(this.apiWrapper);

  Future<void> load() async {
    var prefs = await SharedPreferences.getInstance();

    initiallyConfigured = prefs.getBool("settings.initiallyConfigured") ?? false;
    useNfd = prefs.getBool("settings.useNfd") ?? false;
    remoteNfdIp = prefs.getString("settings.remoteNfdIp") ?? "";
    remoteNfdPort = prefs.getInt("settings.remoteNfdPort") ?? 6363;

    await _updateAndroidFaceSettings(); // Ensure the settings are initially applied to the native code
    notifyListeners();
  }

  Future<void> save() async {
    var prefs = await SharedPreferences.getInstance();

    prefs.setBool("settings.initiallyConfigured", initiallyConfigured);
    prefs.setBool("settings.useNfd", useNfd);
    prefs.setString("settings.remoteNfdIp", remoteNfdIp);
    prefs.setInt("settings.remoteNfdPort", remoteNfdPort);

    await _updateAndroidFaceSettings();
    notifyListeners();
  }

  /// Propagates the changes to the android app
  Future<void> _updateAndroidFaceSettings() async {
    if (useNfd) {
      await apiWrapper.setFaceSettings("ip", 0);
    } else {
      await apiWrapper.setFaceSettings(remoteNfdIp, remoteNfdPort);
    }
  }

}