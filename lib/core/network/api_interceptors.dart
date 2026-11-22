import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';

class AuthInterceptor extends Interceptor {
  String? _authToken;

  void setToken(String? token) {
    _authToken = token;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_authToken != null && _authToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_authToken';
    }
    options.headers['X-Platform'] = 'LIFE-LINK-AI-WEB';
    options.headers['X-Client-Version'] = '1.0.0';
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('[DIO -> ${options.method}] ${options.uri}');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[DIO <- ${response.statusCode}] ${response.requestOptions.uri}',
      );
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[DIO ERROR: ${err.type}] ${err.message} (${err.requestOptions.uri})',
      );
    }
    return handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final customException = _mapDioException(err);
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: customException,
        message: customException.message,
      ),
    );
  }

  ApiException _mapDioException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final responseData = err.response?.data;
        String errorMessage = 'The API rejected the request.';
        if (responseData is Map<String, dynamic>) {
          final envelope = responseData['error'];
          if (envelope is Map<String, dynamic> && envelope['message'] != null) {
            errorMessage = envelope['message'].toString();
          } else if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          }
        }

        switch (statusCode) {
          case 400:
            return ApiException(message: errorMessage, statusCode: 400);
          case 401:
            return UnauthorizedException(message: errorMessage);
          case 403:
            return ForbiddenException(message: errorMessage);
          case 404:
            return NotFoundException(message: errorMessage);
          case 409:
            return ConflictException(message: errorMessage);
          case 422:
            return ValidationException(message: errorMessage);
          case 500:
          case 502:
          case 503:
            return ServerException(
              message: errorMessage,
              statusCode: statusCode,
            );
          default:
            return ApiException(message: errorMessage, statusCode: statusCode);
        }
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      case DioExceptionType.unknown:
      default:
        return UnknownException(
          message: err.message ?? 'Unknown network anomaly occurred.',
          details: err.error,
        );
    }
  }
}
