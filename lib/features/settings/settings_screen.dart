import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool warnings = true;
  bool cloudSync = true;

  String notify = '3 days';
  String theme = 'System Default';
  String units = 'Metric';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(title: const Text('Settings')),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          Card(
            color: AppColors.bannerWhite,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Expiration Warnings'),
                  value: warnings,
                  onChanged: (value) {
                    setState(() {
                      warnings = value;
                    });
                  },
                ),

                ListTile(
                  title: const Text('Notify me'),
                  trailing: DropdownButton<String>(
                    value: notify,
                    items: ['1 day', '3 days', '7 days'].map((day) {
                      return DropdownMenuItem(value: day, child: Text(day));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        notify = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Storage',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          Card(
            color: AppColors.bannerWhite,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Local Data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Local Data'),
                        content: const Text('Storage information coming soon.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SwitchListTile(
                  title: const Text('Cloud Sync'),
                  value: cloudSync,
                  onChanged: (value) {
                    setState(() {
                      cloudSync = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'App Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          Card(
            color: AppColors.bannerWhite,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Theme'),
                  trailing: DropdownButton<String>(
                    value: theme,
                    items: ['System Default', 'Light', 'Dark'].map((item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        theme = value!;
                      });
                    },
                  ),
                ),

                ListTile(
                  title: const Text('Units'),
                  trailing: DropdownButton<String>(
                    value: units,
                    items: ['Metric', 'Imperial'].map((item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        units = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const Card(
            child: ListTile(
              title: Text('App Version'),
              trailing: Text('1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}
