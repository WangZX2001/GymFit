import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymfit/pages/auth_page.dart';
import 'package:gymfit/pages/me/settings/edit_profile_page.dart';
import 'package:gymfit/services/user_profile_service.dart';
import 'package:gymfit/services/theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? userName;
  String? userUsername;
  String? userEmail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    UserProfileService().addListener(_loadUserProfile);
    _loadUserProfile();
  }

  @override
  void dispose() {
    UserProfileService().removeListener(_loadUserProfile);
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              userName = data['name'] as String?;
              userUsername = data['username'] as String?;
              userEmail = user.email;
              isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              userEmail = user.email;
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeService.currentTheme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: FaIcon(
            FontAwesomeIcons.arrowLeft,
            color: themeService.currentTheme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Settings Options
                _buildSettingsSection(
                  'Account',
                  [
                                         _buildSettingsTile(
                       icon: FontAwesomeIcons.userPen,
                       title: 'Edit Profile',
                       subtitle: 'Update your personal information',
                       onTap: () {
                         Navigator.of(context).push(
                           MaterialPageRoute(
                             builder: (context) => EditProfilePage(
                               onProfileUpdated: () {
                                 // Refresh the settings page data
                                 _loadUserProfile();
                               },
                             ),
                           ),
                         );
                       },
                     ),
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.shieldHalved,
                      title: 'Privacy',
                      subtitle: 'Manage your privacy settings',
                      onTap: () {
                        _showPrivacySettingsDialog();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildSettingsSection(
                  'App',
                  [
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.bell,
                      title: 'Notifications',
                      subtitle: 'Manage notification preferences',
                      onTap: () {
                        _showNotificationSettingsDialog();
                      },
                    ),
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.language,
                      title: 'Language',
                      subtitle: 'Change app language',
                      onTap: () {
                        _showLanguageSettingsDialog();
                      },
                    ),
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.palette,
                      title: 'Theme',
                      subtitle: 'Light or dark mode',
                      onTap: () {
                        _showThemeDialog();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildSettingsSection(
                  'Support',
                  [
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.circleQuestion,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact support',
                      onTap: () {
                        _showHelpSupportDialog();
                      },
                    ),
                    _buildSettingsTile(
                      icon: FontAwesomeIcons.circleInfo,
                      title: 'About',
                      subtitle: 'App version and information',
                      onTap: () {
                        _showAboutDialog();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Logout Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _showLogoutDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.rightFromBracket, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: themeService.currentTheme.cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeService.isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: themeService.isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: themeService.currentTheme.textTheme.titleMedium?.color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: FaIcon(
        FontAwesomeIcons.chevronRight,
        color: themeService.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  void _showThemeDialog() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.sun,
                  color: themeService.isDarkMode ? Colors.grey : Colors.orange,
                ),
                title: const Text('Light Mode'),
                trailing: themeService.isDarkMode ? null : const FaIcon(FontAwesomeIcons.check, color: Colors.green),
                onTap: () {
                  themeService.setTheme(false);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.moon,
                  color: themeService.isDarkMode ? Colors.blue : Colors.grey,
                ),
                title: const Text('Dark Mode'),
                trailing: themeService.isDarkMode ? const FaIcon(FontAwesomeIcons.check, color: Colors.green) : null,
                onTap: () {
                  themeService.setTheme(true);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context, rootNavigator: true);
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (c) => const AuthPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacySettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Settings'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy settings will be implemented in a future update.'),
              SizedBox(height: 8),
              Text('Features planned:'),
              SizedBox(height: 4),
              Text('• Profile visibility'),
              Text('• Data sharing preferences'),
              Text('• Account privacy controls'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notification Settings'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notification settings will be implemented in a future update.'),
              SizedBox(height: 8),
              Text('Features planned:'),
              SizedBox(height: 4),
              Text('• Workout reminders'),
              Text('• Achievement notifications'),
              Text('• Friend activity updates'),
              Text('• App updates'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Language Settings'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Language settings will be implemented in a future update.'),
              SizedBox(height: 8),
              Text('Languages planned:'),
              SizedBox(height: 4),
              Text('• English'),
              Text('• Spanish'),
              Text('• French'),
              Text('• German'),
              Text('• More languages coming soon'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Need help? Here are some resources:'),
              SizedBox(height: 8),
              Text('• FAQ section'),
              Text('• Contact support team'),
              Text('• User guide'),
              Text('• Troubleshooting tips'),
              SizedBox(height: 8),
              Text('For immediate support, please email:'),
              Text('support@gymfit.app'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About GymFit'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GymFit - Your Personal Fitness Companion'),
              SizedBox(height: 8),
              Text('Version: 1.0.0'),
              Text('Build: 2024.1.0'),
              SizedBox(height: 8),
              Text('Features:'),
              SizedBox(height: 4),
              Text('• Custom workout creation'),
              Text('• Exercise tracking'),
              Text('• Progress monitoring'),
              Text('• Social features'),
              SizedBox(height: 8),
              Text('© 2024 GymFit Team'),
              Text('All rights reserved.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
} 