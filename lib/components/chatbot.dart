import 'package:flutter/material.dart';

class Chatbot extends StatelessWidget {
  final String text;

  const Chatbot({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color(0x6080BBFF),
      ),
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('lib/images/robot.png', height: 82, width: 82),
          Expanded(child: Text(text, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
