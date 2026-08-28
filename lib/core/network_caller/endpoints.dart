class Urls {
  // base url
  static const String baseUrl = 'https://goalshare-backend-production.up.railway.app/api/v1';

  // auth
  static const String login = '$baseUrl/auth/login'; // POST
  static const String signUp = '$baseUrl/auth/register'; // POST
  static const String verifyOTP = '$baseUrl/auth/verify-email-with-otp'; // POST
  static const String verifyForgotPasswordOTP =
      '$baseUrl/auth/forget-password/verify-otp'; // POST
  static const String resetPassword = '$baseUrl/auth/reset-password'; // POST
  static const String changePassword = '$baseUrl/auth/change-password'; // POST
  static const String authRenew =
      '$baseUrl/auth/renew'; // POST (auth) → fresh token; slides the session

  static const String setupProfile = '$baseUrl/users/update-profile';
  static const String authentication = '$baseUrl/auth/verify-auth';
  static const String logout = '$baseUrl/auth/logout';
  static const String forgotPass = '$baseUrl/auth/forget-password'; // POST

  // home screen
  static const String createHomeMYWHY = "$baseUrl/global/mywhy"; // POST
  static const String getHomeMYWHY = "$baseUrl/global/mywhy"; // GET
  static const String updateHomeMYWHY = "$baseUrl/global/mywhy"; // PATCH /:id
  static const String deleteHomeMYWHY = "$baseUrl/global/mywhy"; // DEL

  static const String createHomeMYAFFIRMATION =
      "$baseUrl/global/affirmation"; // POST
  static const String getHomeMYAFFIRMATION =
      "$baseUrl/global/affirmation/my-affirmation"; // GET
  static const String updateHomeMYAFFIRMATION =
      "$baseUrl/global/affirmation/my-affirmation"; // PATCH /:id
  static const String deleteHomeMYAFFIRMATION =
      "$baseUrl/global/affirmation/my-affirmation"; // DEL

  // user data
  static const String allUsers = "$baseUrl/user";
  static const String userPersonalData = "$baseUrl/user/me";
  static String userById(String id) => "$baseUrl/user/$id"; // GET one user
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
      "$baseUrl/subscription/buy-plan"; // POST (replaced /subscription/assign)

  // follower_list
  static const String getFollowersList = "$baseUrl/follow/followers";
  static const String getFollowingList = "$baseUrl/follow/following";
  static const String followUser = "$baseUrl/follow/follow-user"; // POST
  static const String unFollowUser = "$baseUrl/follow/unfollow-user";

  // current date
  static const String getCurrentDate =
      "$baseUrl/subscription/current-date"; // GET

  // friends (mutual, consent-based — distinct from follow)
  static const String friends = "$baseUrl/friends"; // GET list, DELETE /:userId
  static const String friendRequests =
      "$baseUrl/friends/requests"; // GET both lists, POST send, DELETE /:id cancel
  // + POST "$friendRequests/:id/accept" and "$friendRequests/:id/decline"

  // people search + username claim (used by Find People)
  static const String searchUsers = "$baseUrl/user/search-users"; // GET ?q=
  static const String setUsername = "$baseUrl/user/username"; // PUT

  // push notifications
  // Store/refresh this device's FCM token on the logged-in user so the backend
  // can target it. Friend-request/accept pushes are sent by the backend from
  // its existing handlers; chat pushes come via pushNotify below (chat lives in
  // Firestore, so the sender's app has to tell the server to notify the peer).
  static const String registerFcmToken = "$baseUrl/user/fcm-token"; // PUT { token, platform }
  static const String pushNotify = "$baseUrl/push/notify"; // POST { toUserId, title, body }

  // accountability buddies (matching pool + reputation live on the backend so
  // pairing + ratings cross between users; the app also works locally offline).
  static const String buddyProfile =
      "$baseUrl/accountability/profile"; // GET my profile, POST upsert
  static const String buddyOptIn =
      "$baseUrl/accountability/optin"; // POST { optedIn }
  static const String buddyMatch =
      "$baseUrl/accountability/match"; // GET current match
  static const String buddyCheckIn = "$baseUrl/accountability/checkin"; // POST
  static const String buddyExtend =
      "$baseUrl/accountability/extend"; // POST { value }
  static const String buddyRate =
      "$baseUrl/accountability/rate"; // POST { stars, comment }
  static const String buddyFriendMatch =
      "$baseUrl/accountability/friend-match"; // POST { buddyId, buddyName?, buddyAvatar? }
  static const String buddyCheckins =
      "$baseUrl/accountability/checkins"; // GET → { ourStreak, days }
  static const String buddyVerify =
      "$baseUrl/accountability/verify"; // POST { checkinId, verified }
  static const String buddyGoalsSync =
      "$baseUrl/accountability/goals"; // POST { goals: [...] }
  static const String buddyGoalsView =
      "$baseUrl/accountability/buddy-goals"; // GET → { goals: [...] }
  static const String buddyVoiceSend =
      "$baseUrl/accountability/voice"; // POST { audioUrl, durationMs }
  static const String buddyVoiceList =
      "$baseUrl/accountability/voice"; // GET → { messages: [...] }
  // Daily status thread — "how was your day / did you hit your goals".
  static const String buddyStatusPost =
      "$baseUrl/accountability/status"; // POST { text, hitGoals? }
  static const String buddyStatusList =
      "$baseUrl/accountability/status"; // GET → { updates: [...] }
  // Generic image upload (proof photos) — multipart 'file', returns { url }.
  static const String assetUpload = "$baseUrl/assets/upload"; // POST multipart

  // goal circles (3-5 person squads)
  static const String circleCreate =
      "$baseUrl/circles/create"; // POST { name, memberIds }
  static const String circleMine = "$baseUrl/circles/mine"; // GET
  static const String circleCheckin =
      "$baseUrl/circles/checkin"; // POST { proofUrl, note, date }
  static const String circleShield = "$baseUrl/circles/shield"; // POST { date? }
  static const String circleLeave = "$baseUrl/circles/leave"; // POST

  // buddy sharing — you grant specific friends a view of your nutrition/workout
  // summary. Default private; only granted viewers' data ever leaves the device.
  static const String sharingSettings =
      "$baseUrl/sharing/settings"; // POST { nutritionViewerIds, workoutViewerIds, nutritionSummary, workoutSummary }
  static String sharingSummary(String userId) =>
      "$baseUrl/sharing/summary/$userId"; // GET → sections you're granted

  // organizations — School / Sales / Gym orgs with an admin dashboard.
  static const String orgCreate =
      "$baseUrl/org/create"; // POST { name, orgType }
  static const String orgJoin = "$baseUrl/org/join"; // POST { inviteCode }
  static const String orgMine = "$baseUrl/org/mine"; // GET → my org + role
  static const String orgAll =
      "$baseUrl/org/all"; // GET → all my orgs + isOwner (owner = multi-org)
  static String orgRoster(String orgId) =>
      "$baseUrl/org/$orgId/roster"; // GET (admin) → members
  static const String orgSummary =
      "$baseUrl/org/summary"; // POST { summary } — member pushes scoped metrics
  static const String orgLeave = "$baseUrl/org/leave"; // POST
  static String orgMap(String orgId) =>
      "$baseUrl/org/$orgId/map"; // POST { mapUrl, mapLabel } (admin) — territory map
  static String orgBooking(String orgId) =>
      "$baseUrl/org/$orgId/booking"; // POST { bookingUrl, bookingLabel } (admin) — scheduler
  static String orgMemberRole(String orgId) =>
      "$baseUrl/org/$orgId/member-role"; // POST { userId, role } (admin) — promote/demote co-admin
  static String orgTaskHub(String orgId) =>
      "$baseUrl/org/$orgId/task-hub"; // POST { enabled } (admin) — enable/disable Task Hub

  // Org Task Hub — shared, assignable tasks + projects (members only).
  static String orgTasks(String orgId) =>
      "$baseUrl/org/$orgId/tasks"; // GET → { tasks, projects }
  static String orgCreateTask(String orgId) =>
      "$baseUrl/org/$orgId/task"; // POST { title, ... }
  static String orgUpdateTask(String taskId) =>
      "$baseUrl/org/task/$taskId"; // PATCH { any fields }
  static String orgDeleteTask(String taskId) =>
      "$baseUrl/org/task/$taskId"; // DELETE
  static String orgCreateProject(String orgId) =>
      "$baseUrl/org/$orgId/project"; // POST { name, color }
  static String orgDeleteProject(String projectId) =>
      "$baseUrl/org/project/$projectId"; // DELETE
  static String orgMeetings(String orgId) =>
      "$baseUrl/org/$orgId/meetings"; // GET → { meetings }
  static String orgCreateMeeting(String orgId) =>
      "$baseUrl/org/$orgId/meeting"; // POST { title, startAt, agenda, notes }
  static String orgUpdateMeeting(String meetingId) =>
      "$baseUrl/org/meeting/$meetingId"; // PATCH
  static String orgDeleteMeeting(String meetingId) =>
      "$baseUrl/org/meeting/$meetingId"; // DELETE

  // Solar Cowboys canvassing — door-to-door pins, scoped by org role.
  static String canvassPins(String orgId) =>
      "$baseUrl/canvass/$orgId/pins"; // GET (admin=all, rep=own)
  static String canvassCreatePin(String orgId) =>
      "$baseUrl/canvass/$orgId/pin"; // POST { lat,lng,status,address,... }
  static String canvassUpdatePin(String pinId) =>
      "$baseUrl/canvass/pin/$pinId"; // PATCH { status?, notes?, ... }
  static String canvassAssignPin(String pinId) =>
      "$baseUrl/canvass/pin/$pinId/assign"; // PATCH { repId, repName } (admin)
  static String canvassDeletePin(String pinId) =>
      "$baseUrl/canvass/pin/$pinId"; // DELETE
  // Territories (drawn areas assigned to reps).
  static String canvassTerritories(String orgId) =>
      "$baseUrl/canvass/$orgId/territories"; // GET
  static String canvassCreateTerritory(String orgId) =>
      "$baseUrl/canvass/$orgId/territory"; // POST { name,color,points,assignedRepIds,... }
  static String canvassUpdateTerritory(String tId) =>
      "$baseUrl/canvass/territory/$tId"; // PATCH (admin)
  static String canvassDeleteTerritory(String tId) =>
      "$baseUrl/canvass/territory/$tId"; // DELETE (admin)
  static String canvassEnrich(String orgId, String address) =>
      "$baseUrl/canvass/$orgId/enrich?address=${Uri.encodeQueryComponent(address)}"; // GET home + owner detail

  // Team HQ (org-private): announcements, feed, goals — members only.
  static String orgSpace(String orgId) => "$baseUrl/org/$orgId/space"; // GET
  static String orgPost(String orgId) =>
      "$baseUrl/org/$orgId/post"; // POST { kind, text }
  static String orgPostLike(String postId) =>
      "$baseUrl/org/post/$postId/like"; // POST
  static String orgPostDelete(String postId) =>
      "$baseUrl/org/post/$postId"; // DELETE
  static String orgGoal(String orgId) =>
      "$baseUrl/org/$orgId/goal"; // POST { title, target, metricKey }
  static String orgGoalBump(String goalId) =>
      "$baseUrl/org/goal/$goalId/bump"; // POST { delta }
  static String orgGoalDelete(String goalId) =>
      "$baseUrl/org/goal/$goalId"; // DELETE
}
