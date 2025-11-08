import 'package:assistantforu/services/auth_service.dart';
import 'package:assistantforu/views/pages/dashboard.dart';
import 'package:assistantforu/views/pages/welcome_page.dart';
import 'package:assistantforu/views/widgets/common_scaffold.dart';
import 'package:flutter/material.dart';


class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return CommonScaffold(user: snapshot.data!);
        } else {
          return const WelcomePage();
        }
      },
    );
  }
}
