import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

class AnalystAuditScreen extends StatefulWidget {
  final Project project;
  const AnalystAuditScreen({super.key, required this.project});

  @override
  State<AnalystAuditScreen> createState() => _AnalystAuditScreenState();
}

class _AnalystAuditScreenState extends State<AnalystAuditScreen> {
  final TextEditingController _note = TextEditingController();
  bool _isBusy = false;

  Future<void> _openFile() async {
    final String fullUrl = "https://skillmart-api.onrender.com${widget.project.fileUrl}";
    final Uri url = Uri.parse(fullUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link error")));
    }
  }

  void _submit(String status) async {
    if (_note.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please write your expert notes first.")));
      return;
    }
    setState(() => _isBusy = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    bool success = await ApiService().adminDecision(widget.project.id, status, token, reviewNote: _note.text);

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Evaluation Sent: ${status.toUpperCase()}")));
    }
    if (mounted) setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Expert Review Desk"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectIdentityCard(),
            const SizedBox(height: 25),
            const Text("Detailed Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Text(widget.project.description, style: const TextStyle(fontSize: 15, height: 1.6)),
            ),
            const SizedBox(height: 25),
            const Text("Verification Document", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildFileActionCard(),
            const SizedBox(height: 30),
            const Text("Your Expert Feedback", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write clear instructions for the creator...",
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            _isBusy ? const Center(child: CircularProgressIndicator()) : _buildDecisionButtons(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectIdentityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0056b3), Color(0xFF002a5a)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.project.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _meta("Creator", widget.project.sellerName),
              _meta("Category", widget.project.category),
              _meta("Price", "RWF ${widget.project.price}"),
            ],
          )
        ],
      ),
    );
  }

  Widget _meta(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    ],
  );

  Widget _buildFileActionCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFE1EFFE), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.description, color: Color(0xFF0056b3), size: 30),
          const SizedBox(width: 15),
          const Expanded(child: Text("Click to inspect the project contents", style: TextStyle(fontWeight: FontWeight.w500))),
          ElevatedButton(
            onPressed: _openFile,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056b3), foregroundColor: Colors.white),
            child: const Text("OPEN"),
          )
        ],
      ),
    );
  }

  Widget _buildDecisionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity, height: 55,
          child: ElevatedButton(
            onPressed: () => _submit('approved'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("VERIFY & PUBLISH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: OutlinedButton(onPressed: () => _submit('needs_changes'), style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)), child: const Text("REQUEST CHANGES"))),
            const SizedBox(width: 15),
            Expanded(child: OutlinedButton(onPressed: () => _submit('rejected'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)), child: const Text("DECLINE"))),
          ],
        )
      ],
    );
  }
}