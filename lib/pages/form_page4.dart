import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymfit/components/chatbot.dart';
import 'package:gymfit/pages/form_page5.dart';

class FormPage4 extends StatefulWidget {
  const FormPage4({super.key});

  @override
  State<FormPage4> createState() => _FormPage4State();
}

class _FormPage4State extends State<FormPage4> {
  List<int> height = List.generate(150, (index) => 100 + index);

  int selectedHeight = 170;
  // Scroll controller to scroll to default height
  late FixedExtentScrollController scrollController;

  @override
  void initState() {
    super.initState();

    // Get index of the default height and scroll to it
    final defaultIndex = height.indexOf(selectedHeight);
    scrollController = FixedExtentScrollController(initialItem: defaultIndex);
  }

  void saveHeight() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'height': selectedHeight,
      }, SetOptions(merge: true));

      // Navigate to the next screen
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const FormPage5()),
      );
    }
  }

  Widget nextButton() {
    return GestureDetector(
      onTap: saveHeight,

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
                    'What is your height?',
                    style: textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 20),
                Chatbot(
                  text:
                      "“This is for us to calculate your Body Mass Index and adjust workouts to better suit your goal”",
                ),
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  width: 130,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFF0070F0), width: 3),
                    borderRadius: BorderRadius.circular(30),
                    color: Color(0x4780BBFF),
                  ),
                  child: Text(
                    'cm',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0070F0),
                    ),
                  ),
                ),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    controller: scrollController,
                    itemExtent: 50,
                    diameterRatio: 0.7,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedHeight = height[index];
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: height.length,
                      builder: (context, index) {
                        final heightincm = height[index];
                        final isSelected = heightincm == selectedHeight;
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
                            heightincm.toString(),
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
