import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/config/env_config.dart';
import '../models/damage_prediction.dart';

// provider mte3 damage prediction service
// yوفر instance men DamagePredictionService
final damagePredictionServiceProvider = Provider<DamagePredictionService>((
  ref,
) {
  return DamagePredictionService(Dio());
});

// exception custom lel damage prediction
class DamagePredictionException implements Exception {
  const DamagePredictionException(this.message);

  // message mte3 error
  final String message;

  @override
  String toString() => message;
}

// service yconnecti app m3a damage detection API
class DamagePredictionService {
  const DamagePredictionService(this._dio);

  // Dio client bech nبعثou HTTP request
  final Dio _dio;

  // teb3ath image lel API w trajja3 prediction result
  Future<DamagePrediction> predict(
    File imageFile, {
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleYear,
    String? region,
  }) async {
    // njibou API URL mel .env
    final endpointUrl = await EnvConfig.damagePredictUrl();

    // n7awlou URL l Uri
    final endpoint = Uri.tryParse(endpointUrl);

    // nverifiw eli URL valid w absolute
    if (endpoint == null || !endpoint.hasScheme || endpoint.host.isEmpty) {
      throw const DamagePredictionException(
        'DAMAGE_PREDICT_URL must be a valid absolute URL.',
      );
    }

    // njibou confidence threshold mel .env
    final confidence = await EnvConfig.damagePredictionConfidence();

    // n7adhrou multipart form data fih image + conf + optional vehicle fields
    final formData = FormData.fromMap({
      'images': await MultipartFile.fromFile(
        imageFile.path,
        filename: _fileName(imageFile.path),
      ),
      'conf': confidence.toString(),
      'include_base64': 'false',
      if (vehicleMake != null && vehicleMake.isNotEmpty) 'make': vehicleMake,
      if (vehicleModel != null && vehicleModel.isNotEmpty) 'model': vehicleModel,
      if (vehicleYear != null && vehicleYear.isNotEmpty) 'year': vehicleYear,
      if (region != null && region.isNotEmpty) 'region': region,
    });

    try {
      // nبعثou POST request lel damage API
      final response = await _dio.postUri<Object?>(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.json,
          headers: const {
            'Accept': 'application/json',

            // header bech ngrok ma يطلعch browser warning
            'ngrok-skip-browser-warning': 'true',
          },

          // timeout mte3 upload
          sendTimeout: const Duration(
            seconds: AppConstants.receiveTimeoutInSeconds,
          ),

          // timeout mte3 response
          receiveTimeout: const Duration(
            seconds: AppConstants.receiveTimeoutInSeconds,
          ),
        ),
      );

      // ncheckiw HTTP status code
      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw DamagePredictionException(
          'Damage API returned HTTP $statusCode.',
        );
      }

      // ndecodew response w n7awlouha l DamagePrediction model
      final data = _decodeResponse(response.data);
      return DamagePrediction.fromJson(data, endpoint: endpoint);
    } on DioException catch (error) {
      // errors mte3 Dio n7awlouhom l message understandable
      throw DamagePredictionException(_dioErrorMessage(error));
    } on DamagePredictionException {
      // ken exception mte3na, n3awdou nthrowiwha kif ma hiya
      rethrow;
    } catch (error) {
      // ay error o5ra
      throw DamagePredictionException('Could not analyze the photo. $error');
    }
  }

  // tdecode response: Map wala JSON String
  Map<String, dynamic> _decodeResponse(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);

    // ken response string, nعملou jsonDecode
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    // ken response format ghalet
    throw const DamagePredictionException(
      'Damage API returned an unexpected response.',
    );
  }

  // t7awel DioException l message واضح
  String _dioErrorMessage(DioException error) {
    final statusCode = error.response?.statusCode;

    // ken fama HTTP status code, nرجعou message m3a details mel server
    if (statusCode != null) {
      final details = _extractServerMessage(error.response?.data);
      return details == null
          ? 'Damage API request failed with HTTP $statusCode.'
          : 'Damage API request failed with HTTP $statusCode: $details';
    }

    // messages حسب type mte3 Dio error
    return switch (error.type) {
      DioExceptionType.connectionTimeout =>
        'Connection timed out while reaching the damage API.',
      DioExceptionType.sendTimeout =>
        'The photo upload timed out before it reached the damage API.',
      DioExceptionType.receiveTimeout =>
        'The damage API is still processing or did not respond in time.',
      DioExceptionType.connectionError =>
        'Could not connect to the damage API. Check the ngrok URL in .env.',
      DioExceptionType.badCertificate =>
        'The damage API certificate could not be trusted.',
      DioExceptionType.cancel => 'The damage analysis request was cancelled.',
      DioExceptionType.badResponse || DioExceptionType.unknown =>
        'Could not analyze the photo. ${error.message ?? 'Unknown error'}',
    };
  }

  // tخرج message/error/detail mel server response
  String? _extractServerMessage(Object? data) {
    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      return message?.toString();
    }
    if (data is String && data.trim().isNotEmpty) return data.trim();
    return null;
  }

  // tخرج file name men path
  String _fileName(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }
}
