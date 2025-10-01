import 'package:flutter/material.dart';
import 'package:yomuyomu/Account/model/account_model.dart';

class UserAvatarWidget extends StatelessWidget {
  final AccountModel? account;
  final VoidCallback onLogout;
  final VoidCallback onLoginRegister;

  const UserAvatarWidget({
    required this.account,
    required this.onLogout,
    required this.onLoginRegister,
    super.key,
  });

  bool _isEmailValid(String? email) {
    return email != null &&
        email != ('local@local.a') &&
        email.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = account != null && _isEmailValid(account!.email);

    return Row(
      children: [
        const CircleAvatar(radius: 40),
        const SizedBox(width: 16),
        Expanded(
          child:
              isLoggedIn
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account!.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: onLogout,
                        child: Text(
                          account!.email,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  )
                  : GestureDetector(
                    onTap: onLoginRegister,
                    child: const Text(
                      'Login / Register',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
        ),
      ],
    );
  }
}
