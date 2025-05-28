import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymfit/components/chatbot.dart';

class FormPage2 extends StatefulWidget {
  const FormPage2({super.key});

  @override
  State<FormPage2> createState() => _FormPage2State();
}

class _FormPage2State extends State<FormPage2> {
  final user = FirebaseAuth.instance.currentUser!;

  //sign user out function
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [IconButton(onPressed: signUserOut, icon: Icon(Icons.logout))],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text("What is your Gender?", style: textTheme.headlineMedium),
            const SizedBox(height: 10),
            Chatbot(
              text:
                  "“Gender influences key health metrics like BMR, calorie needs, body fat percentage, enabling more accurate fitness planning.”",
            ),
          ],
        ),
      ),
    );
  }
}
