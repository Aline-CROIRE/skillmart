import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'marketplace_screen.dart';
import 'my_projects_screen.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'analyst_queue_screen.dart';
import 'analyst_work_desk_screen.dart';
import 'admin_verification_screen.dart';
import 'admin_analytics_requests_screen.dart';
import 'team_management_screen.dart';
import '../widgets/rating_dialog.dart';
import 'dart:math';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});
  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentIndex = 0;
  String _role = 'User';
  String _userName = 'Friend';
  bool _isProfileConfirmed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    // Set initial values from prefs
    setState(() {
      _role = prefs.getString('role') ?? 'User';
      _userName = prefs.getString('userName') ?? 'Friend';
      _isProfileConfirmed = prefs.getBool('isProfileConfirmed') ?? false;
      _isLoading = (token.isNotEmpty); // Keep loading if we have a token to fetch fresh data
    });

    if (token.isNotEmpty) {
      try {
        final profile = await ApiService().getProfile(token);
        if (profile != null && mounted) {
          final freshStatus = profile['isProfileConfirmed'] == true;
          setState(() {
            _isProfileConfirmed = freshStatus;
            _isLoading = false;
          });
          await prefs.setBool('isProfileConfirmed', freshStatus);
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }

    // Rating Dialog Trigger
    _checkAndShowRating();
  }

  Future<void> _checkAndShowRating() async {
    if (_role != 'User') return;
    
    final prefs = await SharedPreferences.getInstance();
    final lastRated = prefs.getInt('lastRatingPrompt') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Prompt only once every 3 days max, and with a 20% random chance
    if (now - lastRated > 3 * 24 * 60 * 60 * 1000) {
      if (Random().nextInt(5) == 0) {
        if (mounted) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              showDialog(context: context, builder: (context) => const RatingDialog());
              prefs.setInt('lastRatingPrompt', now);
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Define Pages based on Role
    List<Widget> pages = [];
    if (_role == 'Admin') {
      pages = [
        const AdminVerificationScreen(),
        const AdminAnalyticsRequestsScreen(),
        const TeamManagementScreen(),
        const ProfileScreen()
      ];
    } else if (_role == 'Analyst') {
      if (_isProfileConfirmed) {
        pages = [
          const AnalystQueueScreen(), // Left: Available projects (Queue)
          const AnalystWorkDeskScreen(), // Middle: Assigned projects
          const ProfileScreen() // Right: Account
        ];
      } else {
        pages = [const ProfileScreen()];
        if (_currentIndex != 0) _currentIndex = 0;
      }
    } else {
      pages = [const MarketplaceScreen(), const MyProjectsScreen(), const LibraryScreen(), const ProfileScreen()];
    }

    return Scaffold(
      body: pages.length == 1 ? pages[0] : IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: pages.length < 2 ? null : Container(
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
          items: _buildNavItems(),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    if (_role == 'Admin') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: "Queue"),
        BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: "Analytics"),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "Team"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
      ];
    } else if (_role == 'Analyst') {
      if (!_isProfileConfirmed) {
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
        ];
      }
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: "Submitted"),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: "Work Desk"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: "Explore"),
        BottomNavigationBarItem(icon: Icon(Icons.auto_stories_outlined), label: "My Work"),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: "Collection"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
      ];
    }
  }
}