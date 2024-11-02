import 'dart:convert';
import 'package:dio/src/response.dart' as resp;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

class FitBitAuthService {
//authorizing
  static Future<FitbitCredentials> authorize(
      {required String clientID,
      required String clientSecret,
      required String redirectUri,
      required String callbackUrlScheme,
      List<FitbitAuthScope> scopeList = const [
        FitbitAuthScope.ACTIVITY,
        FitbitAuthScope.CARDIO_FITNESS,
        FitbitAuthScope.HEART_RATE,
        FitbitAuthScope.LOCATION,
        FitbitAuthScope.NUTRITION,
        FitbitAuthScope.OXYGEN_SATURATION,
        FitbitAuthScope.PROFILE,
        FitbitAuthScope.RESPIRATORY_RATE,
        FitbitAuthScope.SETTINGS,
        FitbitAuthScope.SLEEP,
        FitbitAuthScope.SOCIAL,
        FitbitAuthScope.TEMPERATURE
      ],
      int expiresIn = 28800}) async {
    resp.Response response;

    final fitbitAuthorizeFormUrl = FitbitAuthAPIURL.authorizeForm(
        redirectUri: redirectUri,
        clientID: clientID,
        scopeList: scopeList,
        expiresIn: expiresIn);

    try {
      final result = await FlutterWebAuth.authenticate(
          url: fitbitAuthorizeFormUrl.url,
          callbackUrlScheme: callbackUrlScheme);
      final code = Uri.parse(result).queryParameters['code'];

      final fitbitAuthorizeUrl = FitbitAuthAPIURL.authorize(
          redirectUri: redirectUri,
          code: code,
          clientID: clientID,
          clientSecret: clientSecret);

      response = await dio.post(
        fitbitAuthorizeUrl.url,
        data: fitbitAuthorizeUrl.data,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: fitbitAuthorizeUrl.authorizationHeader!,
        ),
      );

      final accessToken = response.data['access_token'] as String;
      // final refreshToken = response.data['refresh_token'] as String;
      final userID = response.data['user_id'] as String;
      return FitbitCredentials(accessToken: accessToken, userID: userID);
    } catch (e) {
      debugPrint(e.toString());
      return FitbitCredentials(accessToken: '', userID: '');
    } // catch
  }
}

Options dioOptions(String accessToken) {
  return Options(
    contentType: 'application/json',
    headers: {
      'Authorization': 'Bearer $accessToken',
    },
  );
}

enum FitbitAuthScope {
  ACTIVITY,
  CARDIO_FITNESS,
  HEART_RATE,
  LOCATION,
  NUTRITION,
  PROFILE,
  SETTINGS,
  SLEEP,
  SOCIAL,
  WEIGHT,
  OXYGEN_SATURATION,
  RESPIRATORY_RATE,
  TEMPERATURE
}

Dio dio = Dio();

class FitbitCredentials {
  final String accessToken;
  final String userID;

  FitbitCredentials({required this.accessToken, required this.userID});
}

class FitbitAuthAPIURL {
  final String url;
  final String? fitbitCredentials;
  final Map<String, dynamic>? data;
  final Map<String, String>? authorizationHeader;

  FitbitAuthAPIURL({
    required this.url,
    this.fitbitCredentials,
    this.data,
    this.authorizationHeader,
  });

  // Method to generate authorization URL
  factory FitbitAuthAPIURL.authorizeForm({
    required String redirectUri,
    required List<FitbitAuthScope> scopeList,
    required int expiresIn,
    String? clientID,
  }) {
    return FitbitAuthAPIURL(
      url:
          'https://www.fitbit.com/oauth2/authorize?client_id=$clientID&response_type=code&scope=activity%20heartrate%20location%20nutrition%20oxygen_saturation%20profile%20respiratory_rate%20settings%20sleep%20social%20temperature%20weight',
      fitbitCredentials: null,
      data: null,
      authorizationHeader: null,
    );
  }

  // Helper function to convert the scope list to a string
  static String _getScope(List<FitbitAuthScope> scopeList) {
    return scopeList
        .map((scope) => scope.toString().split('.').last)
        .join('%20');
  }

  factory FitbitAuthAPIURL.authorize(
      {required String redirectUri,
      String? code,
      String? clientID,
      String? clientSecret}) {
    // Encode the redirectUri
    final String encodedRedirectUri = Uri.encodeFull(redirectUri);

    // Generate the authorization header∂
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    final String authorizationHeader =
        stringToBase64.encode("$clientID:$clientSecret");

    return FitbitAuthAPIURL(
      fitbitCredentials: null,
      url: '${_getBaseURL()}/token',
      data: {
        'client_id': clientID,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': encodedRedirectUri,
      },
      authorizationHeader: {
        'Authorization': 'Basic $authorizationHeader',
      },
    );
  }
  static String _getBaseURL() {
    return 'https://api.fitbit.com/oauth2';
  }
}
