import 'package:flutter/material.dart';

// 🎨 Neural Network Diamond Blue Theme

class AppColors {
  // Deep blue gradient for backgrounds
  static const List<Color> primaryGradient = [
    Color(0xFF0A1929), // Start
    Color(0xFF1A1F3A), // Mid
    Color(0xFF0A3D62), // End
  ];

  // Main background color (start of the gradient)
  static const Color primaryColor = Color(0xFF0A1929);

  // Bright cyan accents for interactive elements and highlights
  static const Color accentColor = Color(0xFF00E5FF);
  static const Color accentSecondaryColor = Color(0xFF00BCD4);
  
  // Text color
  static const Color textColor = Colors.white;
  static const Color buttonTextColor = Colors.black;

  // Glass morphism color for cards
  static final Color cardColor = Colors.white.withOpacity(0.1);

  // --- Mapped old colors to new theme ---
  static const Color secondButtonColor = accentSecondaryColor;
  static const Color mainbackground = primaryColor;
  static const Color drawerHeaderColor = primaryColor;
  static const Color listTileColor = Colors.white70;
}

class AppTextStyles {
  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
  );


  static const TextStyle heading = TextStyle(
    color: AppColors.textColor,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle appBarHeading = TextStyle(
    color: Colors.black,
    fontSize: 35,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle appBarHeadingWhite = TextStyle(
    color: Colors.white,
    fontSize: 35,
    fontWeight: FontWeight.w900,
  );

  // Updated for new theme: Dark text on bright buttons
  static const TextStyle buttonText = TextStyle(
    color: AppColors.primaryColor, 
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );
}

class AppButtonStyles {
  // Updated for new theme: Glowing cyan button
  static final ButtonStyle mainButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30.0),
    ),
  );

  static final ButtonStyle themeButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.accentColor,
    foregroundColor: AppColors.primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30.0),
    ),
  );
}
