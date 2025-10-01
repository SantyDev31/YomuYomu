import 'package:flutter/material.dart';
import 'package:yomuyomu/Account/widgets/forms/login_form.dart';
import 'package:yomuyomu/Account/widgets/forms/register_form.dart';

class LoginRegisterDialog extends StatelessWidget {
  final VoidCallback loadUserData;
  final Future<void> Function(String username, String email) saveUserToDatabase;

  const LoginRegisterDialog({
    super.key,
    required this.loadUserData,
    required this.saveUserToDatabase,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final dialogWidth =
        isWideScreen ? 600.0 : MediaQuery.of(context).size.width * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 550),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    indicatorColor: Colors.cyan,
                    labelColor: Colors.cyan,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Login'),
                      Tab(text: 'Register'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: dialogWidth,
                    height: 400,
                    child: TabBarView(
                      children: [
                        LoginForm(onLoginSuccess: loadUserData),
                        RegisterForm(
                          onRegisterSuccess: loadUserData,
                          saveUserToDatabase: saveUserToDatabase,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Close",
                      style: TextStyle(color: Colors.cyan),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
