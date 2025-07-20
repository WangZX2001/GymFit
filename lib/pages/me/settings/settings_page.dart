import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
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
          icon: Icon(
            Icons.arrow_back,
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
                       icon: Icons.edit,
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
                      icon: Icons.lock,
                      title: 'Privacy',
                      subtitle: 'Manage your privacy settings',
                      onTap: () {
                        // TODO: Implement privacy settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Privacy Settings - Coming Soon')),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildSettingsSection(
                  'App',
                  [
                    _buildSettingsTile(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Manage notification preferences',
                      onTap: () {
                        // TODO: Implement notification settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notification Settings - Coming Soon')),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Change app language',
                      onTap: () {
                        // TODO: Implement language settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Language Settings - Coming Soon')),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.dark_mode,
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
                      icon: Icons.help,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact support',
                      onTap: () {
                        // TODO: Implement help and support
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Help & Support - Coming Soon')),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.info,
                      title: 'About',
                      subtitle: 'App version and information',
                      onTap: () {
                        // TODO: Implement about page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('About - Coming Soon')),
                        );
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
                        Icon(Icons.logout, size: 20),
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
      trailing: Icon(
        Icons.arrow_forward_ios,
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
                leading: Icon(
                  Icons.light_mode,
                  color: themeService.isDarkMode ? Colors.grey : Colors.orange,
                ),
                title: const Text('Light Mode'),
                trailing: themeService.isDarkMode ? null : const Icon(Icons.check, color: Colors.green),
                onTap: () {
                  themeService.setTheme(false);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.dark_mode,
                  color: themeService.isDarkMode ? Colors.blue : Colors.grey,
                ),
                title: const Text('Dark Mode'),
                trailing: themeService.isDarkMode ? const Icon(Icons.check, color: Colors.green) : null,
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
              onPressed: () {
                Navigator.of(context).pop();
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (c) => const AuthPage()),
                    (route) => false,
                  );
                });
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
} 