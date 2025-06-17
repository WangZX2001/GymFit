import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class WeightTrendGraph extends StatefulWidget {
  const WeightTrendGraph({super.key});

  @override
  State<WeightTrendGraph> createState() => WeightTrendGraphState();
}

class WeightTrendGraphState extends State<WeightTrendGraph> {
  List<FlSpot> weightSpots = [];
  List<String> xLabels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWeightLogs();
  }

  void refresh() {
    setState(() {
      isLoading = true;
    });
    fetchWeightLogs();
  }

  Future<void> fetchWeightLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final query =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('weightLogs')
              .orderBy('date', descending: true)
              .get();

      final Map<String, double> latestByDate = {};
      for (final doc in query.docs) {
        final weight = (doc['weight'] as num).toDouble();
        final timestamp = doc['date'] as Timestamp;
        final dateStr = DateFormat('yyyy-MM-dd').format(timestamp.toDate());
        latestByDate.putIfAbsent(dateStr, () => weight);
      }

      final List<FlSpot> spots = [];
      final List<String> labels = [];

      final today = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final label = DateFormat('MM/dd').format(day);
        labels.add(label);

        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        if (latestByDate.containsKey(dateStr)) {
          final weight = latestByDate[dateStr]!;
          spots.add(FlSpot((6 - i).toDouble(), weight));
        }
      }

      setState(() {
        weightSpots = spots;
        xLabels = labels;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        return Text(
                          index >= 0 && index < xLabels.length
                              ? xLabels[index]
                              : '',
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      reservedSize: 40,
                      getTitlesWidget:
                          (value, meta) => Text(
                            '${value.toInt()}kg',
                            style: const TextStyle(fontSize: 10),
                          ),
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData:
                    weightSpots.isNotEmpty
                        ? [
                          LineChartBarData(
                            isCurved: true,
                            spots: weightSpots,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withAlpha(50),
                            ),
                            color: Colors.blue,
                            barWidth: 3,
                          ),
                        ]
                        : [],
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: 6,
              ),
            ),
          ),
        );
  }
}
