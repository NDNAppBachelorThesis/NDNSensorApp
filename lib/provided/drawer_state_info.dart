import 'package:flutter/material.dart';

class DrawerStateInfo with ChangeNotifier {
  int _currentDrawer = 0;

  int get getSelectedIndex => _currentDrawer;

  void setDrawerIndex(int drawer) {
    _currentDrawer = drawer;
    notifyListeners();
  }

}
