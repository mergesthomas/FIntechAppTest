import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  static const pageHorizontal = 24.0;
  static const page = EdgeInsets.fromLTRB(24, 16, 24, 32);
  static const maxContentWidth = 560.0;
}

abstract final class AppRadii {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 12.0;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
}
