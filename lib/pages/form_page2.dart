import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FormPage2 extends StatelessWidget {
  FormPage2({super.key});

  final user = FirebaseAuth.instance.currentUser!;
  //sign user out function
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    //final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [IconButton(onPressed: signUserOut, icon: Icon(Icons.logout))],
      ),
      backgroundColor: Colors.white,
    );
  }
}
