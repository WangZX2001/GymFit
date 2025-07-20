import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymfit/home_page_tabs/calories_tab.dart';
import 'package:gymfit/home_page_tabs/water_tab.dart';
import 'package:gymfit/home_page_tabs/weight_tab.dart';
import 'package:gymfit/services/user_profile_service.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

//Check whether the graph is working properly
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int selectedTabIndex = 0;
  String? userName;
  bool isLoadingName = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UserProfileService().addListener(_fetchUserName);
    _fetchUserName();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UserProfileService().removeListener(_fetchUserName);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _fetchUserName();
    }
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              userName = data['name'] as String?;
              isLoadingName = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              isLoadingName = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingName = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingName = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else if (hour < 21) {
      return 'Good Evening!';
    } else {
      return 'Good Night!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      backgroundColor: themeService.currentTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Welcome section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoadingName
                                ? 'Welcome Back'
                                : userName != null
                                ? 'Welcome Back, $userName!'
                                : 'Welcome Back',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: themeService.currentTheme.textTheme.titleLarge?.color ?? Colors.black,
                            ),
                            overflow: TextOverflow.visible,
                            softWrap: true,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_getGreeting()} Remember \nto Stay Hydrated',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.blue[300],
                        child: Image.asset(
                          'lib/images/fitness.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTrackingOption('Weight', Icons.monitor_weight, 0),
                      const SizedBox(width: 5),
                      _buildTrackingOption(
                        'Calories',
                        Icons.local_fire_department,
                        1,
                      ),
                      const SizedBox(width: 5),
                      _buildTrackingOption('Water', Icons.water_drop, 2),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Dynamic Tab Content
                if (selectedTabIndex == 0)
                  const WeightTab()
                else if (selectedTabIndex == 1)
                  const CaloriesTab()
                else
                  const WaterTab(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingOption(String title, IconData icon, int index) {
    final themeService = Provider.of<ThemeService>(context);
    bool isSelected = selectedTabIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (themeService.isDarkMode ? Colors.white : Colors.black)
              : themeService.currentTheme.cardTheme.color,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? (themeService.isDarkMode ? Colors.black : Colors.white)
                  : themeService.currentTheme.textTheme.titleMedium?.color,
              size: 20,
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected 
                    ? (themeService.isDarkMode ? Colors.black : Colors.white)
                    : themeService.currentTheme.textTheme.titleMedium?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
