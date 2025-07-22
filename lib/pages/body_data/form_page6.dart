import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gymfit/pages/body_data/form_page7.dart';

class FormPage6 extends StatefulWidget {
  const FormPage6({super.key});

  @override
  State<FormPage6> createState() => _FormPage6State();
}

class _FormPage6State extends State<FormPage6> {
  // Separate lists for whole numbers and decimals
  final List<int> wholeNumbers = List.generate(
    200,
    (index) => index + 1,
  ); // 1 to 200
  final List<double> decimals = [
    0.0,
    0.1,
    0.2,
    0.3,
    0.4,
    0.5,
    0.6,
    0.7,
    0.8,
    0.9,
  ];

  int selectedWholeNumber = 70;
  double selectedDecimal = 0.0;
  double selectedWeight = 70.0;
  double? userWeight;

  late FixedExtentScrollController wholeNumberController;
  late FixedExtentScrollController decimalController;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with default values
    wholeNumberController = FixedExtentScrollController(
      initialItem: selectedWholeNumber - 1,
    );
    decimalController = FixedExtentScrollController(initialItem: 0);

    fetchUserWeight();
  }

  // Handle whole number change
  void _handleWholeNumberChange(int newWholeNumber) {
    HapticFeedback.selectionClick();
    setState(() {
      selectedWholeNumber = newWholeNumber;
      selectedWeight = selectedWholeNumber + selectedDecimal;
    });
  }

  // Handle decimal change
  void _handleDecimalChange(double newDecimal) {
    HapticFeedback.selectionClick();
    setState(() {
      selectedDecimal = newDecimal;
      selectedWeight = selectedWholeNumber + selectedDecimal;
    });
  }

  Future<void> fetchUserWeight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists && doc.data()!.containsKey('starting weight')) {
        setState(() {
          userWeight = (doc['starting weight'] as num).toDouble();
        });
      }
    }
  }

  @override
  void dispose() {
    wholeNumberController.dispose();
    decimalController.dispose();
    super.dispose();
  }

  void saveTargetWeight() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Map<String, dynamic> data = {
        'target weight': double.parse(selectedWeight.toStringAsFixed(1)),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const FormPage7()),
      );
    }
  }

  Widget weightchatbot() {
    if (userWeight == null) {
      return const SizedBox(); // show nothing until userWeight is loaded
    }

    final diff = selectedWeight - userWeight!;
    final Color diffColor = diff < 0 ? Colors.red : Colors.green;
    final String diffText =
        "${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)} kg";

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
              Text(
                diffText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: diffColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"In order to hit this target weight, you need to"',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'adjust your weight by the amount shown.',
                  style: TextStyle(fontSize: 14, color: Colors.black),
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
        saveTargetWeight();
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
                Text.rich(
                  TextSpan(
                    text: 'What is your ',
                    style: textTheme.headlineMedium,
                    children: const [
                      TextSpan(
                        text: 'TARGET',
                        style: TextStyle(color: Colors.green),
                      ),
                      TextSpan(text: ' weight ?'),
                    ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Whole number picker
                    SizedBox(
                      width: 100,
                      height: 150,
                      child: ListWheelScrollView.useDelegate(
                        controller: wholeNumberController,
                        itemExtent: 50,
                        diameterRatio: 0.7,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          _handleWholeNumberChange(wholeNumbers[index]);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: wholeNumbers.length,
                          builder: (context, index) {
                            final wholeNumber = wholeNumbers[index];
                            final isSelected =
                                wholeNumber == selectedWholeNumber;
                            return Container(
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
                                wholeNumber.toString(),
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 24,
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
                    ),

                    // Decimal point
                    Container(
                      width: 30,
                      height: 150,
                      alignment: Alignment.center,
                      child: Text(
                        '.',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0070F0),
                        ),
                      ),
                    ),

                    // Decimal picker
                    SizedBox(
                      width: 80,
                      height: 150,
                      child: ListWheelScrollView.useDelegate(
                        controller: decimalController,
                        itemExtent: 50,
                        diameterRatio: 0.7,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          _handleDecimalChange(decimals[index]);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: decimals.length,
                          builder: (context, index) {
                            final decimal = decimals[index];
                            final isSelected = decimal == selectedDecimal;
                            return Container(
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
                                (decimal * 10).toInt().toString(),
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 24,
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
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                weightchatbot(),
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
