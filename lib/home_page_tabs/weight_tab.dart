import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymfit/pages/add_weight_page.dart';
import 'package:gymfit/components/weight_trend_graph.dart'; // ensure this contains WeightTrendGraphState

class WeightTab extends StatefulWidget {
  const WeightTab({super.key});

  @override
  State<WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends State<WeightTab> {
  double? startingWeight;
  double? targetWeight;
  double? currentWeight;
  bool isLoading = true;

  final GlobalKey<WeightTrendGraphState> _graphKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fetchWeights();
  }

  Future<void> fetchWeights() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();

      final weightLogSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('weightLogs')
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (data != null) {
        setState(() {
          startingWeight = (data['starting weight'] as num?)?.toDouble();
          targetWeight = (data['target weight'] as num?)?.toDouble();
          if (weightLogSnap.docs.isNotEmpty) {
            currentWeight =
                (weightLogSnap.docs.first['weight'] as num?)?.toDouble();
          }
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Image.asset('lib/images/compass.png', width: 120, height: 50),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.grey.shade800, width: 2),
                ),
                child: Text(
                  currentWeight != null
                      ? '${currentWeight!.toStringAsFixed(1)} kg'
                      : '--',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Current Weight',
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      child: SizedBox(
                        width: 200,
                        height: 100,
                        child: CustomPaint(painter: TopArcPainter()),
                      ),
                    ),

                    Positioned(
                      top: 110,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${startingWeight?.toStringAsFixed(1) ?? "--"}kg',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Starting Weight',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${targetWeight?.toStringAsFixed(1) ?? "--"}kg',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Target Weight',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      top: 80,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.blue[300],
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset('lib/images/strong.png'),
                      ),
                    ),

                    Positioned(
                      top: 155,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'Good Job',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Weight Trend Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Weight Trend',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'For the last 7 days',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddWeightPage(),
                  ),
                ).then((_) {
                  fetchWeights(); // refresh current weight
                  _graphKey.currentState?.refresh(); // refresh graph
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Add New Weight',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'DM Sans',
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Graph with key
        WeightTrendGraph(key: _graphKey),
      ],
    );
  }
}

class TopArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade500
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final Rect rect = Rect.fromLTRB(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, 3.14, 3.14, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
