import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/pages/body_data/form_page6.dart';

class FormPage5 extends StatefulWidget {
  const FormPage5({super.key});

  @override
  State<FormPage5> createState() => _FormPage5State();
}

class _FormPage5State extends State<FormPage5> {
  final List<double> weight = List.generate(
    2000,
    (index) => (index + 1) * 0.1,
  ); // 0.1 to 200.0
  double selectedWeight = 70.0;
  double? userHeight;
  late ScrollController scrollController;
  final double itemWidth = 80 + 20; // 60 width + 10px margin left & right

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    fetchUserHeight();

    // Scroll to initial position after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final defaultIndex = weight.indexOf(selectedWeight);
        scrollController.jumpTo(defaultIndex * itemWidth);
      }
    });

    // Auto-update selected weight based on center position
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;

      final screenCenter = MediaQuery.of(context).size.width / 2;
      final centerOffset =
          scrollController.offset + (screenCenter - itemWidth / 2);
      int centerIndex = (centerOffset / itemWidth).round();
      final newSelected = weight[centerIndex];
      if (newSelected != selectedWeight) {
        _handleWeightChange(newSelected);
      }
    });
  }

  // Handle weight change with haptic feedback
  void _handleWeightChange(double newWeight) {
    // Haptic feedback for smooth scroll interaction
    HapticFeedback.selectionClick();
    
    // Update selected weight
    setState(() {
      selectedWeight = newWeight;
    });
  }

  Future<void> fetchUserHeight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists && doc.data()!.containsKey('height')) {
        setState(() {
          userHeight = (doc['height'] as num).toDouble();
        });
      }
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void saveWeight() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Map<String, dynamic> data = {
        'starting weight': double.parse(selectedWeight.toStringAsFixed(1)),
      };

      if (userHeight != null) {
        final heightInMeters = userHeight! / 100;
        final bmi = selectedWeight / (heightInMeters * heightInMeters);
        data['bmi'] = double.parse(bmi.toStringAsFixed(1));
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const FormPage6()),
      );
    }
  }

  Widget weightchatbot() {
    double? bmi;
    String statusText = "Calculating BMI...";
    Color bmiColor = Colors.black;

    if (userHeight != null) {
      final heightInMeters = userHeight! / 100;
      bmi = selectedWeight / (heightInMeters * heightInMeters);

      if (bmi < 18.5) {
        bmiColor = Colors.blue;
        statusText = "You need more nutrition and rest";
      } else if (bmi < 25) {
        bmiColor = Colors.green;
        statusText = "You're in good shape! Keep it up!";
      } else if (bmi < 30) {
        bmiColor = Colors.orange;
        statusText = "You need a bit more exercise to get in shape";
      } else {
        bmiColor = Colors.red;
        statusText = "Time to adopt a healthier lifestyle";
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0x6080BBFF),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Image.asset('lib/images/robot.png', height: 60, width: 60),
              const SizedBox(height: 8),
              if (bmi != null)
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '"Your Current BMI is"',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusText,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget nextButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        saveWeight();
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
        child: const Text(
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
                    'What is your weight?',
                    style: textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  width: 130,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF0070F0),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0x4780BBFF),
                  ),
                  child: const Text(
                    'kg',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0070F0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                weightchatbot(),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: weight.length,
                        itemBuilder: (context, index) {
                          final weightinkg = weight[index];
                          final isSelected = weightinkg == selectedWeight;

                          return Container(
                            width: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            alignment: Alignment.center,
                            decoration:
                                isSelected
                                    ? BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF0070F0),
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      color: const Color(0x4780BBFF),
                                    )
                                    : null,
                            child: Text(
                              weightinkg.toStringAsFixed(1),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color:
                                    isSelected
                                        ? const Color(0xFF0070F0)
                                        : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Spacer(),
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
