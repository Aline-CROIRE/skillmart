import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;
  final bool isOwned; 
  const ProjectDetailsScreen({super.key, required this.project, this.isOwned = false});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  bool _isProcessing = false;
  String _currentUserId = "";

  @override
  void initState() { super.initState(); _loadIdentity(); }

  _getIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentUserId = prefs.getString('userId') ?? "");
  }

  Future<void> _openFile() async {
    final Uri url = Uri.parse("https://skillmart-api.onrender.com${widget.project.fileUrl}");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File link error")));
    }
  }

  void _confirmPurchase() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unlock Access"),
        content: Text("Confirm RWF ${widget.project.price} for '${widget.project.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () { Navigator.pop(context); _handlePurchase(); }, child: const Text("CONFIRM")),
        ],
      ),
    );
  }

  void _handlePurchase() async {
    setState(() => _isProcessing = true);
    final prefs = await SharedPreferences.getInstance();
    final success = await ApiService().purchaseProject(widget.project.id, prefs.getString('token')!);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchase Successful!"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Insufficient funds."), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Check if this is my own project
    bool isMyProject = _currentUserId == widget.project.sellerId;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Overview"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity, height: 200,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.folder_shared, size: 60, color: Color(0xFF0056b3)),
            ),
            const SizedBox(height: 30),
            Text(widget.project.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text("By ${widget.project.sellerName}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),
            const Text("Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(widget.project.description, style: const TextStyle(fontSize: 15, height: 1.6)),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildFooter(isMyProject),
    );
  }

  Widget _buildFooter(bool isMine) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black12))),
      child: Row(
        children: [
          if (!widget.isOwned && !isMine)
            Expanded(child: Text("RWF ${widget.project.price}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0056b3)))),
          
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                // DISABLE BUTTON IF IT IS MY PROJECT
                onPressed: isMine ? null : (widget.isOwned ? _openFile : _confirmPurchase),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMine ? Colors.grey[300] : const Color(0xFF0056b3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  isMine ? "YOUR CREATION" : (widget.isOwned ? "OPEN DOCUMENT" : "GET ACCESS"),
                  style: TextStyle(color: isMine ? Colors.grey : Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentUserId = prefs.getString('userId') ?? "");
  }
}