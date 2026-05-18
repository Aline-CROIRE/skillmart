import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../config/api_config.dart';
import '../models/project_model.dart';
import '../models/notification_model.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>?> login(String email, String password, {String? fcmToken}) async {
    try {
      final body = {'email': email, 'password': password};
      if (fcmToken != null) body['fcmToken'] = fcmToken;
      final res = await http.post(Uri.parse('$baseUrl/auth/login'), headers: _headers(null), body: jsonEncode(body));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> register(String name, String email, String password, String role, {String? fcmToken, String? phoneNumber}) async {
    try {
      final body = {'name': name, 'email': email, 'password': password, 'role': role};
      if (fcmToken != null) body['fcmToken'] = fcmToken;
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) body['phoneNumber'] = phoneNumber.trim();
      final res = await http.post(Uri.parse('$baseUrl/auth/register'), headers: _headers(null), body: jsonEncode(body));
      return res.statusCode == 201 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/auth/profile'), headers: _headers(token));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>> updateProfileInfo(Map<String, dynamic> data, String token) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/auth/profile/info'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    final resData = jsonDecode(res.body);
    if (res.statusCode == 200) return resData;
    throw resData['message'] ?? 'Failed to update profile';
  }
  Map<String, dynamic> _parseJsonBody(String body) {
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }

  String _errorMessage(Map<String, dynamic> data, String fallback) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) {
      return '${data['message'] ?? fallback}\n$detail';
    }
    return data['message']?.toString() ?? fallback;
  }

  Future<String> sendEmailVerification(String token) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/verify-email/send'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 35));

    final data = _parseJsonBody(res.body);
    if (res.statusCode == 200) {
      return data['message']?.toString() ?? 'Verification code sent';
    }
    throw _errorMessage(data, 'Failed to send verification code (${res.statusCode})');
  }

  Future<Map<String, dynamic>> verifyEmail(String token, String code) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/verify-email'),
          headers: _headers(token),
          body: jsonEncode({'code': code}),
        )
        .timeout(const Duration(seconds: 30));

    final data = _parseJsonBody(res.body);
    if (res.statusCode == 200) return data;
    throw _errorMessage(data, 'Verification failed');
  }

  Future<Map<String, dynamic>?> addFunds(int amount, String token) async {
    try {
      final res = await http.patch(Uri.parse('$baseUrl/auth/deposit'), headers: _headers(token), body: jsonEncode({'amount': amount}));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) return data;
      throw data['message'] ?? "Deposit failed";
    } catch (e) { rethrow; }
  }

  Future<String?> uploadFile(PlatformFile file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/projects/upload'));
      if (kIsWeb && file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name, contentType: MediaType('application', 'octet-stream')));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200 ? jsonDecode(response.body)['fileUrl'] : null;
    } catch (e) { return null; }
  }

  Future<bool> submitProject(Map<String, dynamic> data, String token) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/projects'), headers: _headers(token), body: jsonEncode(data));
      return res.statusCode == 201;
    } catch (e) { return false; }
  }

  Future<bool> updateProject(String id, Map<String, dynamic> data, String token) async {
    try {
      final res = await http.patch(Uri.parse('$baseUrl/projects/$id'), headers: _headers(token), body: jsonEncode(data));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<List<Project>> getAllProjects({String? userId}) async {
    try {
      final url = userId != null ? '$baseUrl/projects?userId=$userId' : '$baseUrl/projects';
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        return data.map((item) => Project.fromJson(item)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<Project>> getSellerProjects(String userId, String token) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/projects/seller/$userId'), headers: _headers(token));
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        return data.map((item) => Project.fromJson(item)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<Project>> getUserLibrary(String token) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/market/my-library'), headers: _headers(token));
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        return data.map((item) => Project.fromJson(item)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<bool> purchaseProject(String projectId, String token) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/market/purchase'), headers: _headers(token), body: jsonEncode({'projectId': projectId}));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<List<dynamic>> getTransactionHistory(String token) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/market/history'), headers: _headers(token));
      return res.statusCode == 200 ? jsonDecode(res.body) : [];
    } catch (e) { return []; }
  }

  Future<List<Project>> getAnalystQueue(String token) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/analyst/queue'), headers: _headers(token));
      return res.statusCode == 200 ? (jsonDecode(res.body) as List).map((e) => Project.fromJson(e)).toList() : [];
    } catch (e) { return []; }
  }

  Future<List<Project>> getAdminQueue(String token) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/admin/queue'), headers: _headers(token));
      return res.statusCode == 200 ? (jsonDecode(res.body) as List).map((e) => Project.fromJson(e)).toList() : [];
    } catch (e) { return []; }
  }

  Future<bool> submitAdminDecision(String id, String status, String token) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/decision/$id'),
        headers: _headers(token),
        body: jsonEncode({'status': status}),
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> submitAnalystDecision(String id, String status, String token, {String reviewNote = "", int? price, String? analyticsPath}) async {
    try {
      var request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/analyst/review/$id'));
      request.headers.addAll(_headers(token));
      
      request.fields['status'] = status;
      request.fields['reviewNote'] = reviewNote;
      if (price != null) request.fields['price'] = price.toString();
      
      if (analyticsPath != null) {
        request.files.add(await http.MultipartFile.fromPath('analyticsFile', analyticsPath));
      }

      var streamedResponse = await request.send();
      return streamedResponse.statusCode == 200;
    } catch (e) { return false; }
  }

  // Admin: Analytics Requests
  Future<List<dynamic>> getAnalyticsRequests(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/analytics-requests'), headers: _headers(token));
    return res.statusCode == 200 ? jsonDecode(res.body) : [];
  }

  Future<bool> updateAnalyticsRequestStatus(String projectId, String requestId, String status, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/analytics-decision'),
      headers: _headers(token),
      body: jsonEncode({'projectId': projectId, 'requestId': requestId, 'status': status}),
    );
    return res.statusCode == 200;
  }

  // User: Request Access
  Future<Map<String, dynamic>> requestAnalyticsAccess(String projectId, String token) async {
    final res = await http.post(Uri.parse('$baseUrl/projects/$projectId/request-analytics'), headers: _headers(token));
    return jsonDecode(res.body);
  }

  Future<bool> claimProject(String id, String token) async {
    try {
      final res = await http.patch(Uri.parse('$baseUrl/analyst/claim/$id'), headers: _headers(token));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<List<Project>> getAnalystAssignments(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/analyst/assignments'), headers: _headers(token));
    if (res.statusCode == 200) {
      List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => Project.fromJson(json)).toList();
    }
    throw 'Failed to load assignments';
  }

  Future<List<Project>> getAnalystHistory(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/analyst/history'), headers: _headers(token));
    if (res.statusCode == 200) {
      List<dynamic> data = jsonDecode(res.body);
      return data.map((json) => Project.fromJson(json)).toList();
    }
    throw 'Failed to load history';
  }

  Future<Map<String, dynamic>?> bookmarkProject(String id, String token) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/projects/bookmark/$id'), headers: _headers(token));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }

  Future<bool> logout(String token) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers(token),
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<Map<String, dynamic>?> updateAvatar(PlatformFile file, String token) async {
    try {
      var request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/auth/profile'));
      request.headers.addAll(_headers(token));
      
      if (kIsWeb && file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('avatar', file.bytes!, filename: file.name, contentType: MediaType('image', 'jpeg')));
      } else {
        request.files.add(await http.MultipartFile.fromPath('avatar', file.path!));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers(token),
      body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data;
    throw data['message'] ?? 'Failed to change password';
  }

  Future<String> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _headers(null),
      body: jsonEncode({'email': email}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data['message'] ?? 'Recovery code sent';
    throw data['message'] ?? 'Failed to request reset';
  }

  Future<String> resetPassword(String email, String code, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data['message'] ?? 'Password reset successfully';
    throw data['message'] ?? 'Failed to reset password';
  }

  Future<Map<String, dynamic>> manageAnalyst(String email, String action, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/manage-analyst'),
      headers: _headers(token),
      body: jsonEncode({'email': email, 'action': action}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data;
    throw data['message'] ?? 'Failed to update user role';
  }

  Future<List<dynamic>> getAnalysts(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/analysts'), headers: _headers(token));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw 'Error ${res.statusCode}: Failed to load analysts';
  }

  Future<Map<String, dynamic>> createAnalyst(String name, String email, String password, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/create-analyst'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 201) return data;
    throw data['message'] ?? 'Failed to create analyst';
  }

  Future<Map<String, dynamic>> togglePauseAnalyst(String userId, int? days, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/pause-analyst'),
      headers: _headers(token),
      body: jsonEncode({'userId': userId, 'days': days}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data;
    throw data['message'] ?? 'Failed to update suspension status';
  }

  Future<Map<String, dynamic>> confirmAnalystProfile(String userId, String token) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/confirm-profile'),
      headers: _headers(token),
      body: jsonEncode({'userId': userId}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return data;
    throw data['message'] ?? 'Failed to confirm analyst profile';
  }

  Future<bool> unconfirmAnalystProfile(String userId, String token) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/unconfirm-profile'),
        headers: _headers(token),
        body: jsonEncode({'userId': userId}),
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> updateAnalyst({
    required String token,
    required String userId,
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/admin/update-analyst'),
        headers: _headers(token),
        body: jsonEncode({
          'userId': userId,
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        }),
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<Map<String, dynamic>> uploadNationalId(PlatformFile file, String token) async {
    final uri = Uri.parse('$baseUrl/auth/profile/national-id');
    final request = http.MultipartRequest('PATCH', uri);
    request.headers.addAll(_headers(token));
    request.files.add(await http.MultipartFile.fromPath('nationalId', file.path!));
    final streamRes = await request.send();
    final res = await http.Response.fromStream(streamRes);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw jsonDecode(res.body)['message'] ?? 'Failed to upload ID';
  }

  Future<Map<String, dynamic>> uploadVerificationSelfie(PlatformFile file, String token) async {
    final uri = Uri.parse('$baseUrl/auth/profile/verification-selfie');
    final request = http.MultipartRequest('PATCH', uri);
    request.headers.addAll(_headers(token));
    request.files.add(await http.MultipartFile.fromPath('selfie', file.path!));
    final streamRes = await request.send();
    final res = await http.Response.fromStream(streamRes);
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw jsonDecode(res.body)['message'] ?? 'Failed to upload selfie';
  }

  // Notifications
  Future<List<AppNotification>> getNotifications(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers(token));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((n) => AppNotification.fromJson(n)).toList();
    }
    return [];
  }

  Future<void> markNotificationAsRead(String id, String token) async {
    await http.patch(Uri.parse('$baseUrl/notifications/$id/read'), headers: _headers(token));
  }

  Future<void> markAllNotificationsAsRead(String token) async {
    await http.patch(Uri.parse('$baseUrl/notifications/read-all'), headers: _headers(token));
  }

  Future<int> getUnreadNotificationCount(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/notifications/unread-count'), headers: _headers(token));
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['count'] ?? 0;
    }
    return 0;
  }

  Future<bool> sendBroadcast({required String token, required String role, required String title, required String body}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/broadcast'),
        headers: _headers(token),
        body: jsonEncode({'role': role, 'title': title, 'body': body}),
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> sendNewsletter({required String token, required String title, required String body}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/newsletter'),
        headers: _headers(token),
        body: jsonEncode({'title': title, 'body': body}),
      );
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<List<dynamic>> getNotificationsHistory(String token) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/notifications-history'), headers: _headers(token));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw 'Failed to load notification history';
  }

  Future<bool> submitFeedback(int rating, String comment, String token) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/feedback'),
        headers: _headers(token),
        body: jsonEncode({'rating': rating, 'comment': comment}),
      );
      return res.statusCode == 201;
    } catch (e) { return false; }
  }
}