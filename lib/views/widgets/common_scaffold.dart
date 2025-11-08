import 'package:assistantforu/views/pages/analytics_page.dart';
import 'package:assistantforu/views/pages/profile_page.dart';
import 'package:assistantforu/views/pages/team_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/AppStyles.dart';
import '../pages/dashboard.dart';
import '../pages/tasks_page.dart';

class CommonScaffold extends StatefulWidget {
  final User user;
  const CommonScaffold({
    super.key,
    required this.user,
  });


  @override
  State<CommonScaffold> createState() => _CommonScaffoldState();
}

class _CommonScaffoldState extends State<CommonScaffold> {
  int _selectedPage = 0;
  Widget? _fab;

  void _onPageSelected(int value){
    setState(() {
      _selectedPage = value;
       if (value != 2) {
        _fab = null;
      }
    });
    Navigator.pop(context);
  }

  void _onFabChanged(Widget? fab) {
    Future.microtask(() {
      setState(() {
        _fab = fab;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    final List<Widget> pages = [
      Dashboard(),
      TeamPage(),
      TasksPage(onFabChanged: _onFabChanged),
      AnalyticsPage(),
      ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.mainbackground,
      appBar: AppBar(
        title: FittedBox(child: Text("ASSISTANT FOR U", style: AppTextStyles.appBarHeading,)),
        backgroundColor: AppColors.accentColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          SizedBox(width: 50,)
        ],
      ),
      drawer: SafeArea(
        child: Drawer(
          backgroundColor: AppColors.primaryColor,

          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              // Drawer Header with Custom Styling
              DrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.drawerHeaderColor,
                  // Optional: Rounded corner inside the header
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.bubble_chart, // Focus-related icon
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    // Use AppTextStyles.heading and adjust color for contrast
                    Text(
                      'Assistant For You',
                      style: AppTextStyles.heading.copyWith(color: Colors.white, fontSize: 24),
                    ),
                    Text(
                      widget.user.email ?? 'Unknown User',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.home_outlined, color: AppColors.listTileColor),
                title: Text('Dashboard', style: TextStyle(color: AppColors.listTileColor, fontWeight: FontWeight.w500)),
                onTap: () => _onPageSelected(0),
              ),

              ListTile(
                leading: const Icon(Icons.group_outlined, color: AppColors.listTileColor),
                title: const Text('Team', style: TextStyle(color: AppColors.listTileColor, fontWeight: FontWeight.w500)),
                onTap: () => _onPageSelected(1),
              ),

              ListTile(
                leading: const Icon(Icons.task_alt_rounded, color: AppColors.listTileColor),
                title: const Text('Tasks', style: TextStyle(color: AppColors.listTileColor, fontWeight: FontWeight.w500)),
                onTap: () => _onPageSelected(2),
              ),

              ListTile(
                leading: const Icon(Icons.analytics_outlined, color: AppColors.listTileColor),
                title: const Text('Analytics', style: TextStyle(color: AppColors.listTileColor, fontWeight: FontWeight.w500)),
                onTap: () => _onPageSelected(3),
              ),

              ListTile(
                leading: const Icon(Icons.person_2_outlined, color: AppColors.listTileColor),
                title: const Text('Profile', style: TextStyle(color: AppColors.listTileColor, fontWeight: FontWeight.w500)),
                onTap: () => _onPageSelected(4),
              ),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: AppColors.buttonTextColor,
                  ),
                  child: const Text("LOGOUT", style: AppTextStyles.buttonText,),
                ),
              )
            ],
          ),

        ),
      ),
      body: pages[_selectedPage],
      floatingActionButton: _fab,
    );
  }
}
