import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'dart:io';

import 'config/supabase_config.dart';
import 'screens/splash_screen.dart';
import 'providers/complaints_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.apiKey,
    );
  } on SocketException catch (e) {
    debugPrint("Supabase Initialization Error: Network Unreachable. ${e.message}");
  } catch (e) {
    debugPrint("Supabase Initialization Error: ${e.toString()}");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintsProvider()),
      ],
      child: const SmartifyApp(),
    ),
  );
}

class SmartifyApp extends StatelessWidget {
  const SmartifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
        ],
      ),
      onGenerateTitle: (context) => 'Smartify - AIMS Institutional App',
      themeMode: themeProvider.themeName == 'Dark' 
          ? ThemeMode.dark 
          : ThemeMode.light,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      title: 'Smartify',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      home: const SplashScreen(),
    );
  }
}
