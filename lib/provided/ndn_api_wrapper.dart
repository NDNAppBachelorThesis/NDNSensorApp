import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:ndn_sensor_app/provided/global_app_state.dart';

///
/// Base class for all NDN exceptions
class NDNException implements Exception {}

///
/// NDN request couldn't reach a provider
class NDNTimeoutException extends NDNException {
  final String path;

  NDNTimeoutException(this.path);

  @override
  String toString() => "NDNTimeoutException for path $path";
}

///
/// Sporadic weired error
class NDNAsyncCloseException extends NDNException {
  final String path;

  NDNAsyncCloseException(this.path);

  @override
  String toString() => "NDNAsyncCloseException for path $path";
}

///
/// Raised when the app can't connect to an NDF
class NDNConnectNDFException extends NDNException {
  final String path;

  NDNConnectNDFException(this.path);

  @override
  String toString() => "NDNConnectNDFException for path $path";
}

///
/// Unknown NDN exception
class NDNUnknownException extends NDNException {
  final String path;
  final String? stacktrace;

  NDNUnknownException(this.path, [this.stacktrace]);

  @override
  String toString() => "NDNUnknownException for path $path";
}

///
/// A wrapper around the method channel to abstract the method channel code away
class NDNApiWrapper {
  static const platform = MethodChannel("ndn.matthes.de/jndn");
  final GlobalAppState globalAppState;

  NDNApiWrapper({required this.globalAppState});

  ///
  /// Tries to execute a method channel function and handles possible errors.
  /// This method is responsible for increasing / resetting the count to failed NDN packets, which eventually leads to
  /// an error message
  Future<dynamic> _methodChannelCallWrapper(String path, Future<dynamic> Function() request) async {
    try {
      var res = await request();
      globalAppState.resetUnsuccessfulPacketsCnt();
      return res;
    } on PlatformException catch (e) {
      switch (e.code) {
        case "NDN_TIMEOUT":
          throw NDNTimeoutException(path);
        case "NDN_ASYNC_CLOSE":
          throw NDNAsyncCloseException(path);
        case "NDN_NFD_CONNECTION_ERROR":
          globalAppState.incrementUnsuccessfulPacketsCnt();
          throw NDNConnectNDFException(path);
        case "NDN_UNKNOWN_EXCEPTION":
          print("Got unknown exception. Stacktrace:");
          print(e.details);
      }

      throw NDNUnknownException(path, e.details);
    }
  }

  ///
  /// Returns a sensors measurement
  Future<double> getRawData(String path) async {
    return await _methodChannelCallWrapper(path, () async {
      return platform.invokeMethod("getData", {
        "path": path,
      });
    });
  }

  ///
  /// Runs the sensor discovery algorithm
  void runNameDiscovery(void Function(List<String> paths, int? deviceId, bool? isNFD, bool finished) onPathsFound) async {
    List<int> visitedIds = [];
    int timeoutCnt = 0;

    while (timeoutCnt < 3) {
      try {
        dynamic res = await _methodChannelCallWrapper("/esp/discovery", () async {
          return platform.invokeMethod("runDiscovery", {
            "visitedIds": visitedIds,
          });
        });
        timeoutCnt = 0;
        var deviceId = res[0] as int;
        var devicePaths = (res[1] as List<Object?>).map((e) => e as String).toList(growable: false);
        var isNfd = res[2] as bool;

        visitedIds.add(deviceId);
        onPathsFound(devicePaths, deviceId, isNfd, false);
      } on NDNTimeoutException {
        timeoutCnt += 1;
      }
    }

    onPathsFound([], null, null, true);
  }

  ///
  /// Runs the sensor discovery algorithm but returns the found devices and not the sensors
  void runDeviceDiscovery(void Function(String? deviceId, bool? isNfd, bool finished) onDeviceFound) async {
    List<int> visitedIds = [];
    int timeoutCnt = 0;

    while (timeoutCnt < 3) {
      try {
        dynamic res = await _methodChannelCallWrapper("/esp/discovery", () async {
          return platform.invokeMethod("runDiscovery", {
            "visitedIds": visitedIds,
          });
        });
        timeoutCnt = 0;
        var deviceId = res[0] as int;
        var isNfd = res[2] as bool;

        visitedIds.add(deviceId);
        onDeviceFound(deviceId.toString(), isNfd, false);
      } on NDNTimeoutException {
        timeoutCnt += 1;
      }
    }

    onDeviceFound(null, null, true);
  }

  ///
  /// Update the NDN face settings
  Future<void> setFaceSettings(String ip, int port) async {
    await _methodChannelCallWrapper("setFaceSettings", () async {
      return await platform.invokeMethod("setFaceSettings", {
        "ip": ip,
        "port": port,
      });
    });
  }

  ///
  /// Request the link qualities from a device
  Future<Map<int, double>> getSensorLinkQualities(String deviceId) async {
    var r = await _methodChannelCallWrapper("/esp/$deviceId/linkquality", () async {
      return platform.invokeMethod("getLinkQuality", {
        "deviceId": deviceId,
      });
    });

    return (r as Map).map((key, value) => MapEntry(key as int, value as double));
  }

}
