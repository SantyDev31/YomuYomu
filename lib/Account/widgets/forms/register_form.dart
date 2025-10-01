import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yomuyomu/Account/widgets/terms_conditions.dart';
import 'package:yomuyomu/DataBase/firebase_helper.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  final Future<void> Function(String username, String email) saveUserToDatabase;

  const RegisterForm({
    super.key,
    required this.onRegisterSuccess,
    required this.saveUserToDatabase,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authResult = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final firebaseUser = authResult.user;
      if (firebaseUser == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      await widget.saveUserToDatabase(
        _usernameController.text.trim(),
        _emailController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada exitosamente')),
      );

      FirebaseService().syncUserNotesWithFirestore();
      FirebaseService().syncUserProgressWithFirestore();
      widget.onRegisterSuccess();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); 
      _showErrorDialog('No se pudo crear la cuenta:\n$e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Nombre de usuario'),
              validator:
                  (value) =>
                      value!.isEmpty ? 'Ingrese un nombre de usuario' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value!.isEmpty ? 'Ingrese su email' : null,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
              validator:
                  (value) => value!.isEmpty ? 'Ingrese una contraseña' : null,
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text("Registrarse"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "By signing up, you agree to these ",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TermsAndConditions(),
                          ),
                        );
                      },
                      child: const Text(
                        "terms and conditions",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.cyan,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      ".",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
