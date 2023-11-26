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

class NDNApiWrapper {
  static const platform = MethodChannel("ndn.matthes.de/jndn");
  final GlobalAppState globalAppState;

  NDNApiWrapper({required this.globalAppState});

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

  Future<double> getRawData(String path) async {
    return await _methodChannelCallWrapper(path, () async {
      return platform.invokeMethod("getData", {
        "path": path,
      });
    });
  }

  void runDiscovery(void Function(List<String> paths, bool finished) onPathsFound) async {
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
        visitedIds.add(res[0]);
        var devicePaths = (res[1] as List<Object?>).map((e) => e as String).toList(growable: false);
        onPathsFound(devicePaths, false);

      } on NDNTimeoutException {
        timeoutCnt += 1;
      }
    }

    onPathsFound([], true);
  }

  Future<void> setFaceSettings(String ip, int port) async {
    await _methodChannelCallWrapper("setFaceSettings", () async {
      return await platform.invokeMethod("setFaceSettings", {
        "ip": ip,
        "port": port,
      });
    });
  }

}
