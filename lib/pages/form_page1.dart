import 'package:flutter/material.dart';
import 'package:gymfit/components/form_button.dart';
import 'package:gymfit/pages/form_page2.dart';

class FormPage1 extends StatelessWidget {
  const FormPage1({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [Text('Hello !', style: textTheme.headlineMedium)],
                ),

                const SizedBox(height: 10),

                Text(
                  '"I\'m Alex, your dedicated trainer on a journey to transform your body and mind."',
                  style: textTheme.bodyMedium,
                ),

                const SizedBox(height: 30),
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
                const SizedBox(height: 100),
                Text(
                  'Before we start on your fitness journey, here are a few questions for us to tailor a better fitness plan for you. ',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 30),
                FORMBUTTON(destination: FormPage2(), text: "I'M READY"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
