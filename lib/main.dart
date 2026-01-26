import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CashTalk',
      theme: ThemeData(
        fontFamily: 'GmarketSans',
        primaryColor: Color(0xFF3498DB),
      ),
      home: const HomeScreen(isLoggedIn: false),
    );
  }
}