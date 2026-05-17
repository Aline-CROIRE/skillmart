import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';
import 'analyst_audit_screen.dart';
import 'file_view_screen.dart';
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
  void initState() { 
    super.initState(); 
    _loadIdentity(); 
    _secureScreen();
  }

  @override
  void dispose() {
    _unsecureScreen();
    super.dispose();
  }

  Future<void> _secureScreen() async {
    try {
      await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
    } catch (e) {
      debugPrint("Could not set secure flag: $e");
    }
  }

  Future<void> _unsecureScreen() async {
    try {
      await FlutterWindowManagerPlus.clearFlags(FlutterWindowManagerPlus.FLAG_SECURE);
    } catch (e) {
      debugPrint("Could not clear secure flag: $e");
    }
  }

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
      await launchUrl(url, mode: LaunchMode.inAppBrowserView);
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
    final bool isStaff = _userRole == 'Admin' || _userRole == 'Analyst';
    
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
            
            if (widget.project.status == 'sold') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.handshake, color: Colors.red),
                    const SizedBox(width: 10),
                    const Expanded(child: Text("CLOSED / SOLD", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],
            
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
            if (isApproved || isMyProject || isStaff) ...[
              const SizedBox(height: 25),
              _buildInfoRow("Ownership", widget.project.ownerType, Icons.person, colorScheme),
              if (widget.project.ownerName.isNotEmpty)
                _buildInfoRow(widget.project.ownerType == "Individual" ? "Owner Name" : "Company Name", widget.project.ownerName, Icons.badge, colorScheme),
              if (widget.project.ceoName.isNotEmpty)
                _buildInfoRow("CEO Name", widget.project.ceoName, Icons.person_outline, colorScheme),
              _buildInfoRow("Type", widget.project.projectType, Icons.category, colorScheme),
              if (widget.project.externalLink.isNotEmpty)
                _buildInfoRow("External Link", widget.project.externalLink, Icons.link, colorScheme),
              if (widget.project.linkedinUrl.isNotEmpty)
                _buildInfoRow("LinkedIn", widget.project.linkedinUrl, Icons.link, colorScheme),
              if (widget.project.rdbRegistrationNumber.isNotEmpty)
                _buildInfoRow("RDB Registration Number", widget.project.rdbRegistrationNumber, Icons.business_center, colorScheme),
                
              if (widget.project.isShareholderSeeking) ...[
                const SizedBox(height: 15),
                Text("Shareholder Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 10),
                _buildInfoRow("Max Shareholders", "${widget.project.maxShareholders}", Icons.groups, colorScheme),
                _buildInfoRow("Current Secured Investors", "${widget.project.currentInvestors}", Icons.group_add, colorScheme),
                _buildInfoRow("Total Shares Available", "${widget.project.totalSharesAvailable}%", Icons.pie_chart, colorScheme),
                _buildInfoRow("Minimum Share", "${widget.project.minShare}%", Icons.percent, colorScheme),
                _buildInfoRow("Share Unit Value", "RWF ${widget.project.shareValue}", Icons.money, colorScheme),
              ],
              
              if (widget.project.proposalUrl.isNotEmpty || widget.project.rdbProofUrl.isNotEmpty || widget.project.incomeStatementUrl.isNotEmpty || widget.project.rraTaxHistoryUrl.isNotEmpty || widget.project.rraClearanceUrl.isNotEmpty || widget.project.pitchVideoUrl.isNotEmpty) ...[
                const SizedBox(height: 25),
                Text("Verification Documents", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 10),
                if (widget.project.proposalUrl.isNotEmpty) _buildFileRow("Proposal Document", widget.project.proposalUrl, Icons.description, colorScheme),
                if (widget.project.rdbProofUrl.isNotEmpty) _buildFileRow("RDB Certificate", widget.project.rdbProofUrl, Icons.verified, colorScheme),
                if (widget.project.incomeStatementUrl.isNotEmpty) _buildFileRow("Income Statement", widget.project.incomeStatementUrl, Icons.account_balance_wallet, colorScheme),
                if (widget.project.rraTaxHistoryUrl.isNotEmpty) _buildFileRow("Tax History", widget.project.rraTaxHistoryUrl, Icons.history, colorScheme),
                if (widget.project.rraClearanceUrl.isNotEmpty) _buildFileRow("Tax Clearance", widget.project.rraClearanceUrl, Icons.receipt_long, colorScheme),
                if (widget.project.pitchVideoUrl.isNotEmpty) _buildFileRow("Pitch Video", widget.project.pitchVideoUrl, Icons.video_library, colorScheme),
              ],
            ],

            // Expert Analytics Section
            if (isApproved) ...[
              const SizedBox(height: 35),
              const Text("Expert Premium Analytics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildAnalyticsCard(colorScheme, widget.isOwned || isStaff),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          Expanded(child: Text(value, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)))),
        ],
      ),
    );
  }

  Widget _buildFileRow(String label, String url, IconData icon, ColorScheme colorScheme) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url.startsWith('http') ? url : "https://skillmart-api.onrender.com$url");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open file")));
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 15),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
            Icon(Icons.open_in_new, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMyProject, bool isApproved, ColorScheme colorScheme) {
    final bool isStaff = _userRole == 'Admin' || _userRole == 'Analyst';

    // Staff view takes priority for auditing
    if (isStaff) {
      return _footerContainer(
        colorScheme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnalystAuditScreen(project: widget.project))),
                icon: const Icon(Icons.fact_check, color: Colors.white),
                label: const Text("AUDIT PROJECT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),
            ),
            if (_userRole == 'Admin' && widget.project.status != 'sold') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    bool confirm = await showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text("Mark as Closed/Sold?"),
                        content: const Text("This indicates that the project has successfully secured its required funding or was bought out of the system."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("CANCEL")),
                          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("MARK AS SOLD")),
                        ],
                      )
                    ) ?? false;
                    
                    if (confirm) {
                      setState(() => _isProcessing = true);
                      final prefs = await SharedPreferences.getInstance();
                      final success = await ApiService().updateProject(widget.project.id, {'status': 'sold'}, prefs.getString('token')!);
                      if (mounted) {
                        setState(() => _isProcessing = false);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Project marked as Closed/Sold!")));
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update status.")));
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.sell, color: Colors.red),
                  label: const Text("MARK AS CLOSED/SOLD", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                ),
              ),
            ]
          ],
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

  Widget _buildAnalyticsCard(ColorScheme colorScheme, bool hasAccess) {
    if (!hasAccess) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.lock_person_outlined, size: 40, color: Colors.grey),
            const SizedBox(height: 15),
            const Text("Premium Analytics Locked", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              "Full deep-dive expert analysis and valuation documents are hidden until this project is purchased.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text("PURCHASE TO UNLOCK", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final bool isStaff = _userRole == 'Admin' || _userRole == 'Analyst';
    if (isStaff) {
       return _analyticsActionBox(
        colorScheme,
        "Expert Insight Ready",
        "Staff can preview the analytics document.",
        "PREVIEW",
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => FileViewScreen(title: "Expert Analytics", url: widget.project.analyticsFileUrl))),
      );
    }

    final request = widget.project.analyticsAccessRequests.firstWhere(
      (r) => r['userId'].toString() == _currentUserId, 
      orElse: () => null
    );

    if (request == null) {
      return _analyticsActionBox(
        colorScheme,
        "Premium Evaluation",
        "Get a deep-dive professional analysis of this project's viability.",
        "REQUEST ACCESS",
        _requestAnalytics,
      );
    }

    if (request['status'] == 'pending') {
      return _analyticsActionBox(
        colorScheme,
        "Request Sent",
        "Your request is being reviewed by the Admin.",
        "PENDING",
        null,
      );
    }

    if (request['status'] == 'granted') {
      return _analyticsActionBox(
        colorScheme,
        "Access Granted",
        "You now have full access to the expert evaluation.",
        "OPEN ANALYTICS",
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => FileViewScreen(title: "Expert Analytics", url: widget.project.analyticsFileUrl))),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _analyticsActionBox(ColorScheme colorScheme, String title, String sub, String btn, VoidCallback? action) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: colorScheme.primary.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(sub, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 15),
          if (action != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: action, child: Text(btn)),
            )
          else
            Container(
              width: double.infinity, height: 45,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(btn, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ),
        ],
      ),
    );
  }

  Future<void> _requestAnalytics() async {
    setState(() => _isProcessing = true);
    final prefs = await SharedPreferences.getInstance();
    final res = await ApiService().requestAnalyticsAccess(widget.project.id, prefs.getString('token')!);
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
      // Note: Ideally refresh the project data here
    }
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