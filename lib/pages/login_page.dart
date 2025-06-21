import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymfit/auth_service.dart';
import 'package:gymfit/components/my_button.dart';
import 'package:gymfit/components/my_textfield.dart';
import 'package:gymfit/components/square_tile.dart';
import 'package:gymfit/components/persistent_nav.dart';
import 'package:gymfit/services/auth_interface.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  final AuthInterface? authService;

  const LoginPage({super.key, required this.onTap, this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void signUserIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
        );
      },
    );

    try {
      if (widget.authService != null) {
        await widget.authService!.login(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const PersistentNavBar(initialIndex: 0),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (e.code == 'invalid-credential') {
        showErrorDialog('Invalid email or password. Please try again.');
      } else {
        showErrorDialog('Login failed: ${e.code}');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (e is FirebaseAuthException) {
        showErrorDialog('Login failed: ${e.code}');
      } else {
        showErrorDialog('Login failed: ${e.toString()}');
      }
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Failed'),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 100),
                Text(
                  'Welcome To',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'DMSans',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'GymFit ©',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'DMSans',
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your Ultimate Gym Partner',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        'Forget the Password?',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                MyButton(onTap: signUserIn, text: "Sign In"),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 0.8, color: Colors.black),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Text(
                          'Or Continue With',
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 0.8, color: Colors.black),
                      ),
                    ],
                  ),
                ),
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
                    Text(
                      'Not a member yet?',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Register Now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}