import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gymfit/auth_service.dart';
import 'package:gymfit/components/my_button.dart';
import 'package:gymfit/components/my_textfield.dart';
import 'package:gymfit/components/square_tile.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //Text Editing Controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmedpasswordController = TextEditingController();

  //Sign User Up
  void signUserUp() async {
    // First check if passwords match
    if (passwordController.text != confirmedpasswordController.text) {
      showErrorDialog('Passwords don\'t match');
      return;
    }

    // Now show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.blue, strokeWidth: 2),
        );
      },
    );

    // Try creating the user
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ignore: use_build_context_synchronously
      Navigator.pop(context); // close the spinner
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close the spinner

      if (e.code == 'email-already-in-use') {
        showErrorDialog('This email is already registered.');
      } else if (e.code == 'invalid-email') {
        showErrorDialog('Invalid email address format.');
      } else if (e.code == 'weak-password') {
        showErrorDialog('Password should be at least 6 characters.');
      } else {
        showErrorDialog('Registration failed: ${e.code}');
      }
    }
  }

  //dialog box for
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                const SizedBox(height: 50),
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
                  'GymFit \u00a9',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'DMSans',
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Let\'s create an account now!',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 10),

                //Username Textfield
                MyTextfield(
                  controller: emailController,
                  hintText: 'Email Address',
                  obscureText: false,
                ),

                const SizedBox(height: 10),

                //Password Textfield
                MyTextfield(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),

                const SizedBox(height: 10),

                //Confirm Password Textfield
                MyTextfield(
                  controller: confirmedpasswordController,
                  hintText: 'Comfirm Password',
                  obscureText: true,
                ),

                const SizedBox(height: 10),

                //Forget Password
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

                //Sign In Button
                MyButton(onTap: signUserUp, text: "Sign Up Now"),

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
                    //google button
                    SquareTile(ImagePath: 'lib/images/google icon.png', onTap: () => AuthService().signInWithGoogle(),),
                    SquareTile(ImagePath: 'lib/images/apple icon.png', onTap: () {},),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
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
                        'Login Now',
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
