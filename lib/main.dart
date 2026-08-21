import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'dart:io';

import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/complaints_provider.dart';

// --- 1. THEME PROVIDER ---
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = "selected_theme";
  ThemeData _currentTheme = AppTheme.lavenderTheme;
  String _currentThemeName = "Lavender";

  ThemeProvider() {
    _loadTheme();
  }

  ThemeData get currentTheme => _currentTheme;
  String get themeName => _currentThemeName;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey) ?? "Lavender";
    setTheme(savedTheme, save: false);
  }

  void setTheme(String name, {bool save = true}) {
    _currentThemeName = name;
    switch (name) {
      case 'Lavender':
        _currentTheme = AppTheme.lavenderTheme;
        break;
      case 'Dark':
        _currentTheme = AppTheme.darkTheme;
        break;
      case 'Blue':
        _currentTheme = AppTheme.blueTheme;
        break;
      case 'Orange':
        _currentTheme = AppTheme.orangeTheme;
        break;
      default:
        _currentTheme = AppTheme.lavenderTheme;
        break;
    }
    notifyListeners();
    if (save) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(_themeKey, name);
      });
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      // FIXED: Using publishableKey to resolve deprecation warning
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
      // --- APP CONFIGURATION ---
      onGenerateTitle: (context) => 'Smartify - AIMS Institutional App',
      
      // Dynamic ThemeMode switching based on the ThemeProvider
      themeMode: themeProvider.themeName == 'Dark' 
          ? ThemeMode.dark 
          : ThemeMode.light,
      
      // Modern Bouncing scroll behavior for the entire app
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

// --- GLOBAL DIALOG FUNCTIONS ---

void showAboutSmartifyDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: colorScheme.onPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "About Smartify",
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.videocam, size: 16, color: colorScheme.onPrimary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Attach video clips to your reports for faster resolution.",
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  "Snap it, Submit, Solve it.... 😉",
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Smartify is a digital platform designed for students and staff to resolve campus issues digitally rather than through paper-based methods.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  "DEVELOPED BY",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text("AMRUTA HIREMATH", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Text("GAGANA SHREE R.", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Text("MINCHITHA R.", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE"),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

void showContactSupportDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Contact Support"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAdminContact(context, "Admin: GAGANA SHREE R.", "9986916779", "gaganashriranganath@gmail.com"),
          const Divider(),
          _buildAdminContact(context, "Admin: AMRUTA HIREMATH", "8618927590", "hiremathamruta58@gmail.com"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CLOSE"),
        ),
      ],
    ),
  );
}

Widget _buildAdminContact(BuildContext context, String name, String phone, String email) {
  final colorScheme = Theme.of(context).colorScheme;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Phone: $phone", style: const TextStyle(fontSize: 12)),
          IconButton(
            icon: Icon(Icons.phone, color: colorScheme.primary),
            onPressed: () => launchUrl(Uri.parse("tel:$phone")),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text("Email: $email", style: const TextStyle(fontSize: 11))),
          IconButton(
            icon: Icon(Icons.email, color: colorScheme.primary),
            onPressed: () => launchUrl(Uri.parse("mailto:$email")),
          ),
        ],
      ),
    ],
  );
}

void showThemeDialog(BuildContext context) {
  final provider = Provider.of<ThemeProvider>(context, listen: false);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("✨ Select App Theme"),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Lavender', 'Dark', 'Blue', 'Orange'].map((themeName) {
              return RadioListTile<String>(
                title: Text(themeName),
                value: themeName,
                // ignore: deprecated_member_use
                groupValue: provider.themeName,
                // ignore: deprecated_member_use
                onChanged: (val) {
                  provider.setTheme(val!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          );
        },
      ),
    ),
  );
}
