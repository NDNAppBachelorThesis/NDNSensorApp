import 'package:flutter/material.dart';


///
/// Stores the currently selected drawer element to highlight that in the AppDrawer
class DrawerStateInfo with ChangeNotifier {
  int _currentDrawer = 0;

  int get getSelectedIndex => _currentDrawer;

  void setDrawerIndex(int drawer) {
    _currentDrawer = drawer;
    notifyListeners();
  }

}
