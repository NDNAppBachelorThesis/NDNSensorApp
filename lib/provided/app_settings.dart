import 'package:flutter/material.dart';
import 'package:ndn_sensor_app/provided/ndn_api_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings with ChangeNotifier {
  final NDNApiWrapper apiWrapper;

  bool useNfd = true;
  String remoteNfdIp = "";
  int remoteNfdPort = 6363;

  AppSettings(this.apiWrapper);

  Future<void> load() async {
    var prefs = await SharedPreferences.getInstance();

    useNfd = prefs.getBool("settings.useNfd") ?? false;
    remoteNfdIp = prefs.getString("settings.remoteNfdIp") ?? "";
    remoteNfdPort = prefs.getInt("settigns.remoteNfdPort") ?? 6363;

    await _updateAndroidFaceSettings();
    notifyListeners();
  }

  void save() async {
    var prefs = await SharedPreferences.getInstance();

    prefs.setBool("settings.useNfd", useNfd);
    prefs.setString("settings.remoteNfdIp", remoteNfdIp);
    prefs.setInt("settigns.remoteNfdPort", remoteNfdPort);

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