import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguredSensors with ChangeNotifier {
  List<SensorConfig> _selectedEndpoints = [];

  Future<void> initialize() async {
    var prefs = await SharedPreferences.getInstance();

    try {
      _selectedEndpoints = (prefs.getStringList("configuredPaths") ?? [])
          .map((e) => SensorConfig.fromJsonString(e))
          .toList();
    } on FormatException catch (e) {
      print("Failed to load settings. Resetting them. $e");
    }

    notifyListeners();
  }

  Future<void> addEndpoint(SensorConfig config) async {
    var prefs = await SharedPreferences.getInstance();

    _selectedEndpoints.add(config);
    prefs.setStringList("configuredPaths", _selectedEndpoints.map((e) => e.toJsonString()).toList());

    notifyListeners();
  }

  Future<void> removeEndpoint(String path) async {
    var prefs = await SharedPreferences.getInstance();

    _selectedEndpoints.removeWhere((e) => e.path == path);
    prefs.setStringList("configuredPaths", _selectedEndpoints.map((e) => e.toJsonString()).toList());

    notifyListeners();
  }

  Future<void> toggleEndpoint(String path, bool enabled) async {
    var prefs = await SharedPreferences.getInstance();

    var element = _selectedEndpoints.where((e) => e.path == path).first;
    element.enabled = enabled;
    prefs.setStringList("configuredPaths", _selectedEndpoints.map((e) => e.toJsonString()).toList());

    notifyListeners();
  }

  bool pathExists(String path) {
    return _selectedEndpoints.map((e) => e.path).contains(path);
  }

  List<SensorConfig> get allEndpoints => _selectedEndpoints
      .toList(growable: false);

  List<SensorConfig> get activeEndpoints => _selectedEndpoints
      .where((e) => e.enabled)
      .toList(growable: false);

}

class SensorConfig {
  final String path;
  final String title;
  bool enabled;

  SensorConfig(this.path, this.title, this.enabled);

  static SensorConfig fromJsonString(String data) {
    var dataMap = jsonDecode(data) as Map<String, dynamic>;

    return SensorConfig(dataMap["path"], dataMap["title"], dataMap["enabled"]);
  }

  String toJsonString() {
    return jsonEncode({
      "path": path,
      "title": title,
      "enabled": enabled,
    });
  }

}
