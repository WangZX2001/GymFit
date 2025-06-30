import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/components/chatbot.dart';
import 'package:gymfit/pages/body_data/form_page8.dart';

class FormPage7 extends StatefulWidget {
  const FormPage7({super.key});

  @override
  State<FormPage7> createState() => _FormPage7State();
}

class _FormPage7State extends State<FormPage7> {
  final user = FirebaseAuth.instance.currentUser!;

  String selectedGoal = '';

  // Save selectedGoal to Firebase Firestore
  void saveGoalToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && selectedGoal.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'goal': selectedGoal,
      }, SetOptions(merge: true));
    }

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const FormPage8()),
    );
  }

  Widget goalCard(String goal, String imagePath) {
    bool isSelected = selectedGoal == goal;

    return GestureDetector(
      onTap: () {
        //when user tap on the goal, the selectedGoal will be set to the respective goal
        setState(() {
          selectedGoal = goal;
        });
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? Color(0x6080BBFF) : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Image.asset(imagePath, height: 60),
            const SizedBox(height: 10),
            Text(
              goal,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.blue : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget nextButton() {
    bool canProceed = selectedGoal.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (canProceed) {
          HapticFeedback.mediumImpact();
          saveGoalToFirestore();
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
                  "What is your personal fitness goal?",
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    goalCard('Lose Weight', 'lib/images/belly.png'),
                    goalCard('Gain Muscle', 'lib/images/muscle.png'),
                    goalCard('Endurance', 'lib/images/endurance.png'),
                    goalCard('Cardio', 'lib/images/cardiology.png'),
                  ],
                ),
                const SizedBox(height: 20),
                Chatbot(
                  text:
                      "“We ask about your fitness goal so I can better guide you.”",
                ),
                const Spacer(),
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
