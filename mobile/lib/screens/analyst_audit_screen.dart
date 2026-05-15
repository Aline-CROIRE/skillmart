import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import 'file_view_screen.dart';

class AnalystAuditScreen extends StatefulWidget {
  final Project project;
  const AnalystAuditScreen({super.key, required this.project});

  @override
  State<AnalystAuditScreen> createState() => _AnalystAuditScreenState();
}

class _AnalystAuditScreenState extends State<AnalystAuditScreen> {
  final TextEditingController _note = TextEditingController();
  final TextEditingController _price = TextEditingController();
  String? _analyticsPath;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _price.text = widget.project.price.toString();
  }

  void _openInApp(String title, String url) {
    if (url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FileViewScreen(title: title, url: url)),
    );
  }

  Future<void> _pickAnalyticsDoc() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx']);
    if (result != null) {
      setState(() => _analyticsPath = result.files.single.path);
    }
  }

  void _submit(String status) async {
    if (_note.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please write your expert notes first.")));
      return;
    }
    if (status == 'approved') {
      if ((int.tryParse(_price.text) ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set a valid price before approving.")));
        return;
      }
      if (_analyticsPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload the full Analytics Document for this project.")));
        return;
      }
    }

    setState(() => _isBusy = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    bool success = await ApiService().submitAnalystDecision(
      widget.project.id, 
      status, 
      token, 
      reviewNote: _note.text,
      price: int.tryParse(_price.text),
      analyticsPath: _analyticsPath,
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
    final p = widget.project;

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
            
            _sectionTitle("Basic Information", context),
            _infoRow("Type", p.projectType, context),
            _infoRow("Description", p.description, context),
            if (p.externalLink.isNotEmpty) _infoRow("External Link", p.externalLink, context),
            
            const SizedBox(height: 25),
            _sectionTitle("Ownership & Structure", context),
            _infoRow("Owner Type", p.ownerType, context),
            _infoRow("Owner Name", p.ownerName.isEmpty ? p.sellerName : p.ownerName, context),
            if (p.ceoName.isNotEmpty) _infoRow("CEO", p.ceoName, context),
            if (p.linkedinUrl.isNotEmpty) _infoRow("LinkedIn", p.linkedinUrl, context),

            const SizedBox(height: 25),
            _sectionTitle("Investment Details", context),
            _infoRow("Seeking Shareholders", p.isShareholderSeeking ? "YES" : "NO", context),
            if (p.isShareholderSeeking) ...[
              _infoRow("Total Shares", p.totalSharesAvailable.toString(), context),
              _infoRow("Max Shareholders", p.maxShareholders.toString(), context),
              _infoRow("Min Share Purchase", "${p.minShare} Shares", context),
              _infoRow("Share Value", "RWF ${p.shareValue}", context),
            ],

            const SizedBox(height: 25),
            _sectionTitle("Verification Documents", context),
            _docTile("Main Project File", p.fileUrl, context),
            _docTile("Business Proposal", p.proposalUrl, context),
            _docTile("RDB Proof", p.rdbProofUrl, context),
            _docTile("Income Statement", p.incomeStatementUrl, context),
            _docTile("RRA Tax History", p.rraTaxHistoryUrl, context),
            _docTile("RRA Clearance", p.rraClearanceUrl, context),
            _docTile("Pitch Video / Media", p.pitchVideoUrl, context),

            const SizedBox(height: 30),
            _sectionTitle("Valuation & Feedback", context),
            
            // Analytics Doc Picker
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.blue.withOpacity(0.2))),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.blue),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Analytics Document", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_analyticsPath == null ? "Required for Approval (PDF/DOC)" : "Document ready: ${_analyticsPath!.split('/').last}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: _pickAnalyticsDoc, child: Text(_analyticsPath == null ? "UPLOAD" : "CHANGE")),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Evaluated Market Price (RWF)",
                prefixIcon: Icon(Icons.payments),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Expert Feedback / Instructions",
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

  Widget _sectionTitle(String text, BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
  );

  Widget _infoRow(String label, String value, BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text("$label:", style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );

  Widget _docTile(String label, String url, BuildContext context) {
    if (url.isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.fullscreen, size: 18),
      onTap: () => _openInApp(label, url),
    );
  }

  Widget _buildProjectIdentityCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final p = widget.project;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.thumbnailUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: CachedNetworkImage(
                imageUrl: p.thumbnailUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(height: 180, color: Colors.grey.withOpacity(0.1), child: const Center(child: CircularProgressIndicator())),
                errorWidget: (context, url, error) => Container(height: 180, color: Colors.grey.withOpacity(0.1), child: const Icon(Icons.image_not_supported_outlined)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, style: TextStyle(color: colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("${p.category} • ${p.sellerName}", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
              ],
            ),
          ),
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