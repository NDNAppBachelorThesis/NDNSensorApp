import 'package:flutter/material.dart';

class GlobalAppState with ChangeNotifier {
  bool _showedNDFConnectionError = false;
  int _unsuccessfulPacketsCnt = 0;

  bool get showedNDFConnectionError => _showedNDFConnectionError;

  set showedNDFConnectionError(bool value) {
    _showedNDFConnectionError = value;
    notifyListeners();
  }

  int get unsuccessfulPacketsCnt => _unsuccessfulPacketsCnt;

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
