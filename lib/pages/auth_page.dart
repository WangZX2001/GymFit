import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gymfit/pages/body_data/form_page1.dart';
import 'package:gymfit/components/persistent_nav.dart';
//import 'package:gymfit/pages/login_page.dart';
import 'package:gymfit/pages/login_or_register_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(snapshot.data!.uid)
                      .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;

                final hasAllFields =
                    userData != null &&
                    userData.containsKey('height') &&
                    userData.containsKey('weight') &&
                    userData.containsKey('bmi') &&
                    userData.containsKey('target weight') &&
                    userData.containsKey('goal');

                return hasAllFields ? const PersistentNavBar(initialIndex: 0) : const FormPage1();
              },
            );
          } else {
            return const LoginOrRegister();
          }
        },
      ),
    );

    /*return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          //if there is an user logged
          if(snapshot.hasData) {
            return FormPage1();
          } else {
            return LoginOrRegister();
          }
        } 
      ),
    );
  }*/
  }
}
