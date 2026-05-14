import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../models/project_model.dart';

class ApiService {
  static const String baseUrl = 'https://skillmart-api.onrender.com/api';

  // Private helper to generate consistent headers
  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // 1. AUTHENTICATION: Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // 2. AUTHENTICATION: Register
  Future<Map<String, dynamic>?> register(String name, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers(null),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      if (response.statusCode == 201) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // 3. PROJECTS: Fetch all approved projects (Marketplace)
  Future<List<Project>> getAllProjects() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/projects'));
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Project.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 4. PROJECTS: Upload File (Supports Web & Mobile)
  Future<String?> uploadFile(PlatformFile file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/projects/upload'));

      if (file.bytes != null) {
        // Handle WEB: Using bytes
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
          contentType: MediaType('application', 'octet-stream'),
        ));
      } else if (file.path != null) {
        // Handle MOBILE: Using path
        request.files.add(await http.MultipartFile.fromPath('file', file.path!));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['fileUrl'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 5. PROJECTS: Submit Project Metadata
  Future<bool> submitProject(Map<String, dynamic> data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: _headers(token),
        body: jsonEncode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 6. ADMIN: Get queue of pending projects
  Future<List<Project>> getAdminQueue(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/queue'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Project.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 7. ADMIN: Approve or Reject a project
  Future<bool> adminDecision(String projectId, String status, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/decision/$projectId'),
        headers: _headers(token),
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 8. MARKETPLACE: Purchase a project (RWF Transaction)
  Future<bool> purchaseProject(String projectId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/market/purchase'),
        headers: _headers(token),
        body: jsonEncode({'projectId': projectId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 9. ANALYTICS: Get trends (Analyst/Admin Only)
  Future<Map<String, dynamic>?> getGlobalTrends(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/trends'),
        headers: _headers(token),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }
}