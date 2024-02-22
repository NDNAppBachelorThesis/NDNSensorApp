import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
/// The unit of a sensors measurements
enum SensorUnit {
  none(Icons.question_mark_rounded, ""),
  temperature(Icons.thermostat_rounded, "°C"),
  humidity(Icons.water_drop_rounded, "%"),
  percent(Icons.percent_rounded, "%"),
  absolute(Icons.toggle_off_outlined, ""),
  centiMeters(Icons.straighten_outlined, "cm")
  ;

  final IconData? icon;
  final String unitString;

  const SensorUnit(this.icon, this.unitString);

  String toJsonString() {
    return name;
  }

  static SensorUnit fromJsonString(String data) {
    return SensorUnit.values.where((e) => e.name == data).first;
  }
}


///
/// Stores and manages the currently configured sensors. Also ensures that these settings are persisted to disk
class ConfiguredSensors with ChangeNotifier {
  List<SensorConfig> _selectedEndpoints = [];

  Future<void> initialize() async {
    var prefs = await SharedPreferences.getInstance();

    try {
      _selectedEndpoints =
          (prefs.getStringList("configuredPaths") ?? []).map((e) => SensorConfig.fromJsonString(e)).toList();
    } on FormatException catch (e) {
      print("Failed to load settings. Resetting them. $e");
    }

    notifyListeners();
  }

  ///
  /// Add a new sensor
  Future<void> addEndpoint(SensorConfig config) async {
    var prefs = await SharedPreferences.getInstance();

    _selectedEndpoints.add(config);
    prefs.setStringList("configuredPaths", _selectedEndpoints.map((e) => e.toJsonString()).toList());

    notifyListeners();
  }

  ///
  /// Remove an existing sensor
  Future<void> removeEndpoint(String path) async {
    var prefs = await SharedPreferences.getInstance();

    _selectedEndpoints.removeWhere((e) => e.path == path);
    prefs.setStringList("configuredPaths", _selectedEndpoints.map((e) => e.toJsonString()).toList());

    notifyListeners();
  }

  ///
  /// Enable / disable an existing sensor
  Future<void> toggleEndpoint(String path, bool enabled) async {
    var prefs = await SharedPreferences.getInstance();

    var element = _selectedEndpoints.where((e) => e.path == path).first;
    element.enabled = enabled;
    prefs.setStringList("configuredPaths", _selectedEndpoints.map((e) => e.toJsonString()).toList());

    notifyListeners();
  }

  ///
  /// Checks if a sensor with a certain name exists (e.g. '/etc/654461481157345/data')
  bool pathExists(String path) {
    return _selectedEndpoints.map((e) => e.path).contains(path);
  }

  List<SensorConfig> get allEndpoints => _selectedEndpoints.toList(growable: false);

  List<SensorConfig> get activeEndpoints => _selectedEndpoints.where((e) => e.enabled).toList(growable: false);
}

///
/// The concrete config of a single sensor
class SensorConfig {
  final String path;
  final String title;
  final SensorUnit unit;
  bool enabled;

  SensorConfig(this.path, this.title, this.unit, this.enabled);

  static SensorConfig fromJsonString(String data) {
    var dataMap = jsonDecode(data) as Map<String, dynamic>;

    return SensorConfig(
      dataMap["path"],
      dataMap["title"],
      SensorUnit.fromJsonString(dataMap["unit"] ?? "none"),
      dataMap["enabled"],
    );
  }

  String toJsonString() {
    return jsonEncode({
      "path": path,
      "title": title,
      "unit": unit.toJsonString(),
      "enabled": enabled,
    });
  }
}
