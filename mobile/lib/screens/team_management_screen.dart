import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'file_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final _api = ApiService();
  List<dynamic> _analysts = [];
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
      final data = await _api.getAnalysts(token);
      setState(() => _analysts = data);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _createAnalyst() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Create Analyst Account"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
              const SizedBox(height: 10),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Temporary Password"), obscureText: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            loading 
              ? const SizedBox(width: 40, height: 40, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
              : ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                      _showError("All fields are required");
                      return;
                    }
                    setDialogState(() => loading = true);
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('token') ?? '';
                      await _api.createAnalyst(nameCtrl.text, emailCtrl.text, passCtrl.text, token);
                      if (mounted) {
                        Navigator.pop(context);
                        _fetch();
                      }
                    } catch (e) { 
                      _showError(e.toString()); 
                      setDialogState(() => loading = false);
                    }
                  },
                  child: const Text("CREATE"),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAnalyst(dynamic analyst) async {
    final nameCtrl = TextEditingController(text: analyst['name']);
    final emailCtrl = TextEditingController(text: analyst['email']);
    final phoneCtrl = TextEditingController(text: analyst['phoneNumber'] ?? "");
    bool loading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Analyst Info"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            loading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    setDialogState(() => loading = true);
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('token') ?? '';
                      await _api.updateAnalyst(
                        token: token,
                        userId: analyst['_id'],
                        name: nameCtrl.text,
                        email: emailCtrl.text,
                        phoneNumber: phoneCtrl.text,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        _fetch();
                      }
                    } catch (e) { 
                      _showError(e.toString()); 
                      setDialogState(() => loading = false);
                    }
                  },
                  child: const Text("SAVE CHANGES"),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _unconfirmProfile(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reverse Confirmation?"),
        content: const Text("This will prevent the analyst from evaluating projects. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("UNCONFIRM")
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await _api.unconfirmAnalystProfile(userId, prefs.getString('token') ?? '');
        _fetch();
      } catch (e) { _showError(e.toString()); }
    }
  }

  Future<void> _togglePause(String userId, bool isCurrentlyPaused) async {
    if (isCurrentlyPaused) {
      // Direct Unpause
      try {
        final prefs = await SharedPreferences.getInstance();
        await _api.togglePauseAnalyst(userId, null, prefs.getString('token') ?? '');
        _fetch();
      } catch (e) { _showError(e.toString()); }
      return;
    }

    // Show Pause Options
    int? selectedDays;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Suspend Analyst"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choose suspension duration:"),
            const SizedBox(height: 10),
            ListTile(title: const Text("3 Days"), onTap: () => Navigator.pop(context, 3)),
            ListTile(title: const Text("7 Days"), onTap: () => Navigator.pop(context, 7)),
            ListTile(title: const Text("30 Days"), onTap: () => Navigator.pop(context, 30)),
            ListTile(title: const Text("Indefinite"), onTap: () => Navigator.pop(context, 0)),
          ],
        ),
      ),
    ).then((value) async {
      if (value != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await _api.togglePauseAnalyst(userId, value == 0 ? null : value, prefs.getString('token') ?? '');
          _fetch();
        } catch (e) { _showError(e.toString()); }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Team Management")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAnalyst,
        icon: const Icon(Icons.add),
        label: const Text("New Analyst"),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _analysts.isEmpty
          ? const Center(child: Text("No analysts found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _analysts.length,
              itemBuilder: (context, i) {
                final a = _analysts[i];
                final bool paused = a['isPaused'] == true;
                final bool verified = a['emailVerified'] == true;
                final bool confirmed = a['isProfileConfirmed'] == true;
                final String? idUrl = a['nationalIdUrl'];
                final String? selfieUrl = a['verificationSelfieUrl'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    leading: CircleAvatar(
                      backgroundImage: a['avatar'] != null ? CachedNetworkImageProvider(a['avatar']) : null,
                      child: a['avatar'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(a['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _editAnalyst(a),
                          visualDensity: VisualDensity.compact,
                        )
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['email'], style: const TextStyle(fontSize: 12)),
                        if (a['phoneNumber'] != null)
                          Text(a['phoneNumber'], style: const TextStyle(fontSize: 12, color: Colors.blue)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _statusChip(verified ? "Verified" : "Unverified", verified ? Colors.green : Colors.orange),
                            const SizedBox(width: 8),
                            _statusChip(confirmed ? "Confirmed" : "Pending", confirmed ? Colors.blue : Colors.grey),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Compliance Checklist", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 10),
                            _requirementRow("Email Verified", verified),
                            _requirementRow("Phone Number Added", a['phoneNumber'] != null),
                            _requirementRow("National ID Uploaded", idUrl != null),
                            _requirementRow("Verification Selfie Uploaded", selfieUrl != null),
                            const Divider(height: 30),
                            if (idUrl != null || selfieUrl != null) ...[
                              const Text("Review Files", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              if (idUrl != null)
                                _fileTile("National ID", idUrl, Icons.badge_outlined),
                              if (selfieUrl != null)
                                _fileTile("Identity Verification Selfie", selfieUrl, Icons.face_retouching_natural),
                              const Divider(height: 30),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Account Access"),
                                Switch(
                                  value: !paused,
                                  activeColor: Colors.green,
                                  onChanged: (_) => _togglePause(a['_id'], paused),
                                ),
                              ],
                            ),
                            if (!confirmed)
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (verified && a['phoneNumber'] != null && idUrl != null && selfieUrl != null) 
                                        ? SkillMartTheme.primaryBlue 
                                        : Colors.grey.shade300,
                                    ),
                                    onPressed: (verified && a['phoneNumber'] != null && idUrl != null && selfieUrl != null) 
                                      ? () async {
                                        try {
                                          final prefs = await SharedPreferences.getInstance();
                                          await _api.confirmAnalystProfile(a['_id'], prefs.getString('token') ?? '');
                                          _fetch();
                                        } catch (e) { _showError(e.toString()); }
                                      } : null,
                                    child: const Text("CONFIRM PROFILE"),
                                  ),
                                ),
                              ),
                            if (confirmed)
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    onPressed: () => _unconfirmProfile(a['_id']),
                                    child: const Text("UNCONFIRM PROFILE"),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _requirementRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.cancel, size: 16, color: met ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: met ? Colors.green : Colors.red, fontSize: 12)),
        ],
      ),
    );
  }

  

  Widget _fileTile(String label, String url, IconData icon) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.fullscreen, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FileViewScreen(title: label, url: url),
          ),
        );
      },
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
