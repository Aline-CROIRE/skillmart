import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import 'upload_screen.dart';
import 'project_details_screen.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});
  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  final ApiService _api = ApiService();
  List<Project> _myWork = [];
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getString('userId') ?? '';
      
      final profileData = await _api.getProfile(token);
      final data = await _api.getSellerProjects(userId, token);
      
      if (mounted) {
        setState(() { 
          _userProfile = profileData;
          _myWork = data; 
          _isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isEmailVerified = _userProfile?['emailVerified'] == true;
    bool hasPhone = _userProfile?['phoneNumber'] != null && _userProfile!['phoneNumber'].toString().isNotEmpty;
    bool canCreate = isEmailVerified && hasPhone;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Creations", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh))],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!canCreate && _userProfile != null)
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red),
                            SizedBox(width: 10),
                            Text("Action Required", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text("You must complete your profile to create projects:", style: TextStyle(color: colorScheme.onSurface, fontSize: 13)),
                        const SizedBox(height: 5),
                        if (!isEmailVerified)
                          Text("• Verify your email address", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                        if (!hasPhone)
                          Text("• Add a phone number to your profile", style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                Expanded(
                  child: _myWork.isEmpty && canCreate
                    ? _buildEmpty(context)
                    : RefreshIndicator(
                        onRefresh: _fetch,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20).copyWith(top: (!canCreate && _userProfile != null) ? 0 : 20),
                          itemCount: _myWork.length,
                          itemBuilder: (context, i) => _projectCard(_myWork[i], context),
                        ),
                      ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canCreate ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())).then((_) => _fetch()) : null,
        backgroundColor: canCreate ? colorScheme.primary : colorScheme.surfaceVariant,
        label: Text("New Creation", style: TextStyle(color: canCreate ? Colors.white : colorScheme.onSurfaceVariant.withOpacity(0.5), fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add, color: canCreate ? Colors.white : colorScheme.onSurfaceVariant.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(
    child: Text("You haven't shared anything yet. Start today!", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
  );

  Widget _projectCard(Project p, BuildContext context) {
    bool needsWork = p.status == 'needs_changes';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: p))),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(p.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
                _statusBadge(p.status, context),
              ],
            ),
            const SizedBox(height: 5),
            Text(p.category, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
            if (needsWork || p.status == 'pending') ...[
              const SizedBox(height: 15),
              if (needsWork)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Analyst Feedback:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      const SizedBox(height: 5),
                      Text(p.reviewNote, style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
                    ],
                  ),
                ),
              if (needsWork) const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => UploadScreen(existingProject: p))
                  ).then((_) => _fetch()),
                  icon: Icon(needsWork ? Icons.edit_document : Icons.edit, size: 18),
                  label: Text(needsWork ? "FIX & RESUBMIT" : "EDIT SUBMISSION"),
                ),
              )
            ],
            if (p.status == 'approved') ...[
               const Divider(height: 30),
               Text("Earnings: RWF ${p.price}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ]
          ],
        ),
      ),
      ),
    );
  }

  Widget _statusBadge(String status, BuildContext context) {
    String label = "Pending"; Color color = Colors.orange;
    if (status == 'approved') { label = "Verified"; color = Colors.green; }
    if (status == 'needs_changes') { label = "Needs Work"; color = Colors.orange; }
    if (status == 'rejected') { label = "Declined"; color = Colors.red; }
    if (status == 'under_review') { label = "In Review"; color = Theme.of(context).colorScheme.primary; }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}