import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final success = await ApiService().submitFeedback(_rating, _commentController.text, token);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thank you for your feedback!")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to submit feedback.")));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, size: 60, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                "How's your experience?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "We'd love to hear your thoughts on SkillMart.",
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              
              // Star Rating
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 2,
                children: List.generate(5, (index) {
                  int score = index + 1;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _rating = score),
                    icon: Icon(
                      _rating >= score ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 20),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Optional: Tell us why...",
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_rating == 0 || _isSubmitting) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SUBMIT FEEDBACK", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Maybe Later", style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
