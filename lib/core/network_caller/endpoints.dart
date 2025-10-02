class Urls {

  // base url
  // static const String baseUrl = 'https://ram-singh7-server.vercel.app/api/v1';
  static const String baseUrl = 'https://goal-share-backend.vercel.app/api/v1';

  // auth
  static const String login = '$baseUrl/auth/login'; // POST
  static const String signUp = '$baseUrl/auth/register'; // POST
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

  // user data
  static const String allUsers = "$baseUrl/users";
  static const String userPersonalData = "$baseUrl/user/me";
  static const String userFollowersCount = "$baseUrl/follow/my-counts";

  // motivations
  static const String motivationalNudges = "$baseUrl/motivation";  // GET
  static const String createMotivationalNudges = "$baseUrl/motivation";  // POST
  static const String deleteMotivationalNudges = "$baseUrl/motivation";  // DELETE

  // mission
  static const String createMission = "$baseUrl/goals";  // POST
  static const String getMission = "$baseUrl/goals/my-goals";  // GET
  static const String deleteMission = "$baseUrl/goals";  // POST
  static const String missionDetails = "$baseUrl/goals";  // GET
  static const String createMYWHY = "$baseUrl/goals";  // POST
  static const String createAffirmation = "$baseUrl/goals";  // POST

  // client details
  static const String customerDetails = "$baseUrl/goals/clients";  // GET
  static const String createClient = "$baseUrl/goals";  // POST
  static const String updateClientStatus = "$baseUrl/goals/clients";  // PATCH
  static const String updateClientTimeSpent = "$baseUrl/goals/clients";  // PATCH
  static const String updateMissionBreakTimeSpent = "$baseUrl/goals";  // PATCH

  // vision board
  static const String createVisionBoard = "$baseUrl/vision";  // POST
  static const String getVisionBoard = "$baseUrl/vision/my-vision";  // GET

// follow
  static const String getSuggestedPeople = "$baseUrl/follow/suggested-people";  // GET






}
