import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings with ChangeNotifier {
  bool useNfd = true;
  String remoteNfdIp = "";
  int remoteNfdPort = 6363;

  Future<void> load() async {
    var prefs = await SharedPreferences.getInstance();

    useNfd = prefs.getBool("settings.useNfd") ?? false;
    remoteNfdIp = prefs.getString("settings.remoteNfdIp") ?? "";
    remoteNfdPort = prefs.getInt("settigns.remoteNfdPort") ?? 6363;

    notifyListeners();
  }

  void save() async {
    var prefs = await SharedPreferences.getInstance();

    prefs.setBool("settings.useNfd", useNfd);
    prefs.setString("settings.remoteNfdIp", remoteNfdIp);
    prefs.setInt("settigns.remoteNfdPort", remoteNfdPort);

    notifyListeners();
  }

}