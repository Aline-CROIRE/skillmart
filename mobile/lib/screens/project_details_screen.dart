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

  void _loadIdentity() async {
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("Unlock Access", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text("Confirm RWF ${widget.project.price} for '${widget.project.title}'?", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: TextStyle(color: Theme.of(context).colorScheme.primary))),
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

  void _handleWatch() async {
    setState(() => _isProcessing = true);
    final prefs = await SharedPreferences.getInstance();
    final success = await ApiService().watchProject(widget.project.id, prefs.getString('token')!);
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("We will notify you when approved!"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action failed."), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMyProject = _currentUserId == widget.project.sellerId;
    bool isApproved = widget.project.status == 'approved';
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Project Overview"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(colorScheme, !isApproved && !isMyProject),
            const SizedBox(height: 30),
            Text(widget.project.title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            Text("By ${widget.project.sellerName}", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
            
            if (!isApproved && !isMyProject) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: Colors.orange),
                    const SizedBox(width: 15),
                    Expanded(child: Text("This project is currently undergoing expert analysis. Analytics and pricing are not yet available.", style: TextStyle(color: colorScheme.onSurface, fontSize: 13))),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),
            Text("Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 10),
            Text(widget.project.description, style: TextStyle(fontSize: 15, height: 1.6, color: colorScheme.onSurface.withOpacity(0.8))),
            
            if (isApproved || isMyProject) ...[
              const SizedBox(height: 25),
              _buildInfoRow("Ownership", widget.project.ownerType, Icons.person, colorScheme),
              _buildInfoRow("Type", widget.project.projectType, Icons.category, colorScheme),
              if (widget.project.isShareholderSeeking)
                _buildInfoRow("Shareholders", "Seeking ${widget.project.maxShareholders}", Icons.groups, colorScheme),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildFooter(isMyProject, isApproved, colorScheme),
    );
  }

  Widget _buildThumbnail(ColorScheme colorScheme, bool isBlurred) {
    return Container(
      width: double.infinity, height: 220,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05), 
        borderRadius: BorderRadius.circular(20),
        image: widget.project.thumbnailUrl.isNotEmpty 
          ? DecorationImage(
              image: NetworkImage("https://skillmart-api.onrender.com${widget.project.thumbnailUrl}"),
              fit: BoxFit.cover
            )
          : null
      ),
      child: widget.project.thumbnailUrl.isEmpty 
        ? Icon(Icons.folder_shared, size: 60, color: colorScheme.primary)
        : null,
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          Text(value, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMine, bool isApproved, ColorScheme colorScheme) {
    if (isMine) {
      return _footerContainer(
        colorScheme,
        child: const Text("YOU ARE THE CREATOR", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      );
    }

    if (!isApproved) {
      return _footerContainer(
        colorScheme,
        child: ElevatedButton.icon(
          onPressed: _isProcessing ? null : _handleWatch,
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text("WAIT FOR ANALYTICS", style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      );
    }

    // Approved & Not Mine
    return _footerContainer(
      colorScheme,
      child: Row(
        children: [
          if (!widget.isOwned)
            Expanded(child: Text("RWF ${widget.project.price}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.primary))),
          
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: widget.isOwned ? _openFile : _confirmPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  widget.isOwned ? "OPEN DOCUMENT" : "GET ACCESS",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _footerContainer(ColorScheme colorScheme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor))
      ),
      child: child,
    );
  }
}