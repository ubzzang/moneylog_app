import 'package:flutter/material.dart';
import 'package:moneylog_app/screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      // 영랑추가_지출입달력
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ko', 'KR'),
      // 추가종료
      //home: const HomeScreen(isLoggedIn: false),
      home: const LoginScreen(),
    );
  }
}