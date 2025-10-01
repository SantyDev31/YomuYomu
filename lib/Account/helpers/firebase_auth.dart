import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

Future<void> signIn(String email, String password) async {
  try {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  } catch (e) {
    print('Error signing in: $e');
  }
}

Future<void> signOut() async {
  await _auth.signOut();
}
