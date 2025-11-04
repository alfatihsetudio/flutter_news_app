// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Experimental Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      // <- ini yang bikin pertama tampil
      home: const MenuScreen(),
      // (opsional) kalau mau juga pakai named routes
      routes: {
        '/menu': (_) => const MenuScreen(),
      },
    );
  }
}
