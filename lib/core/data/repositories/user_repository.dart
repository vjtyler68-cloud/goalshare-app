import 'package:spanx/core/error/exceptions.dart';
import 'package:spanx/core/error/failures.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config_v2.dart';
import 'package:spanx/core/user_info/model/user_data_model.dart';
import 'package:spanx/core/utils/result.dart';

/// Abstract repository interface for user operations
abstract class UserRepository {
  Future<Result<UserDataModel>> getUserInfo();
  Future<Result<Map<String, int>>> getFollowersCount();
  Future<Result<bool>> updateProfile(Map<String, dynamic> data);
}

/// Implementation of UserRepository
class UserRepositoryImpl implements UserRepository {
  final NetworkConfigV2 _networkConfig;

  UserRepositoryImpl({NetworkConfigV2? networkConfig})
      : _networkConfig = networkConfig ?? NetworkConfigV2.instance;

  @override
  Future<Result<UserDataModel>> getUserInfo() async {
    try {
      final response = await _networkConfig.apiRequest(
        method: RequestMethod.GET,
        url: Urls.userPersonalData,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final userData = UserDataModel.fromJson(response['data'] as Map<String, dynamic>);
        return Result.success(userData);
      } else {
        return Result.failure(
          response['message']?.toString() ?? 'Failed to fetch user info',
        );
      }
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(message: e.message).userMessage);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message).userMessage);
    } catch (e) {
      return Result.failure(
        UnexpectedFailure(message: e.toString()).userMessage,
      );
    }
  }

  @override
  Future<Result<Map<String, int>>> getFollowersCount() async {
    try {
      final response = await _networkConfig.apiRequest(
        method: RequestMethod.GET,
        url: Urls.userFollowersCount,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        return Result.success({
          'followersCount': data['followersCount'] as int? ?? 0,
          'followingCount': data['followingCount'] as int? ?? 0,
        });
      } else {
        return Result.failure(
          response['message'] ?? 'Failed to fetch followers count',
        );
      }
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(message: e.message).userMessage);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message).userMessage);
    } catch (e) {
      return Result.failure(
        UnexpectedFailure(message: e.toString()).userMessage,
      );
    }
  }

  @override
  Future<Result<bool>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _networkConfig.apiRequest(
        method: RequestMethod.POST,
        url: Urls.userUpdateProfile,
        body: data,
        requiresAuth: true,
      );

      if (response['success'] == true) {
        return Result.success(true);
      } else {
        return Result.failure(
          response['message'] ?? 'Failed to update profile',
        );
      }
    } on NetworkException catch (e) {
      return Result.failure(NetworkFailure(message: e.message).userMessage);
    } on ServerException catch (e) {
      return Result.failure(ServerFailure(message: e.message).userMessage);
    } catch (e) {
      return Result.failure(
        UnexpectedFailure(message: e.toString()).userMessage,
      );
    }
  }
}
