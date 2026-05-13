import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  
  String _title = '';
  String _description = '';
  String _category = 'Web';
  File? _selectedFile;
  bool _isLoading = false;

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields and select a file')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      String? fileUrl = await _apiService.uploadFile(_selectedFile!);
      if (fileUrl != null) {
        bool success = await _apiService.submitProject({
          'title': _title,
          'description': _description,
          'category': _category,
          'fileUrl': fileUrl,
          'sellerId': 'user_flutter_mobile',
        });

        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project submitted for analysis!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Project')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Title'),
                    onSaved: (val) => _title = val ?? '',
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    onSaved: (val) => _description = val ?? '',
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  DropdownButtonFormField(
                    value: _category,
                    items: ['Web', 'Mobile', 'AI', 'Design', 'Other']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => _category = val as String),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text(_selectedFile == null ? 'Select File' : 'File Selected'),
                    trailing: const Icon(Icons.attach_file),
                    onTap: _pickFile,
                    tileColor: Colors.grey[200],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Upload & Analyze'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}