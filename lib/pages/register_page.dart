import 'package:flutter/material.dart';
import 'package:gymfit/components/my_button.dart';
import 'package:gymfit/components/my_textfield.dart';
import 'package:gymfit/components/square_tile.dart';
import 'package:gymfit/auth_service.dart';
import '../services/auth_interface.dart';
import '../services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  final AuthInterface? authService;

  const RegisterPage({super.key, required this.onTap, this.authService});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmedpasswordController = TextEditingController();

  void signUserUp() async {
    if (passwordController.text != confirmedpasswordController.text) {
      showErrorDialog('Passwords don’t match');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
      ),
    );

    try {
      final auth = widget.authService ?? FirebaseAuthService();
      await auth.register(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          showErrorDialog('This email is already registered.');
        } else if (e.code == 'invalid-email') {
          showErrorDialog('Invalid email address format.');
        } else if (e.code == 'weak-password') {
          showErrorDialog('Password should be at least 6 characters.');
        } else {
          showErrorDialog('Registration failed: ${e.code}');
        }
      } else {
        showErrorDialog('An unexpected error occurred.');
      }
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text('Welcome To', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('GymFit ©', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
                const Text('Let\'s create an account now!', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 10),

                MyTextfield(
                  key: const Key('emailField'),
                  controller: emailController,
                  hintText: 'Email Address',
                  obscureText: false,
                ),
                const SizedBox(height: 10),

                MyTextfield(
                  key: const Key('passwordField'),
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                MyTextfield(
                  key: const Key('confirmPasswordField'),
                  controller: confirmedpasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(height: 30),

                MyButton(onTap: signUserUp, text: "Sign Up Now"),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(
                      ImagePath: 'lib/images/google icon.png',
                      onTap: () => AuthService().signInWithGoogle(),
                    ),
                    SquareTile(
                      ImagePath: 'lib/images/apple icon.png',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text('Login Now', style: TextStyle(color: Colors.blue, fontSize: 13)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
