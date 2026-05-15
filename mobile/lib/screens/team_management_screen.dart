import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

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

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Analyst Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Full Name")),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: "Temporary Password"), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              try {
                final prefs = await SharedPreferences.getInstance();
                await _api.createAnalyst(nameCtrl.text, emailCtrl.text, passCtrl.text, prefs.getString('token') ?? '');
                Navigator.pop(context);
                _fetch();
              } catch (e) { _showError(e.toString()); }
            },
            child: const Text("CREATE"),
          ),
        ],
      ),
    );
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

                return Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: paused ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.1)),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundImage: a['avatar'] != null ? NetworkImage(a['avatar']) : null,
                      child: a['avatar'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(a['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['email'], style: const TextStyle(fontSize: 12)),
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
                          children: [
                            if (idUrl != null)
                              ListTile(
                                leading: const Icon(Icons.badge_outlined),
                                title: const Text("View National ID"),
                                trailing: const Icon(Icons.open_in_new),
                                onTap: () { /* Open URL */ },
                              ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Account Active"),
                                Switch(
                                  value: !paused,
                                  activeColor: Colors.green,
                                  onChanged: (_) => _togglePause(a['_id'], paused),
                                ),
                              ],
                            ),
                            if (!confirmed)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      final prefs = await SharedPreferences.getInstance();
                                      await _api.confirmAnalystProfile(a['_id'], prefs.getString('token') ?? '');
                                      _fetch();
                                    } catch (e) { _showError(e.toString()); }
                                  },
                                  child: const Text("CONFIRM PROFILE"),
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
