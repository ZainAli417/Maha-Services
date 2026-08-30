import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../main.dart';

/// Thrown when the backend refuses a request for a reason the caller can act on.
class BackendException implements Exception {
  const BackendException(this.statusCode, this.error, this.message);

  final int statusCode;
  final String error;
  final String message;

  /// The signed-in account is not allowed to do this.
  bool get isForbidden => statusCode == 403;

  /// The invitation window closed.
  bool get isGone => statusCode == 410;

  /// The server's state disagrees with the client's — usually because the
  /// assessment moved on in another tab.
  bool get isConflict => statusCode == 409;

  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'BackendException($statusCode): $message';
}

/// Every call to the Node backend, carrying the caller's Firebase identity.
///
/// The backend authenticates each request against Firebase and checks the
/// caller's role, so a request without a token is refused. Routing every call
/// through here is what stops a screen from quietly forgetting the token and
/// only failing in production.
class BackendApi {
  BackendApi._();

  static final http.Client _client = http.Client();

  /// The signed-in user's ID token.
  ///
  /// Firebase refreshes it automatically about every hour; asking for it per
  /// request returns the cached one until it is close to expiry, so this is
  /// cheap enough to call every time and always current.
  static Future<String> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const BackendException(401, 'Unauthorized', 'You are not signed in.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const BackendException(401, 'Unauthorized', 'Could not read your session.');
    }
    return token;
  }

  /// Headers for a JSON request. Use [multipart] for a file upload, where the
  /// content type carries a boundary that http builds itself.
  static Future<Map<String, String>> headers({bool multipart = false}) async {
    return {
      'Authorization': 'Bearer ${await _idToken()}',
      if (!multipart) 'Content-Type': 'application/json',
    };
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await _client
        .post(
          Uri.parse('${Env.backendUrl}$path'),
          headers: await headers(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _decode(path, response);
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await _client
        .get(Uri.parse('${Env.backendUrl}$path'), headers: await headers())
        .timeout(timeout);
    return _decode(path, response);
  }

  static Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final response = await _client
        .patch(
          Uri.parse('${Env.backendUrl}$path'),
          headers: await headers(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _decode(path, response);
  }

  /// Fire-and-forget: used for the integrity signals the assessment screen
  /// reports. A dropped one is not worth interrupting the candidate over.
  static Future<void> postQuietly(String path, Map<String, dynamic> body) async {
    try {
      await post(path, body, timeout: const Duration(seconds: 8));
    } catch (e) {
      debugPrint('backend $path (quiet) failed: $e');
    }
  }

  static Map<String, dynamic> _decode(String path, http.Response response) {
    Map<String, dynamic> body;
    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      body = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    debugPrint('⚠️ $path → ${response.statusCode}: ${response.body}');
    throw BackendException(
      response.statusCode,
      (body['error'] ?? 'Request failed').toString(),
      (body['message'] ?? 'Something went wrong. Please try again.').toString(),
    );
  }
}
