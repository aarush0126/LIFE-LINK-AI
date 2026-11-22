import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_interceptors.dart';
import '../../../shared/models/user_model.dart';
import '../application/auth_controller.dart';

class AuthApiSession {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthApiSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
}

class AuthApiService {
  final ApiClient _client;
  final AuthInterceptor _authInterceptor;
  String? _refreshToken;

  AuthApiService(this._client, this._authInterceptor);

  Future<AuthApiSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.token,
      data: {'username': email.trim(), 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return _acceptSession(response.data);
  }

  Future<AuthApiSession> refresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      throw StateError('There is no production session to refresh.');
    }
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.refreshToken,
      data: {'refresh_token': refreshToken},
    );
    return _acceptSession(response.data);
  }

  Future<void> logout() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) return;
    try {
      await _client.post<void>(
        ApiEndpoints.logout,
        data: {'refresh_token': refreshToken},
      );
    } finally {
      _refreshToken = null;
      _authInterceptor.setToken(null);
    }
  }

  AuthApiSession _acceptSession(Map<String, dynamic>? payload) {
    if (payload == null) {
      throw const FormatException(
        'The API returned an empty sign-in response.',
      );
    }
    final userData = payload['user'];
    if (userData is! Map<String, dynamic>) {
      throw const FormatException(
        'The API response did not contain a user profile.',
      );
    }
    final accessToken = payload['access_token'];
    final refreshToken = payload['refresh_token'];
    if (accessToken is! String || refreshToken is! String) {
      throw const FormatException(
        'The API response did not contain session tokens.',
      );
    }

    final user = _userFromApi(userData);
    _refreshToken = refreshToken;
    _authInterceptor.setToken(accessToken);
    return AuthApiSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  UserModel _userFromApi(Map<String, dynamic> data) {
    final roleName = data['role'];
    final role = UserRole.values.where(
      (candidate) => candidate.name == roleName,
    );
    if (role.isEmpty) {
      throw FormatException('The API returned an unsupported role: $roleName');
    }
    final institutionId = data['institution_id'];
    final userId = data['id'];
    final fullName = data['full_name'];
    final email = data['email'];
    final institutionName = data['institution_name'];
    final department = data['department'];
    if (userId is! int ||
        institutionId is! int ||
        fullName is! String ||
        email is! String ||
        institutionName is! String ||
        department is! String) {
      throw const FormatException('The API returned an invalid user profile.');
    }
    return UserModel(
      id: userId.toString(),
      fullName: fullName,
      email: email,
      hprId: '',
      role: role.first,
      affiliatedHospitalId: institutionId.toString(),
      affiliatedHospitalName: institutionName,
      department: department,
      isVerified: data['is_verified'] == true,
      isProfileComplete: data['is_active'] == true,
      lastLoginAt: DateTime.now(),
    );
  }
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(
    ref.watch(apiClientProvider),
    ref.watch(authInterceptorProvider),
  );
});

Future<String?> terminateApiSession({
  required AuthApiService service,
  required AuthController controller,
}) async {
  String? warning;
  try {
    await service.logout();
  } on DioException {
    warning =
        'Local session ended; server-side revocation could not be confirmed.';
  } finally {
    await controller.signOut();
  }
  return warning;
}
