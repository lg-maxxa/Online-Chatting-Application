import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_chat/services/auth_service.dart';
import 'package:nexus_chat/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService.tryAutoLogin', () {
    test('returns false and clears invalid stored session payload', () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.tokenKey: 'token-1',
        AppConstants.userKey: '{broken-json',
      });

      final authService = AuthService();
      final loggedIn = await authService.tryAutoLogin();

      expect(loggedIn, isFalse);
      expect(authService.isAuthenticated, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.tokenKey), isNull);
      expect(prefs.getString(AppConstants.userKey), isNull);
    });
  });
}
