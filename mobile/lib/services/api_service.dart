import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/project_model.dart';
import '../models/analysis_model.dart';

class ApiService {
  static const String baseUrl = 'https://skillmart-api.onrender.com/api';

  Future<List<Project>> getSellerProjects(String sellerId) async {
    final response = await http.get(Uri.parse('$baseUrl/seller/projects/$sellerId'));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => Project.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<Project>> getAdminQueue() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/queue'));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((item) => Project.fromJson(item)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getProjectDetails(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/admin/project/$id'));
    return jsonDecode(response.body);
  }

  Future<bool> adminDecision(String id, String status) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/decision/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }

  Future<String?> uploadFile(File file) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/projects/upload'));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    return response.statusCode == 200 ? jsonDecode(response.body)['fileUrl'] : null;
  }

  Future<bool> submitProject(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }
}