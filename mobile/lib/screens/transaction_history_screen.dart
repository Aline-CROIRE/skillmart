import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});
  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;
  String _myId = "";

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      _myId = prefs.getString('userId') ?? '';
      
      final data = await ApiService().getTransactionHistory(token);
      if (mounted) setState(() { _history = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("Account Activity"), elevation: 0),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : _history.isEmpty
          ? const Center(child: Text("No transactions found yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _history.length,
              itemBuilder: (context, i) => _historyCard(_history[i]),
            ),
    );
  }

  Widget _historyCard(dynamic tx) {
    // Safety check: if project or buyer is null (deleted), use fallback text
    String projectTitle = tx['project']?['title'] ?? "Deleted Resource";
    String otherParty = "";
    
    bool isPurchase = tx['buyer']?['_id'] == _myId;
    if (isPurchase) {
      otherParty = "To: ${tx['seller']?['name'] ?? 'Unknown'}";
    } else {
      otherParty = "From: ${tx['buyer']?['name'] ?? 'Unknown'}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPurchase ? Colors.red[50] : Colors.green[50],
            child: Icon(
              isPurchase ? Icons.arrow_upward : Icons.arrow_downward,
              color: isPurchase ? Colors.red : Colors.green, size: 18,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(projectTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(otherParty, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            "${isPurchase ? '-' : '+'} RWF ${tx['amount']}",
            style: TextStyle(fontWeight: FontWeight.w900, color: isPurchase ? Colors.red : Colors.green),
          )
        ],
      ),
    );
  }
}