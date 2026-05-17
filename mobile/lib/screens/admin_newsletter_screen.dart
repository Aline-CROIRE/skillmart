import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'admin_notification_history_screen.dart';

class AdminNewsletterScreen extends StatefulWidget {
  const AdminNewsletterScreen({super.key});

  @override
  State<AdminNewsletterScreen> createState() => _AdminNewsletterScreenState();
}

class _AdminNewsletterScreenState extends State<AdminNewsletterScreen> {
  final ApiService _api = ApiService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendNewsletter() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in both fields")));
      return;
    }

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      // I'll need to add sendNewsletter to ApiService
      final success = await _api.sendNewsletter(
        token: token,
        title: _titleController.text,
        body: _messageController.text,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Newsletter dispatched!")));
          _titleController.clear();
          _messageController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to dispatch newsletter")));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Newsletter Hub"), 
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationHistoryScreen(initialFilter: 'newsletter'))),
            icon: const Icon(Icons.history, size: 18),
            label: const Text("History", style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Create Newsletter", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              const SizedBox(height: 10),
              Text(
                "This will be sent to all subscribed users. It will always appear in their notification tray, but they will only receive Push or Email if they've enabled it in their settings.",
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
              ),
              const SizedBox(height: 30),
              
              Text("Campaign Title", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "e.g., Monthly Market Recap",
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              
              const SizedBox(height: 25),
              
              Text("Newsletter Content", style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 10),
              TextField(
                controller: _messageController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Write your newsletter content here...",
                  filled: true,
                  fillColor: colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendNewsletter,
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
                          Icon(Icons.mark_as_unread_rounded),
                          SizedBox(width: 10),
                          Text("DISPATCH NEWSLETTER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
