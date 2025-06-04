import 'package:flutter/material.dart';
import 'package:gymfit/pages/workout_screen.dart';
import 'package:gymfit/components/chatbot.dart';

class FormPage4 extends StatelessWidget {
  const FormPage4({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Almost there!',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              const Chatbot(
                text: "Great job completing your profile! Now let's start your fitness journey with a personalized workout plan.",
              ),
              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkoutScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF396599), Color(0xFF5EA9FF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Text(
                      "LET'S GO",
                      style: textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
