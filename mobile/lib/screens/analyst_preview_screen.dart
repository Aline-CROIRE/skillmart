import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnalystPreviewScreen extends StatefulWidget {
  final Project project;
  const AnalystPreviewScreen({super.key, required this.project});

  @override
  State<AnalystPreviewScreen> createState() => _AnalystPreviewScreenState();
}

class _AnalystPreviewScreenState extends State<AnalystPreviewScreen> {
  final ApiService _api = ApiService();
  bool _isBusy = false;

  Future<void> _claimProject() async {
    setState(() => _isBusy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final success = await _api.claimProject(widget.project.id, token);
      if (success && mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'${widget.project.title}' assigned to your Work Desk.")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Project Preview"), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(height: 200, color: Colors.grey.withOpacity(0.1), child: const Center(child: CircularProgressIndicator())),
                        errorWidget: (context, url, error) => Container(height: 200, color: Colors.grey.withOpacity(0.1), child: const Icon(Icons.image_not_supported_outlined)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text("${p.category} • ${p.projectType}", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                        const Divider(height: 32),
                        _detailRow(Icons.person_outline, "Creator", p.sellerName),
                        _detailRow(Icons.business_center_outlined, "Entity", p.ownerType),
                        _detailRow(Icons.location_on_outlined, "Owner", p.ownerName.isEmpty ? p.sellerName : p.ownerName),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text("Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(p.description, style: TextStyle(fontSize: 15, height: 1.6, color: colorScheme.onSurface.withOpacity(0.8))),
            const SizedBox(height: 40),
            if (p.isShareholderSeeking) ...[
              const Text("Investment Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text("This project is seeking shareholders.", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100), // Spacing for bottom button
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: _isBusy 
          ? const Center(heightFactor: 1, child: CircularProgressIndicator())
          : SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _claimProject,
                child: const Text("ASSIGN TO ME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
