import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'admin_notification_history_screen.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final ApiService _api = ApiService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedRole = 'All';
  bool _isSending = false;

  final List<String> _roles = ['All', 'Admin', 'Analyst', 'User'];

  Future<void> _sendBroadcast() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both title and message")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final success = await _api.sendBroadcast(
        token: token,
        role: _selectedRole,
        title: _titleController.text,
        body: _messageController.text,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Broadcast sent successfully!")),
          );
          _titleController.clear();
          _messageController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to send broadcast")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Broadcast Hub"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationHistoryScreen(initialFilter: 'broadcast'))),
            icon: const Icon(Icons.history, size: 18),
            label: const Text("History", style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Send Global Announcement",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Compose a message that will be sent as a push notification and saved to the tray of selected users.",
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              
              // Role Selector
              Text("Target Audience", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Title Field
              Text("Notification Title", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "e.g., System Maintenance",
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Message Field
              Text("Message Body", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 10),
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Enter your message here...",
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendBroadcast,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSending 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded),
                          SizedBox(width: 10),
                          Text("DISPATCH BROADCAST", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
