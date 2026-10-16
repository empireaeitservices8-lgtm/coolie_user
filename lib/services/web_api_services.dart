import 'dart:async';
import 'package:cooli/models/app_error_model.dart';
import 'package:cooli/providers/_mixins.dart';
import 'package:cooli/utils/extensions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '_mixins_api.dart';

/// Global Pretty API Logger Interceptor for all network requests
class CooliApiLoggerInterceptor extends Interceptor {
  final Map<String, DateTime> _requestTimers = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestTimers[options.uri.toString()] = DateTime.now();

    debugPrint('╔════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ 🚀 [API REQUEST] ${options.method.toUpperCase()} ${options.uri}');
    debugPrint('║ 📋 Headers: ${options.headers}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('║ 🔍 Query Parameters: ${options.queryParameters}');
    }
    if (options.data != null) {
      debugPrint('║ 📦 Request Body: ${options.data}');
    }
    debugPrint('╚════════════════════════════════════════════════════════════════════════════════');

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = _requestTimers.remove(response.requestOptions.uri.toString());
    final duration = startTime != null
        ? '${DateTime.now().difference(startTime).inMilliseconds}ms'
        : 'N/A';

    debugPrint('╔════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ ✅ [API RESPONSE - ${response.statusCode} ${response.statusMessage ?? 'OK'}] ${response.requestOptions.method.toUpperCase()} ${response.requestOptions.uri}');
    debugPrint('║ ⏱️ Elapsed Time: $duration');
    debugPrint('║ 📥 Response Body: ${response.data}');
    debugPrint('╚════════════════════════════════════════════════════════════════════════════════');

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = _requestTimers.remove(err.requestOptions.uri.toString());
    final duration = startTime != null
        ? '${DateTime.now().difference(startTime).inMilliseconds}ms'
        : 'N/A';

    debugPrint('╔════════════════════════════════════════════════════════════════════════════════');
    debugPrint('║ ❌ [API ERROR - ${err.response?.statusCode ?? 'NO_STATUS'}] ${err.requestOptions.method.toUpperCase()} ${err.requestOptions.uri}');
    debugPrint('║ ⏱️ Elapsed Time: $duration');
    debugPrint('║ ⚠️ Error Type: ${err.type}');
    debugPrint('║ ⚠️ Error Message: ${err.message}');
    if (err.response?.data != null) {
      debugPrint('║ 📥 Error Response: ${err.response?.data}');
    }
    debugPrint('╚════════════════════════════════════════════════════════════════════════════════');

    super.onError(err, handler);
  }
}

class WebAPIService with WebAPIMixin, MixinAPIProvider {
  static final WebAPIService _instance = WebAPIService._initialise();
  factory WebAPIService() => _instance;

  WebAPIService._initialise()
      : _dio = Dio(BaseOptions(
            headers: {
              "accept": "application/json",
            })) {
    _dio.interceptors.add(CooliApiLoggerInterceptor());
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<bool> initTokenToHeader({bool initToken = true}) =>
      getTokenFromSharedPref().then((token) {
        if (token?.isEmpty ?? true) {
          return true;
        }
        if (_dio.options.headers.containsKey('Authorization')) {
          _dio.options.headers.remove('Authorization');
        }
        if (initToken) {
          _dio.options.headers
              .putIfAbsent('Authorization', () => 'Bearer $token');
          debugPrint('Authorization==>${token!}');
        }
        return true;
      });

  ///initialize language code in header
  Future<bool> initLangPrefToHeader() =>
      getLanguageSharedPref().then((languageCode) async {
        if (_dio.options.headers.containsKey('lang')) {
          _dio.options.headers.remove('lang');
        }
        _dio.options.headers.putIfAbsent('lang', () => languageCode ?? 'en');
        return true;
      });

  /// Initializes the tenant code in the header.
  Future<bool> initTenantPrefToHeader() =>
      getTenantCodeSharedPref().then((tenantCode) async {
        if (_dio.options.headers.containsKey('tenant')) {
          _dio.options.headers.remove('tenant');
        }
        _dio.options.headers.putIfAbsent('tenant', () => tenantCode ?? '0');
        return true;
      });

  /// Executes an API call and handles its response.
  Future<T> executeAPI<T>({
    required Future<Response<dynamic>> methodToCall,
    required FutureOr<T> Function(
      Map<dynamic, dynamic> value,
    ) converter,
    Function(AppError msg)? onError,
    Function(T value)? onSuccess,
    Function? functionToRefresh,
  }) {
    return methodToCall
        .then(validateResStatusData)
        .then(converter)
        .then((value) {
      onSuccess?.call(value);
      return value;
    }).catchError((ex) {
      onDioError(ex, 'setRegistrationVerifyOTP',
          apiFunction: functionToRefresh);
      throw ex;
    }, test: (ex) => ex is DioException).handleAPIException(
      handleAPIException: handleAPIException,
      onShowError: (msg) {
        onError?.call(msg);
      },
    );
  }
}
