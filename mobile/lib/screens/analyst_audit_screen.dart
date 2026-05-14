import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme.dart';

class AnalystAuditScreen extends StatefulWidget {
  final Project project;
  const AnalystAuditScreen({super.key, required this.project});

  @override
  State<AnalystAuditScreen> createState() => _AnalystAuditScreenState();
}

class _AnalystAuditScreenState extends State<AnalystAuditScreen> {
  final TextEditingController _note = TextEditingController();
  final TextEditingController _price = TextEditingController();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _price.text = widget.project.price.toString();
  }

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
    if (status == 'approved' && (int.tryParse(_price.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set a valid price before approving.")));
      return;
    }

    setState(() => _isBusy = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    bool success = await ApiService().adminDecision(
      widget.project.id, 
      status, 
      token, 
      reviewNote: _note.text,
      price: int.tryParse(_price.text),
    );

    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Evaluation Sent: ${status.toUpperCase()}")));
    }
    if (mounted) setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Expert Review Desk"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectIdentityCard(context),
            const SizedBox(height: 25),
            Text("Detailed Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(15)),
              child: Text(widget.project.description, style: TextStyle(fontSize: 15, height: 1.6, color: colorScheme.onSurface)),
            ),
            const SizedBox(height: 25),
            Text("Verification Document", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            _buildFileActionCard(context),
            const SizedBox(height: 30),
            
            Text("Set Project Price (RWF)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter evaluated market price...",
                prefixIcon: Icon(Icons.payments),
              ),
            ),
            const SizedBox(height: 25),

            Text("Your Expert Feedback", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Write clear instructions for the creator...",
              ),
            ),
            const SizedBox(height: 40),
            _isBusy ? const Center(child: CircularProgressIndicator()) : _buildDecisionButtons(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectIdentityCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.project.title, style: TextStyle(color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
          Divider(color: Theme.of(context).dividerColor, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _meta("Creator", widget.project.sellerName, colorScheme),
              _meta("Category", widget.project.category, colorScheme),
              _meta("Price", "RWF ${widget.project.price}", colorScheme),
            ],
          )
        ],
      ),
    );
  }

  Widget _meta(String label, String value, ColorScheme colorScheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
      Text(value, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
    ],
  );

  Widget _buildFileActionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(Icons.description, color: Theme.of(context).colorScheme.primary, size: 30),
          const SizedBox(width: 15),
          Expanded(child: Text("Click to inspect the project contents", style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface))),
          ElevatedButton(
            onPressed: _openFile,
            child: const Text("OPEN"),
          )
        ],
      ),
    );
  }

  Widget _buildDecisionButtons(BuildContext context) {
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