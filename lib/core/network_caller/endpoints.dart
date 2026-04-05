class Urls {
  // base url
  static const String baseUrl = 'https://api.goalsharewin.com/api/v1';

  // auth
  static const String login = '$baseUrl/auth/login'; // POST
  static const String signUp = '$baseUrl/auth/register'; // POST
  static const String verifyOTP = '$baseUrl/auth/verify-email-with-otp'; // POST
  static const String verifyForgotPasswordOTP =
      '$baseUrl/auth/forget-password/verify-otp'; // POST
  static const String resetPassword = '$baseUrl/auth/reset-password'; // POST
  static const String changePassword = '$baseUrl/auth/change-password'; // POST

  static const String setupProfile = '$baseUrl/users/update-profile';
  static const String authentication = '$baseUrl/auth/verify-auth';
  static const String logout = '$baseUrl/auth/logout';
  static const String forgotPass = '$baseUrl/auth/forget-password'; // POST
  // static const String pickUpLocation = '$baseUrl/user/pickup-locations';
  // static String getCalendar(String date, String locationUuid) =>
  //     '$baseUrl/calendar?date=$date&pickup_location_uuid=$locationUuid';

  // home screen
  static const String createHomeMYWHY = "$baseUrl/global/mywhy"; // POST
  static const String getHomeMYWHY = "$baseUrl/global/mywhy"; // GET
  static const String deleteHomeMYWHY = "$baseUrl/global/mywhy"; // DEL

  static const String createHomeMYAFFIRMATION =
      "$baseUrl/global/my-affirmation"; // POST
  static const String getHomeMYAFFIRMATION =
      "$baseUrl/global/affirmation/my-affirmation"; // GET
  static const String deleteHomeMYAFFIRMATION =
      "$baseUrl/global/affirmation/my-affirmation"; // DEL

  // user data
  static const String allUsers = "$baseUrl/user";
  static const String userPersonalData = "$baseUrl/user/me";
  static const String userFollowersCount = "$baseUrl/follow/my-counts";
  static const String userUploadPhoto = "$baseUrl/user/update-profile-image";
  static const String userUpdateProfile = "$baseUrl/user/update-profile";
  static const String userSoftDelete = "$baseUrl/user/soft-delete";

  // motivations
  static const String motivationalNudges =
      "$baseUrl/motivation/my-motivation"; // GET
  static const String createMotivationalNudges = "$baseUrl/motivation"; // POST
  static const String deleteMotivationalNudges =
      "$baseUrl/motivation"; // DELETE

  // mission
  static const String createMission = "$baseUrl/goals"; // POST
  static const String getMission = "$baseUrl/goals/my-goals"; // GET
  static const String deleteMission = "$baseUrl/goals"; // POST
  static const String missionDetails = "$baseUrl/goals"; // GET
  static const String createMYWHY = "$baseUrl/goals"; // POST
  static const String createAffirmation = "$baseUrl/goals"; // POST

  // client details
  static const String customerDetails = "$baseUrl/goals/clients"; // GET
  static const String createClient = "$baseUrl/goals"; // POST
  static const String updateClientStatus = "$baseUrl/goals/clients"; // PATCH
  static const String updateClientTimeSpent = "$baseUrl/goals/clients"; // PATCH
  static const String updateMissionBreakTimeSpent = "$baseUrl/goals"; // PATCH

  // vision board
  static const String createVisionBoard = "$baseUrl/vision"; // POST
  static const String getVisionBoard = "$baseUrl/vision/my-vision"; // GET
  static String deleteVision(String id) => "$baseUrl/vision/$id"; // GET

  // follow
  static const String getSuggestedPeople =
      "$baseUrl/follow/suggested-people"; // GET

  //my budget ---
  static const String getMyBudget = "$baseUrl/budget/my"; // GET
  static const String addBudget = "$baseUrl/budget/target"; // POST
  static String addIncome({required String budgetId}) =>
      "$baseUrl/budget/$budgetId/income"; // POST
  static String addExpense({required String budgetId}) =>
      "$baseUrl/budget/$budgetId/expense"; // POST

  // analytics
  static const String getUserReportAnalytics = "$baseUrl/meta/user"; // GET

  // subscription
  static const String getUserSubscription =
      "$baseUrl/subscription/my-subscription"; // GET
  static const String getSubscriptionPackages = "$baseUrl/subscription"; // GET
  static const String createSubscriptionPackages =
      "$baseUrl/subscription/assign"; // POST

  // follower_list
  static const String getFollowersList = "$baseUrl/follow/followers";
  static const String getFollowingList = "$baseUrl/follow/following";
  static const String followUser = "$baseUrl/follow/follow-user"; // POST
  static const String unFollowUser = "$baseUrl/follow/unfollow-user";

  // current date
  static const String getCurrentDate =
      "$baseUrl/subscription/current-date"; // GET
}
