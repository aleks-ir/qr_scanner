import 'package:flutter/material.dart';
import 'package:qr_scanner/home_page.dart';

void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(
            backgroundColor: Colors.black12,
            contentTextStyle: TextStyle(color: Colors.white)),
        brightness: Brightness.dark,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.white.withOpacity(0.3),
          foregroundColor: Colors.white,
        )),
    home: const HomePage()));
