import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'analyst_audit_screen.dart';
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
  bool _isBookmarked = false;
  String _currentUserId = "";
  String _userRole = "User";


  @override
  void initState() { super.initState(); _loadIdentity(); }

  void _loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? "";
    final role = prefs.getString('role') ?? "User";
    setState(() {
      _currentUserId = uid;
      _userRole = role;
    });
    
    // Check if bookmarked
    final profile = await ApiService().getProfile(prefs.getString('token') ?? "");
    if (profile != null && profile['bookmarkedProjects'] != null) {
      final List bookmarks = profile['bookmarkedProjects'];
      setState(() {
        _isBookmarked = bookmarks.any((b) => b['_id'] == widget.project.id);
      });
    }
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    if (token.isEmpty) return;

    setState(() => _isProcessing = true);
    final res = await ApiService().bookmarkProject(widget.project.id, token);
    if (mounted && res != null) {
      setState(() {
        _isBookmarked = res['isBookmarked'] ?? false;
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? "Action successful"),
        backgroundColor: _isBookmarked ? Colors.green : Colors.grey,
      ));
    }
  }

  Future<void> _openFile() async {
    final url = Uri.parse(widget.project.fileUrl.startsWith('http') 
      ? widget.project.fileUrl 
      : "https://skillmart-api.onrender.com${widget.project.fileUrl}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open file")));
    }
  }

  void _confirmPurchase() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_checkout_rounded, size: 50, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Confirm Purchase", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("You are about to unlock full access to \"${widget.project.title}\" for RWF ${widget.project.price}.", textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL"))),
                const SizedBox(width: 15),
                Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); _handlePurchase(); }, child: const Text("CONFIRM"))),
              ],
            )
          ],
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final bool isApproved = widget.project.status == 'approved';
    final bool isMyProject = widget.project.sellerId == _currentUserId;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Project Overview"), 
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isProcessing ? null : _toggleBookmark,
            icon: Icon(
              _isBookmarked ? Icons.favorite : Icons.favorite_border,
              color: _isBookmarked ? Colors.red : null,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(colorScheme, !isApproved && !isMyProject),
            const SizedBox(height: 25),
            Text(widget.project.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Analytics Awaiting Box
            if (!isApproved && !isMyProject) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    Icon(Icons.query_stats, color: colorScheme.primary),
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
            
            // Full details for owner or approved projects
            if (isApproved || isMyProject) ...[
              const SizedBox(height: 25),
              _buildInfoRow("Ownership", widget.project.ownerType, Icons.person, colorScheme),
              _buildInfoRow("Type", widget.project.projectType, Icons.category, colorScheme),
              if (widget.project.isShareholderSeeking)
                _buildInfoRow("Shareholders", "Seeking ${widget.project.maxShareholders}", Icons.groups, colorScheme),
              if (widget.project.linkedinUrl.isNotEmpty)
                _buildInfoRow("LinkedIn", widget.project.linkedinUrl, Icons.link, colorScheme),
            ],

            if (isMyProject && widget.project.reviewNote.isNotEmpty) ...[
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Analyst Note:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 5),
                    Text(widget.project.reviewNote, style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
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
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: widget.project.thumbnailUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: widget.project.thumbnailUrl.startsWith('http') ? widget.project.thumbnailUrl : "https://skillmart-api.onrender.com${widget.project.thumbnailUrl}",
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Center(child: Icon(Icons.broken_image_outlined, color: colorScheme.primary)),
            )
          : Icon(Icons.folder_shared, size: 60, color: colorScheme.primary),
      ),
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

  Widget _buildFooter(bool isMyProject, bool isApproved, ColorScheme colorScheme) {
    final bool isStaff = _userRole == 'Admin' || _userRole == 'Analyst';

    // Staff view takes priority for auditing
    if (isStaff) {
      return _footerContainer(
        colorScheme,
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalystAuditScreen(project: widget.project))),
            icon: const Icon(Icons.fact_check, color: Colors.white),
            label: const Text("AUDIT PROJECT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
        ),
      );
    }

    // If it's my project, I should always be able to open the document
    if (isMyProject) {
      return _footerContainer(
        colorScheme,
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: _openFile,
            icon: const Icon(Icons.file_open, color: Colors.white),
            label: const Text("VIEW MY SUBMISSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
        ),
      );
    }

    if (!isApproved) {
      return _footerContainer(
        colorScheme,
        child: Row(
          children: [
            Expanded(child: Text("Awaiting Analyst Audit", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold))),
            const SizedBox(width: 10),
            const Icon(Icons.info_outline, color: Colors.grey),
          ],
        ),
      );
    }

    // Approved & Not Mine
    return _footerContainer(
      colorScheme,
      child: Row(
        children: [
          Expanded(child: Text("RWF ${widget.project.price}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorScheme.primary))),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: widget.isOwned ? _openFile : _confirmPurchase,
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text(widget.isOwned ? "OPEN DOCUMENT" : "GET ACCESS", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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