import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const AProvaApp());
}

class AProvaApp extends StatelessWidget {
  const AProvaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A PROVA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}