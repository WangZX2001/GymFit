import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymfit/components/chatbot.dart';
import 'package:gymfit/pages/body_data/form_page4.dart';

class FormPage3 extends StatefulWidget {
  const FormPage3({super.key});

  @override
  State<FormPage3> createState() => _FormPage3State();
}

class _FormPage3State extends State<FormPage3> {
  List<int> years = List.generate(90, (index) => 1935 + index);

  int selectedYear = 2000;
  // Scroll controller to scroll to default year
  late FixedExtentScrollController scrollController;

  @override
  void initState() {
    super.initState();

    // Get index of the default year and scroll to it
    final defaultIndex = years.indexOf(selectedYear);
    scrollController = FixedExtentScrollController(initialItem: defaultIndex);
  }

  void saveBirthYear() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'age': DateTime.now().year - selectedYear,
      }, SetOptions(merge: true));

      // Navigate to the next screen
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const FormPage4()),
      );
    }
  }

  Widget nextButton() {
    return GestureDetector(
      onTap: saveBirthYear,

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
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What is your birth year?',
                    style: textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 20),
                Chatbot(
                  text:
                      "This will help us tailor workouts to suit your body's capabilities and ensure safe training",
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: scrollController,
                    itemExtent: 50,
                    diameterRatio: 0.7,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedYear = years[index];
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: years.length,
                      builder: (context, index) {
                        final year = years[index];
                        final isSelected = year == selectedYear;
                        return Container(
                          width: 130,
                          alignment: Alignment.center,
                          decoration:
                              isSelected
                                  ? BoxDecoration(
                                    border: Border.all(
                                      color: Color(0xFF0070F0),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    color: Color(0x4780BBFF),
                                  )
                                  : null,
                          child: Text(
                            year.toString(),
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color:
                                  isSelected ? Color(0xFF0070F0) : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
