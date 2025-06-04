import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymfit/components/chatbot.dart';
import 'package:gymfit/pages/form_page10.dart';

class FormPage9 extends StatefulWidget {
  const FormPage9({super.key});

  @override
  State<FormPage9> createState() => _FormPage9State();
}

class _FormPage9State extends State<FormPage9> {
  final user = FirebaseAuth.instance.currentUser!;

  String fitnesslevel = '';

  // Save fitness level to Firebase Firestore
  void saveFitnessLevelToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && fitnesslevel.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fitness level': fitnesslevel,
      }, SetOptions(merge: true));
    }

    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const FormPage10()),
    );
  }

  Widget fitnessCard(String level) {
    bool isSelected = fitnesslevel == level;

    return GestureDetector(
      onTap: () {
        setState(() {
          fitnesslevel = level;
        });
      },
      child: Container(
        width: 292,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Color(0x6080BBFF) : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          level,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.blue : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget nextButton() {
    bool canProceed = fitnesslevel.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (canProceed) {
          saveFitnessLevelToFirestore();
        }
      },

      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 100, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: LinearGradient(
            colors: [Color(0xFF396599), Color((0xFF5EA9FF))],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Text(
          'Next',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "What is your current fitness level?",
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Column(
                  spacing: 30,
                  children: [
                    fitnessCard('Beginner'),
                    fitnessCard('Intermediate'),
                    fitnessCard('Advance'),
                  ],
                ),
                const Spacer(),
                Chatbot(
                  text:
                      '“To avoid showing exercises that are too advanced or too easy”',
                ),
                const SizedBox(height: 40),
                nextButton(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
