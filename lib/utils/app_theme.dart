import 'package:flutter/material.dart';

const _seedColor = Colors.blue;

final ThemeData appLightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: Colors.yellow,
  useMaterial3: true,
);

final ThemeData appDarkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: _seedColor,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: Colors.yellow,
  useMaterial3: true,
);
