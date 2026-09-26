import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/theme_provider.dart';

/// Shows an informative dialog about the Smartify application.
void showAboutSmartifyDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  
  showDialog(
    context: context,
    builder: (context) => FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData ? snapshot.data!.version : "1.0.0";
        return Dialog(
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
                    const Icon(Icons.info, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "About Smartify",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                      "Smartify is a digital platform designed for students and staff to resolve campus issues digitally.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Version: $version",
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                    const Text(
                      "Copyright © 2024 Smartify Team",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
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
        );
      },
    ),
  );
}

/// Shows a dialog with support contact information.
void showContactSupportDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.headset_mic, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text("Contact Support"),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Need help? Our team is here to assist you with any issues or queries.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 15),
            _buildAdminContact(context, "GAGANA SHREE R.", "9986916779", "gaganashriranganath@gmail.com"),
            const Divider(),
            _buildAdminContact(context, "AMRUTA HIREMATH", "8618927590", "hiremathamruta58@gmail.com"),
          ],
        ),
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
      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 4),
      Row(
        children: [
          Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(phone, style: TextStyle(fontSize: 13, color: Colors.grey[800])),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.phone, color: colorScheme.primary, size: 20),
            onPressed: () => launchUrl(Uri.parse("tel:$phone")),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      Row(
        children: [
          Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              email, 
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.email, color: colorScheme.primary, size: 20),
            onPressed: () => launchUrl(Uri.parse("mailto:$email")),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    ],
  );
}

/// Shows a dialog to select the application theme.
void showThemeDialog(BuildContext context) {
  final provider = Provider.of<ThemeProvider>(context, listen: false);
  final colorScheme = Theme.of(context).colorScheme;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Text("✨ ", style: TextStyle(fontSize: 20)),
          Text("Select App Theme"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Lavender', 'Dark', 'Blue', 'Orange'].map((themeName) {
          return RadioListTile<String>(
            title: Text(themeName),
            value: themeName,
            groupValue: provider.themeName,
            activeColor: colorScheme.primary,
            onChanged: (val) {
              provider.setTheme(val!);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    ),
  );
}
