import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymfit/services/user_profile_service.dart';
import 'package:provider/provider.dart';
import 'package:gymfit/services/theme_service.dart';

class EditProfilePage extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  
  const EditProfilePage({super.key, this.onProfileUpdated});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  
  String? userName;
  String? userUsername;
  String? userEmail;
  bool isLoading = true;
  bool isSaving = false;
  bool hasChanges = false;
  
  // Username validation states
  bool isCheckingUsername = false;
  bool? isUsernameAvailable;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _setupTextControllers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _setupTextControllers() {
    _nameController.addListener(_checkForChanges);
    _usernameController.addListener(_checkForChanges);
    _usernameController.addListener(_onUsernameChanged);
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != (userName ?? '');
    final usernameChanged = _usernameController.text.trim() != (userUsername ?? '');
    
    setState(() {
      hasChanges = nameChanged || usernameChanged;
    });
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Reset states if username is empty or too short
    if (username.isEmpty || username.length < 3) {
      setState(() {
        isCheckingUsername = false;
        isUsernameAvailable = null;
      });
      return;
    }
    
    // Check if username format is valid
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        isCheckingUsername = false;
        isUsernameAvailable = false;
      });
      return;
    }
    
    // Don't check if username hasn't changed from original
    if (username == (userUsername ?? '')) {
      setState(() {
        isCheckingUsername = false;
        isUsernameAvailable = true;
      });
      return;
    }
    
    // Set checking state
    setState(() {
      isCheckingUsername = true;
      isUsernameAvailable = null;
    });
    
    // Debounce the API call
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUsernameAvailability(username);
    });
  }

  Future<void> _checkUsernameAvailability(String username) async {
    try {
      final isUnique = await _isUsernameUnique(username);
      if (mounted) {
        setState(() {
          isCheckingUsername = false;
          isUsernameAvailable = isUnique;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCheckingUsername = false;
          isUsernameAvailable = null;
        });
      }
    }
  }

  Future<bool> _isUsernameUnique(String username) async {
    if (username.trim().isEmpty) return false;
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.trim().toLowerCase())
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
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
              
              // Set the text controllers
              _nameController.text = userName ?? '';
              _usernameController.text = userUsername ?? '';
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

  Widget? _buildUsernameSuffixIcon() {
    if (isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    if (isUsernameAvailable == true) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 24,
      );
    }
    
    if (isUsernameAvailable == false) {
      return const Icon(
        Icons.cancel,
        color: Colors.red,
        size: 24,
      );
    }
    
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check username availability if username has changed
    final newUsername = _usernameController.text.trim();
    if (newUsername != (userUsername ?? '')) {
      bool isUnique;
      if (isUsernameAvailable != null) {
        isUnique = isUsernameAvailable!;
      } else {
        isUnique = await _isUsernameUnique(newUsername);
      }
      
      if (!isUnique) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username is already taken'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Notify all listeners that profile has been updated
          UserProfileService().notifyProfileUpdated();
          // Call the callback to notify parent pages
          widget.onProfileUpdated?.call();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
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
          'Edit Profile',
          style: themeService.currentTheme.appBarTheme.titleTextStyle,
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside of text fields
            FocusScope.of(context).unfocus();
          },
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Picture Section
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _showProfilePictureDialog();
                                  },
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                                        child: Icon(
                                          Icons.person,
                                          size: 60,
                                          color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade600,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Name Field
                          _buildTextField(
                            controller: _nameController,
                            label: 'Name',
                            hint: 'Enter your full name',
                            icon: Icons.person,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Username Field
                          _buildUsernameField(),
                          
                          const SizedBox(height: 20),
                          
                          // Email Field (Read-only)
                          _buildReadOnlyField(
                            label: 'Email',
                            value: userEmail ?? 'No email',
                            icon: Icons.email,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Save Button
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(4.0),
                            child: ElevatedButton(
                              onPressed: (isSaving || !hasChanges) ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasChanges ? Colors.blue.shade600 : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: hasChanges ? 2 : 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isSaving) ...[
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    isSaving ? 'Saving...' : 'Save Changes',
                                    style: const TextStyle(
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
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    final themeService = Provider.of<ThemeService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeService.currentTheme.textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Username is required';
            }
            if (value.trim().length < 3) {
              return 'Username must be at least 3 characters';
            }
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
              return 'Username can only contain letters, numbers, and underscores';
            }
            if (isUsernameAvailable == false) {
              return 'Username is already taken';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Enter your username',
            prefixIcon: Icon(
              Icons.alternate_email, 
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            suffixIcon: _buildUsernameSuffixIcon(),
            filled: true,
            fillColor: themeService.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeService.currentTheme.textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon, 
              color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            filled: true,
            fillColor: themeService.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: themeService.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeService.currentTheme.textTheme.titleMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: themeService.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeService.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon, 
                color: themeService.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: themeService.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProfilePictureDialog() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: themeService.currentTheme.dialogTheme.backgroundColor,
          title: Text(
            'Change Profile Picture',
            style: themeService.currentTheme.textTheme.titleLarge,
          ),
          content: Text(
            'Profile picture functionality will be implemented soon!',
            style: themeService.currentTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: themeService.currentTheme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 