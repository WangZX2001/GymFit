import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AddWeightPage extends StatefulWidget {
  const AddWeightPage({super.key});

  @override
  State<AddWeightPage> createState() => _AddWeightPageState();
}

class _AddWeightPageState extends State<AddWeightPage> {
  double selectedWeight = 70.0;
  DateTime selectedDate = DateTime.now();
  double? latestLoggedWeight;

  @override
  void initState() {
    super.initState();
    fetchLatestWeightLog();
  }

  Future<void> fetchLatestWeightLog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('weightLogs')
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          latestLoggedWeight = (data['weight'] as num).toDouble();
        });
      }
    }
  }

  Future<void> submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('weightLogs')
          .add({
            'weight': selectedWeight,
            'date': Timestamp.fromDate(selectedDate),
          });
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Add Weight',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'DM Sans',
            fontSize: 25,
            fontWeight: FontWeight.w300,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: submit,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRow(
            'Weight',
            '${selectedWeight.toStringAsFixed(1)} kg',
            _pickWeight,
          ),
          const Divider(height: 1, color: Colors.black),
          _buildRow(
            'Date',
            DateFormat('dd MMM yyyy').format(selectedDate),
            _pickDate,
          ),
          const Divider(height: 1, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: const Color.fromARGB(255, 200, 200, 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                fontFamily: 'DM Sans',
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 20,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickWeight() async {
    final controller = TextEditingController(
      text: selectedWeight.toStringAsFixed(1),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Your Weight'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
            ],
            decoration: const InputDecoration(
              hintText: 'Weight in kg',
              hintStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 18),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final input = double.tryParse(controller.text);
                if (input != null) {
                  setState(() => selectedWeight = input);
                }
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
