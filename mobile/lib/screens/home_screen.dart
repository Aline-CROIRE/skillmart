import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'marketplace_screen.dart';
import 'my_projects_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'analyst_queue_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentIndex = 0;
  String _role = 'User';
  String _userName = 'Friend';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? 'User';
      _userName = prefs.getString('userName') ?? 'Friend';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Use Admin/Analyst View or Regular User View
    bool isStaff = _role == 'Admin' || _role == 'Analyst';

    final List<Widget> pages = isStaff 
      ? [const MarketplaceScreen(), const AnalystQueueScreen(), const ProfileScreen()] 
      : [const MarketplaceScreen(), const MyProjectsScreen(), const LibraryScreen(), const ProfileScreen()];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.black54 : Colors.black12, 
              blurRadius: 10
            )
          ]
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          items: isStaff ? _staffItems() : _userItems(),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _userItems() => const [
    BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: "Explore"),
    BottomNavigationBarItem(icon: Icon(Icons.auto_stories_outlined), label: "My Work"),
    BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: "Collection"),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
  ];

  List<BottomNavigationBarItem> _staffItems() => const [
    BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: "Explore"),
    BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: "Review Hub"),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
  ];
}