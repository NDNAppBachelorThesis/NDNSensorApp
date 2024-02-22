import 'dart:math';

import 'package:flutter/material.dart';

extension ListUtils<T> on List<T> {
  List<T> lastNElements(int n) {
    return sublist(max(length - n, 0));
  }

  List<T> everyNth(int n) => [for (var i = 0; i < length; i += n) this[i]];
}

extension DoubleListUtil on List<double> {
  double _avg(List<double> list, int index, int avgN) {
    double res = 0.0;
    int divider = 0;
    var indexModifiers = List.generate(avgN, (index) => index - (avgN / 2).floor());

    for (int m in indexModifiers) {
      if (index + m >= 0 && index + m < list.length) {
        res += list[index + m];
        divider++;
      }
    }

    if (divider == 0) {
      return 0.0;
    }

    return res / divider;
  }

  /// Averages every n elements in the list
  List<double> averageNElements(int n) {
    assert(n % 2 == 1); // Must be odd number
    var thisList = this;

    return thisList.indexed.toList().everyNth(n).map((e) => _avg(thisList, e.$1, n)).toList();
  }
}

extension DoubleUtils on double {
  double roundToN(int n) {
    var multiplier = pow(10, n);
    return ((this * multiplier).round() / multiplier);
  }

  String roundToNPadded(int n) {
    var unpadded = roundToN(n).toString();
    return unpadded.padRight(unpadded.indexOf(".") + n + 1, '0');
  }
}

extension IconUtils on IconData {
  Icon toIcon({double? size, Color? color}) {
    return Icon(this, size: size, color: color);
  }
}
