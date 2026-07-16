import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/auth/controller/login_controller.dart';

void main() {
  late LoginController controller;

  setUp(() {
    controller = LoginController();
  });

  // ── isEmailValid ─────────────────────────────────────────────────────────

  group('isEmailValid', () {
    test('returns true for standard email', () {
      expect(controller.isEmailValid('user@example.com'), isTrue);
    });

    test('returns true for email with subdomain', () {
      expect(controller.isEmailValid('user@mail.example.co.uk'), isTrue);
    });

    test('returns true for email with plus alias', () {
      expect(controller.isEmailValid('user+tag@example.com'), isTrue);
    });

    test('returns false for missing @', () {
      expect(controller.isEmailValid('userexample.com'), isFalse);
    });

    test('returns false for missing domain', () {
      expect(controller.isEmailValid('user@'), isFalse);
    });

    test('returns false for missing TLD', () {
      expect(controller.isEmailValid('user@example'), isFalse);
    });

    test('returns false for empty string', () {
      expect(controller.isEmailValid(''), isFalse);
    });

    test('returns false for whitespace only', () {
      expect(controller.isEmailValid('   '), isFalse);
    });
  });

  // ── isSubscriptionExpired ────────────────────────────────────────────────

  group('isSubscriptionExpired', () {
    test('returns true when endDateString is null', () {
      expect(controller.isSubscriptionExpired(null), isTrue);
    });

    test('returns true when endDateString is empty', () {
      expect(controller.isSubscriptionExpired(''), isTrue);
    });

    test('returns true when date is in the past', () {
      expect(controller.isSubscriptionExpired('2000-01-01T00:00:00.000Z'),
          isTrue);
    });

    test('returns false when date is in the future', () {
      expect(controller.isSubscriptionExpired('2099-12-31T00:00:00.000Z'),
          isFalse);
    });

    test('returns true for unparseable date string', () {
      expect(controller.isSubscriptionExpired('not-a-date'), isTrue);
    });
  });

  // ── hasActiveSubscription ────────────────────────────────────────────────

  group('hasActiveSubscription', () {
    test(
        'returns true when subscriptionId is null but the end date is in the '
        'future (backend-granted trials/promos have no store receipt)', () {
      expect(
          controller.hasActiveSubscription(null, '2099-12-31T00:00:00.000Z'),
          isTrue);
    });

    test('returns false when subscription is expired', () {
      expect(
          controller.hasActiveSubscription('sub_123', '2000-01-01T00:00:00Z'),
          isFalse);
    });

    test('returns true when subscriptionId present and not expired', () {
      expect(
          controller.hasActiveSubscription('sub_123', '2099-12-31T00:00:00Z'),
          isTrue);
    });

    test('returns false when endDate is null even with a subscriptionId', () {
      expect(controller.hasActiveSubscription('sub_123', null), isFalse);
    });
  });

  // ── isInfoCompleted ──────────────────────────────────────────────────────

  group('isInfoCompleted', () {
    test('returns false when both fields are empty', () {
      controller.emailController.text = '';
      controller.passwordController.text = '';
      expect(controller.isInfoCompleted(), isFalse);
    });

    test('returns false when only email filled', () {
      controller.emailController.text = 'a@b.com';
      controller.passwordController.text = '';
      expect(controller.isInfoCompleted(), isFalse);
    });

    test('returns false when only password filled', () {
      controller.emailController.text = '';
      controller.passwordController.text = 'secret';
      expect(controller.isInfoCompleted(), isFalse);
    });

    test('returns true when both fields are filled', () {
      controller.emailController.text = 'a@b.com';
      controller.passwordController.text = 'secret';
      expect(controller.isInfoCompleted(), isTrue);
    });
  });
}
