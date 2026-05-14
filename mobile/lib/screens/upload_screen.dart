import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  final Project? existingProject; // Optional: If passed, we are editing
  const UploadScreen({super.key, this.existingProject});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late TextEditingController _title;
  late TextEditingController _desc;
  late TextEditingController _price;
  String _category = 'Academic';
  PlatformFile? _pickedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if we are editing
    _title = TextEditingController(text: widget.existingProject?.title ?? "");
    _desc = TextEditingController(text: widget.existingProject?.description ?? "");
    _price = TextEditingController(text: widget.existingProject?.price.toString() ?? "");
    if (widget.existingProject != null) _category = widget.existingProject!.category;
  }

  Future<void> _submit() async {
    if (_title.text.isEmpty || _price.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token')!;
    
    String? fileUrl = widget.existingProject?.fileUrl; // Keep old file by default
    if (_pickedFile != null) {
      fileUrl = await ApiService().uploadFile(_pickedFile!);
    }

    if (fileUrl != null) {
      final data = {
        'title': _title.text,
        'description': _desc.text,
        'category': _category,
        'price': int.parse(_price.text),
        'fileUrl': fileUrl,
        'sellerId': prefs.getString('userId'),
      };

      bool success;
      if (widget.existingProject != null) {
        // UPDATE MODE
        success = await ApiService().updateProject(widget.existingProject!.id, data, token);
      } else {
        // CREATE MODE
        success = await ApiService().submitProject(data, token);
      }

      if (mounted && success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submission updated!")));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingProject != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? "Improve My Work" : "Share New Work")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            _input("Project Title", _title, Icons.title),
            _input("Price (RWF)", _price, Icons.payments, isNum: true),
            _dropdown(),
            _input("Describe the value...", _desc, Icons.description, lines: 4),
            const SizedBox(height: 20),
            _filePicker(),
            const SizedBox(height: 40),
            _isLoading ? const CircularProgressIndicator() : 
            SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056b3)),
              onPressed: _submit, 
              child: Text(isEditing ? "RESUBMIT FOR REVIEW" : "PUBLISH TO COMMUNITY", style: const TextStyle(color: Colors.white))
            )),
          ],
        ),
      ),
    );
  }

  Widget _input(String h, TextEditingController c, IconData i, {int lines = 1, bool isNum = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(controller: c, maxLines: lines, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: h, prefixIcon: Icon(i), filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
  );

  Widget _dropdown() => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: DropdownButtonFormField<String>(value: _category, items: ["Academic", "Business", "Creative", "Technology", "Professional"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _category = v!), decoration: InputDecoration(filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none))),
  );

  Widget _filePicker() => InkWell(
    onTap: () async {
      final r = await FilePicker.platform.pickFiles();
      if (r != null) setState(() => _pickedFile = r.files.first);
    },
    child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFE1EFFE), borderRadius: BorderRadius.circular(15)), child: Row(children: [const Icon(Icons.cloud_upload), const SizedBox(width: 15), Expanded(child: Text(_pickedFile?.name ?? (widget.existingProject != null ? "Keep current file" : "Select File")))])),
  );
}