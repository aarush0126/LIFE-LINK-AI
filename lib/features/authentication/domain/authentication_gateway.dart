import '../../../shared/models/user_model.dart';

class AuthenticationCredentials {
  final String email;
  final String password;

  const AuthenticationCredentials({
    required this.email,
    required this.password,
  });
}

abstract interface class AuthenticationGateway {
  Future<UserModel> signIn(AuthenticationCredentials credentials);

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset(String email);

  Future<UserModel> verifyEmail(String verificationCode);

  Future<UserModel> updateProfile({
    required UserRole role,
    required String hospitalName,
    required String department,
    required String hprId,
  });

  Future<void> signOut();
}
