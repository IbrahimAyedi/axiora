import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_constants.dart';
import 'api_endpoints.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
            // timeout bech app ma testannech barcha ki connection ta9ef

      connectTimeout: const Duration(seconds: AppConstants.connectTimeoutInSeconds),
            // timeout bech app ma testannech barcha response

      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeoutInSeconds),
      headers: const {
              // headers default mte3 requests

        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
});
