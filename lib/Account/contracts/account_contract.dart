import 'package:yomuyomu/Account/model/account_model.dart';

abstract class AccountViewContract {
  void updateAccount(AccountModel? account);
  void showLoading();
  void hideLoading();
  void showError(String message);
}


abstract class AccountPresenterContract {
  Future<void> logout();
  Future<void> loadUserData();
  Future<void> saveUserToDatabase(String nickname, String email);
}
