// lib/views/widgets/gradient_scaffold.dart
import 'package:flutter/material.dart';
import '../../utils/AppStyles.dart';

class GradientScaffold extends StatelessWidget {
  final AppBar? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

const GradientScaffold({
  super.key,
  this.appBar,
  required this.body,
  this.floatingActionButton,
  this.bottomNavigationBar,
});

@override
Widget build(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: AppColors.primaryGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    ),
  );
}
}
