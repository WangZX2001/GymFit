import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymfit/components/my_textfield.dart';
import 'package:gymfit/pages/body_data/form_page2.dart';

class FormPage1 extends StatefulWidget {
  const FormPage1({super.key});

  @override
  State<FormPage1> createState() => _FormPage1State();
}

class _FormPage1State extends State<FormPage1> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  
  bool isLoading = false;
  String? nameError;
  String? usernameError;
  
  // Username validation states
  bool isCheckingUsername = false;
  bool? isUsernameAvailable;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Add listener for real-time username validation
    usernameController.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final username = usernameController.text.trim();
    
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

  bool _validateInputs() {
    setState(() {
      nameError = null;
      usernameError = null;
    });

    bool isValid = true;

    // Validate name
    if (nameController.text.trim().isEmpty) {
      setState(() {
        nameError = 'Please enter your name';
      });
      isValid = false;
    } else if (nameController.text.trim().length < 2) {
      setState(() {
        nameError = 'Name must be at least 2 characters';
      });
      isValid = false;
    }

    // Validate username
    if (usernameController.text.trim().isEmpty) {
      setState(() {
        usernameError = 'Please enter a username';
      });
      isValid = false;
    } else if (usernameController.text.trim().length < 3) {
      setState(() {
        usernameError = 'Username must be at least 3 characters';
      });
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(usernameController.text.trim())) {
      setState(() {
        usernameError = 'Username can only contain letters, numbers, and underscores';
      });
      isValid = false;
    }

    return isValid;
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

  Future<void> _proceedToNextPage() async {
    if (!_validateInputs()) return;

    setState(() {
      isLoading = true;
      usernameError = null;
    });

    try {
      // Check username uniqueness (use cached result if available)
      bool isUnique;
      if (isUsernameAvailable != null) {
        isUnique = isUsernameAvailable!;
      } else {
        isUnique = await _isUsernameUnique(usernameController.text);
      }
      
      if (!isUnique) {
        setState(() {
          usernameError = 'Username is already taken';
          isLoading = false;
        });
        return;
      }

      // Save name and username to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'name': nameController.text.trim(),
          'username': usernameController.text.trim().toLowerCase(),
        }, SetOptions(merge: true));

        // Navigate to next page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormPage2()),
          );
        }
      }
    } catch (e) {
      setState(() {
        usernameError = 'Error saving data. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside text fields
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [Text('Hello !', style: textTheme.headlineMedium)],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    '"I\'m Alex, your dedicated trainer on a journey to transform your body and mind."',
                    style: textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'lib/images/boy.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  Text(
                    'Let\'s start by getting to know you better!',
                    style: textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Name input field
                  MyTextfield(
                    controller: nameController,
                    hintText: 'Your Name',
                    obscureText: false,
                  ),
                  
                  if (nameError != null) ...[
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          nameError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 15),
                  
                                  // Username input field
                MyTextfield(
                  controller: usernameController,
                  hintText: 'Choose a Username',
                  obscureText: false,
                  suffixIcon: _buildUsernameSuffixIcon(),
                ),
                  
                  if (usernameError != null) ...[
                    const SizedBox(height: 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          usernameError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 30),
                  
                  Text(
                    'Before we start on your fitness journey, here are a few questions for us to tailor a better fitness plan for you.',
                    style: textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Custom button that handles loading state
                  GestureDetector(
                    onTap: isLoading ? null : _proceedToNextPage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                                          decoration: BoxDecoration(
                      color: isLoading ? Colors.grey : Colors.blue,
                      borderRadius: BorderRadius.circular(25),
                    ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "I'M READY",
                                style: textTheme.labelLarge,
                              ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
