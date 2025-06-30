import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/pages/body_data/form_page9.dart';

class FormPage8 extends StatefulWidget {
  const FormPage8({super.key});

  @override
  State<FormPage8> createState() => _FormPage8State();
}

class _FormPage8State extends State<FormPage8> {
  final user = FirebaseAuth.instance.currentUser!;

  String medicalcondition = '';

  // Save medical condition to Firebase Firestore
  void saveConditionToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && medicalcondition.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'medical condition': medicalcondition,
      }, SetOptions(merge: true));
    }

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const FormPage9()),
    );
  }

  Widget conditionCard(String condition, String imagePath1, String imagePath2) {
    bool isSelected = medicalcondition == condition;

    return GestureDetector(
      onTap: () {
        setState(() {
          medicalcondition = condition;
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
        child: Row(
          children: [
            Image.asset(isSelected ? imagePath1 : imagePath2, height: 40),
            const SizedBox(width: 20),
            Text(
              condition,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.blue : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget nextButton() {
    bool canProceed = medicalcondition.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (canProceed) {
          HapticFeedback.mediumImpact();
          saveConditionToFirestore();
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
                  "Have you had any pre existing medical condition?",
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Column(
                  spacing: 20,
                  children: [
                    conditionCard(
                      'None',
                      'lib/images/none_after.png',
                      'lib/images/none_before.png',
                    ),
                    conditionCard(
                      'High Blood Pressure',
                      'lib/images/hypertension_after.png',
                      'lib/images/hypertension_before.png',
                    ),
                    conditionCard(
                      'Flu',
                      'lib/images/sneeze_after.png',
                      'lib/images/sneeze_before.png',
                    ),
                    conditionCard(
                      'Bone Injuries',
                      'lib/images/bone_after.png',
                      'lib/images/bone_before.png',
                    ),
                  ],
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
