import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/components/chatbot.dart';
import 'package:gymfit/pages/body_data/form_page3.dart';

class FormPage2 extends StatefulWidget {
  const FormPage2({super.key});

  @override
  State<FormPage2> createState() => _FormPage2State();
}

class _FormPage2State extends State<FormPage2> {
  final user = FirebaseAuth.instance.currentUser!;

  String selectedGender = '';

  // Save selected gender to Firebase Firestore
  void saveGenderToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && selectedGender.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'gender': selectedGender,
      }, SetOptions(merge: true));
    }

    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const FormPage3()),
    );
  }

  Widget genderCard(String gender, String imagePath) {
    bool isSelected = selectedGender == gender;

    return GestureDetector(
      onTap: () {
        //when user tap on the gender, the selectedgender will be set to the respective gender
        setState(() {
          selectedGender = gender;
        });
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 30),
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
            Image.asset(imagePath, height: 80),
            const SizedBox(height: 10),
            Text(gender, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget nextButton() {
    bool canProceed = selectedGender.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (canProceed) {
          HapticFeedback.mediumImpact();
          saveGenderToFirestore();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "What is your Gender?",
                      style: textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Chatbot(
                  text:
                      "“Gender influences key health metrics like BMR, calorie needs, body fat percentage, enabling more accurate fitness planning.”",
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    genderCard('Male', 'lib/images/man.png'),
                    genderCard('Female', 'lib/images/woman.png'),
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
