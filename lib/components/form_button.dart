import 'package:flutter/material.dart';

class Formbutton extends StatelessWidget {
  final String text;
  final Widget destination;

  const Formbutton({super.key, required this.destination, required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
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
          child: Text(text, style: textTheme.labelLarge),
        ),
      ),
    );
  }
}
