import 'package:dio/dio.dart';
import '../storage/storage_service.dart';
import 'api_endpoints.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio _dio;
  final StorageService _storageService;

  ApiClient({Dio? dio, StorageService? storageService})
      : _storageService = storageService ?? StorageService() {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.reject(_handleError(error));
        },
      ),
    );
  }

  Dio get client => _dio;

  Future<Response<dynamic>> _requestWithFallback({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
    } on DioException catch (error) {
      if (error.type != DioExceptionType.connectionError) {
        throw error.error as ApiException;
      }

      final currentBaseUrl = error.requestOptions.baseUrl;
      for (final candidate in ApiEndpoints.baseUrlCandidates) {
        if (candidate == currentBaseUrl) continue;

        try {
          return await _dio.request(
            _buildAbsoluteUrl(candidate, path),
            data: data,
            queryParameters: queryParameters,
            options: Options(
              method: method,
              extra: {
                ...error.requestOptions.extra,
                'fallbackBaseUrl': candidate,
              },
            ),
          );
        } on DioException catch (fallbackError) {
          if (fallbackError.type != DioExceptionType.connectionError) {
            throw fallbackError.error as ApiException;
          }
        }
      }

      throw error.error as ApiException;
    }
  }

  String _buildAbsoluteUrl(String baseUrl, String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    return '$baseUrl/$path';
  }

  DioException _handleError(DioException error) {
    String message = 'An unexpected error occurred. Please try again.';
    int? statusCode = error.response?.statusCode;
    dynamic errorsData;

    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      message = data['message'] ?? message;
      errorsData = data['errors'];
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your internet network.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Unable to reach the server. Please verify network connectivity.';
    }

    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: ApiException(
        message: message,
        statusCode: statusCode,
        errors: errorsData,
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _requestWithFallback(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _requestWithFallback(
      method: 'POST',
      path: path,
      data: data,
    );
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return _requestWithFallback(
      method: 'PATCH',
      path: path,
      data: data,
    );
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return _requestWithFallback(
      method: 'DELETE',
      path: path,
      data: data,
    );
  }
}
