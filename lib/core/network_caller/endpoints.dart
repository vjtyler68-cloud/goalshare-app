class Urls {

  // base url
  // static const String baseUrl = 'https://ram-singh7-server.vercel.app/api/v1';
  static const String baseUrl = 'https://goal-share-backend.vercel.app/api/v1';

  // auth
  static const String login = '$baseUrl/auth/login'; // POST
  static const String signUp = '$baseUrl/users/register'; // POST
  static const String verifyOTP = '$baseUrl/auth/verify-email-with-otp'; // POST
  static const String verifyForgotPasswordOTP = '$baseUrl/auth/forget-password/verify-otp'; // POST
  static const String resetPassword = '$baseUrl/auth/reset-password'; // POST
  static const String changePassword = '$baseUrl/auth/change-password'; // POST

  static const String setupProfile = '$baseUrl/users/update-profile';
  static const String authentication = '$baseUrl/auth/verify-auth';
  static const String logout = '$baseUrl/auth/logout';
  static const String forgotPass = '$baseUrl/auth/forget-password';  // POST
  // static const String pickUpLocation = '$baseUrl/user/pickup-locations';
  // static String getCalendar(String date, String locationUuid) =>
  //     '$baseUrl/calendar?date=$date&pickup_location_uuid=$locationUuid';

  static const String userData = "$baseUrl/users";

}
