import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndn_sensor_app/provided/configured_sensors.dart';
import 'package:ndn_sensor_app/provided/ndn_api_wrapper.dart';


///
/// Manages the sensors data. Periodically requests the current sensor measurement values via NDN
class SensorDataHandler {
  final Map<String, SensorData> _dataHistory = {};
  final ConfiguredSensors _configuredSensors;
  final NDNApiWrapper _ndnApiWrapper;
  Timer? timer;

  SensorDataHandler({
    required ConfiguredSensors configuredSensors,
    required NDNApiWrapper ndnApiWrapper,
  }) : _configuredSensors = configuredSensors, _ndnApiWrapper = ndnApiWrapper;

  ///
  /// Request a single measurement via NDN
  Future<void> _updateSingleData(String path) async {
    try {
      var res = await _ndnApiWrapper.getRawData(path);
      getData(path)
        ..add(res)
        ..lastResultError = false;

    } on NDNException catch (e) {
      print("Failed to update $path (${e.runtimeType})");
      getData(path).lastResultError = true;
    }
  }

  ///
  /// Request the measurements for all active sensors via NDN
  Future<void> _updateAllData(Timer timer) async {
    List<Future<void>> futures = [];

    for (var e in _configuredSensors.activeEndpoints) {
      futures.add(_updateSingleData(e.path));
    }

    await Future.wait(futures);
  }

  Future<void> startAndInitialize() async {
    // Initially populate the keys
    for (var e in _configuredSensors.allEndpoints) {
      createEntry(e.path);
    }

    // Listen to changes in the sensor config
    _configuredSensors.addListener(() {
      var oldKeys = _dataHistory.keys.toSet();
      var newKeys = _configuredSensors.allEndpoints.map((e) => e.path).toSet();

      var toRemove = oldKeys.difference(newKeys);
      var toAdd = newKeys.difference(oldKeys);

      for (var key in toRemove) {
        removeEntry(key);
      }

      for (var key in toAdd) {
        createEntry(key);
      }
    });

    timer = Timer.periodic(Duration(seconds: 1), _updateAllData);
  }

  void stop() {
    timer?.cancel();
  }

  SensorData getData(String path) {
    return _dataHistory[path] ?? SensorData();
  }

  void createEntry(String path) {
    _dataHistory[path] = SensorData();
  }

  void removeEntry(String path) {
    _dataHistory.remove(path);
  }
}

///
/// Stores the actual data history of a sensor
class SensorData extends ChangeNotifier {
  final List<double> _history = [];
  bool _lastResultError = false;

  void add(double item) {
    _history.add(item);

    // Prevent the app from using too much memory
    if (_history.length > 3000) {
      _history.removeRange(0, 100);
    }

    notifyListeners();
  }

  double? get lastItem => _history.lastOrNull;

  List<double> get history => _history.toList(growable: false);

  bool get lastResultError => _lastResultError;

  set lastResultError(bool value) {
    _lastResultError = value;
    notifyListeners();
  }

}
