import 'package:firebase_auth/firebase_auth.dart';
import 'auth_interface.dart';

class FirebaseAuthService implements AuthInterface {
  final FirebaseAuth _auth;

  FirebaseAuthService([FirebaseAuth? instance])
      : _auth = instance ?? FirebaseAuth.instance;

  @override
  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
