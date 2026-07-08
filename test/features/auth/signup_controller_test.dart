import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/auth/controller/signup_controller.dart';

void main() {
  late SignupController controller;

  setUp(() {
    controller = SignupController();
  });

  tearDown(() {
    controller.onClose();
  });

  // ── isEmailValid ─────────────────────────────────────────────────────────

  group('isEmailValid', () {
    test('returns true for valid email', () {
      expect(controller.isEmailValid('test@example.com'), isTrue);
    });

    test('returns true for email with dots in local part', () {
      expect(controller.isEmailValid('first.last@domain.org'), isTrue);
    });

    test('returns false for missing @', () {
      expect(controller.isEmailValid('testexample.com'), isFalse);
    });

    test('returns false for empty string', () {
      expect(controller.isEmailValid(''), isFalse);
    });

    test('returns false for missing TLD', () {
      expect(controller.isEmailValid('user@domain'), isFalse);
    });
  });

  // ── isPasswordValid ──────────────────────────────────────────────────────

  group('isPasswordValid', () {
    test('returns true for password with exactly 6 characters', () {
      expect(controller.isPasswordValid('123456'), isTrue);
    });

    test('returns true for password longer than 6 characters', () {
      expect(controller.isPasswordValid('supersecret'), isTrue);
    });

    test('returns false for password shorter than 6 characters', () {
      expect(controller.isPasswordValid('12345'), isFalse);
    });

    test('returns false for empty password', () {
      expect(controller.isPasswordValid(''), isFalse);
    });
  });

  // ── isPasswordMatched ────────────────────────────────────────────────────

  group('isPasswordMatched', () {
    test('returns true when passwords match', () {
      controller.passwordTextController.text = 'password123';
      controller.confirmPasswordTextController.text = 'password123';
      expect(controller.isPasswordMatched(), isTrue);
    });

    test('returns false when passwords differ', () {
      controller.passwordTextController.text = 'password123';
      controller.confirmPasswordTextController.text = 'different';
      expect(controller.isPasswordMatched(), isFalse);
    });

    test('returns true when both passwords are empty strings', () {
      controller.passwordTextController.text = '';
      controller.confirmPasswordTextController.text = '';
      expect(controller.isPasswordMatched(), isTrue);
    });
  });

  // ── isInfoCompleted ──────────────────────────────────────────────────────

  group('isInfoCompleted', () {
    void fillAll() {
      controller.fullNameTextController.text = 'John Doe';
      controller.emailTextController.text = 'john@example.com';
      controller.passwordTextController.text = 'password123';
      controller.confirmPasswordTextController.text = 'password123';
    }

    test('returns false when all fields are empty', () {
      expect(controller.isInfoCompleted(), isFalse);
    });

    test('returns true when all fields are filled', () {
      fillAll();
      expect(controller.isInfoCompleted(), isTrue);
    });

    test('returns false when fullName is missing', () {
      fillAll();
      controller.fullNameTextController.text = '';
      expect(controller.isInfoCompleted(), isFalse);
    });

    test('returns false when email is missing', () {
      fillAll();
      controller.emailTextController.text = '';
      expect(controller.isInfoCompleted(), isFalse);
    });

    test('returns false when password is missing', () {
      fillAll();
      controller.passwordTextController.text = '';
      expect(controller.isInfoCompleted(), isFalse);
    });

    test('returns false when confirm password is missing', () {
      fillAll();
      controller.confirmPasswordTextController.text = '';
      expect(controller.isInfoCompleted(), isFalse);
    });
  });

  // ── toggleTermsAgree ─────────────────────────────────────────────────────

  group('toggleTermsAgree', () {
    test('starts false', () {
      expect(controller.isTermsAgree.value, isFalse);
    });

    test('toggles to true on first call', () {
      controller.toggleTermsAgree();
      expect(controller.isTermsAgree.value, isTrue);
    });

    test('toggles back to false on second call', () {
      controller.toggleTermsAgree();
      controller.toggleTermsAgree();
      expect(controller.isTermsAgree.value, isFalse);
    });
  });
}
