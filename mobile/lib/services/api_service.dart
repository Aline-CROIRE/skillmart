import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project_model.dart';

class ApiService {
  static const String baseUrl = 'https://skillmart-api.onrender.com/api';

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/auth/login'), headers: _headers(null), body: jsonEncode({'email': email, 'password': password}));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> register(String name, String email, String password, String role) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/auth/register'), headers: _headers(null), body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role}));
      return res.statusCode == 201 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>?> getProfile(String token) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/auth/profile'), headers: _headers(token));
      return res.statusCode == 200 ? jsonDecode(res.body) : null;
    } catch (e) { return null; }
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

  Future<List<Project>> getAdminQueue(String token) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/analyst/queue'), headers: _headers(token));
      return res.statusCode == 200 ? (jsonDecode(res.body) as List).map((e) => Project.fromJson(e)).toList() : [];
    } catch (e) { return []; }
  }

  Future<bool> adminDecision(String id, String status, String token, {String reviewNote = "", int? price}) async {
    try {
      final body = {'status': status, 'reviewNote': reviewNote};
      if (price != null) body['price'] = price.toString();
      
      final res = await http.patch(Uri.parse('$baseUrl/analyst/review/$id'), headers: _headers(token), body: jsonEncode(body));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> watchProject(String id, String token) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/projects/watch/$id'), headers: _headers(token));
      return res.statusCode == 200;
    } catch (e) { return false; }
  }
}