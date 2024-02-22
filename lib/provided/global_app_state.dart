import 'package:flutter/material.dart';

///
/// Stores global app state, which can be used everywhere in the app
class GlobalAppState with ChangeNotifier {
  bool _showedNDFConnectionError = false;
  int _unsuccessfulPacketsCnt = 0;

  bool get showedNDFConnectionError => _showedNDFConnectionError;

  set showedNDFConnectionError(bool value) {
    _showedNDFConnectionError = value;
    notifyListeners();
  }

  int get unsuccessfulPacketsCnt => _unsuccessfulPacketsCnt;

  ///
  /// Increments the counter for unsuccessfully send NDN packets
  int incrementUnsuccessfulPacketsCnt() {
    var res =  ++_unsuccessfulPacketsCnt;
    notifyListeners();
    return res;
  }

  void resetUnsuccessfulPacketsCnt() {
    _unsuccessfulPacketsCnt = 0;
    _showedNDFConnectionError = false;
  }

}
