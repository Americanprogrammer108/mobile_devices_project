import 'package:flutter/material.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/notification_preferences.dart';
import '../../services/notification_preferences_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationPreferencesRepository _preferencesRepository =
      NotificationPreferencesRepository(FirebaseFirestore.instance);

  NotificationPreferences _preferences = const NotificationPreferences();
  bool _loadingPreferences = true;
  bool _savingPreferences = false;

  bool cloudSync = true;
  String theme = 'System Default';
  String units = 'Metric';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() => _loadingPreferences = false);
      }
      return;
    }

    try {
      final preferences = await _preferencesRepository.watch(user.uid).first;

      if (!mounted) return;

      setState(() {
        _preferences = preferences;
        _loadingPreferences = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loadingPreferences = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load notification settings: $error')),
      );
    }
  }

  Future<void> _savePreferences(NotificationPreferences updated) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _savingPreferences) return;

    setState(() => _savingPreferences = true);

    try {
      await _preferencesRepository.save(user.uid, updated);

      if (!mounted) return;

      setState(() => _preferences = updated);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save notification settings: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingPreferences = false);
      }
    }
  }

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
                  value: _preferences.expirationWarnings,
                  onChanged: _loadingPreferences || _savingPreferences
                      ? null
                      : (value) {
                          _savePreferences(
                            _preferences.copyWith(expirationWarnings: value),
                          );
                        },
                ),

                ListTile(
                  title: const Text('Notify me'),
                  trailing: DropdownButton<int>(
                    value: _preferences.daysBeforeExpiry,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 day')),
                      DropdownMenuItem(value: 3, child: Text('3 days')),
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                    ],
                    onChanged:
                        _loadingPreferences ||
                            _savingPreferences ||
                            !_preferences.expirationWarnings
                        ? null
                        : (value) {
                            if (value == null) return;

                            _savePreferences(
                              _preferences.copyWith(daysBeforeExpiry: value),
                            );
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

          ElevatedButton(
            onPressed: () async {
              await notificationService.showTestNotificationNow();
            },
            child: const Text('Test Notification Now'),
          ),

          ElevatedButton(
            onPressed: () async {
              await notificationService.scheduleTestNotification();
            },
            child: const Text('Test Scheduled Notification'),
          ),

          ElevatedButton(
            onPressed: () => setState(() {
              FirebaseAuth.instance.signOut();
            }),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
