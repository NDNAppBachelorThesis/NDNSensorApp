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

  Future<double> getRawData(String path) async {
    try {
      var res = await platform.invokeMethod("getData", {
        "path": path,
      });
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
}
