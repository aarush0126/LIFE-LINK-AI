class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({required this.message, this.statusCode, this.details});

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

class NetworkException extends ApiException {
  const NetworkException({
    super.message =
        'The API could not be reached. Check the connection and API URL.',
    super.statusCode,
  });
}

class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'The API request timed out. Please retry.',
    super.statusCode = 408,
  });
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'The session is invalid or expired. Please sign in again.',
    super.statusCode = 401,
  });
}

class ForbiddenException extends ApiException {
  const ForbiddenException({
    super.message = 'Access denied for this account.',
    super.statusCode = 403,
  });
}

class NotFoundException extends ApiException {
  const NotFoundException({
    super.message = 'The requested API resource was not found.',
    super.statusCode = 404,
  });
}

class ConflictException extends ApiException {
  const ConflictException({
    super.message = 'The request conflicts with an existing record.',
    super.statusCode = 409,
  });
}

class ValidationException extends ApiException {
  final Map<String, List<String>> errors;

  const ValidationException({
    super.message = 'One or more request fields are invalid.',
    super.statusCode = 422,
    this.errors = const {},
  });
}

class ServerException extends ApiException {
  const ServerException({
    super.message = 'The API encountered an internal error.',
    super.statusCode = 500,
  });
}

class UnknownException extends ApiException {
  const UnknownException({
    super.message = 'An unexpected API error occurred.',
    super.statusCode,
    super.details,
  });
}
