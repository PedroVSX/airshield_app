import 'package:flutter/material.dart';

import 'presentation/screens/dashboard/dashboard_screen.dart';

class AirShieldApp extends StatelessWidget {
  const AirShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF101418);
    const surfaceColor = Color(0xFF1B2228);
    const primaryColor = Color(0xFF55D6BE);

    return MaterialApp(
      title: 'AirShield',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,

        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          surface: surfaceColor,
          onSurface: Color(0xFFF1F5F4),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          foregroundColor: Color(0xFFF1F5F4),
          elevation: 0,
        ),

        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: surfaceColor,
          indicatorColor: Color(0xFF29453F),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12),
          ),
        ),
      ),

      themeMode: ThemeMode.dark,

      home: const DashboardScreen(),
    );
  }
}