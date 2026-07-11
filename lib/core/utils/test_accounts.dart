/// Test/reviewer accounts that behave like ADMIN for routing purposes:
/// they go straight into the app without an active subscription.
///
/// Needed while the backend's email delivery is down (no OTP verification or
/// password reset possible) so the team always has working logins to test
/// with. Any Gmail plus-alias of the base account (goalshare25+something)
/// also counts, so fresh test accounts can be created against the same inbox.
library;

const String _testAccountLocalPart = 'goalshare25';
const String _testAccountDomain = '@gmail.com';

bool isTestAccount(String? email) {
  final e = (email ?? '').trim().toLowerCase();
  if (!e.endsWith(_testAccountDomain)) return false;
  final local = e.substring(0, e.length - _testAccountDomain.length);
  return local == _testAccountLocalPart ||
      local.startsWith('$_testAccountLocalPart+');
}
