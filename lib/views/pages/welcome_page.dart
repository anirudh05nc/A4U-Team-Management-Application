import 'package:assistantforu/views/pages/signup_page.dart';
import 'package:assistantforu/views/widgets/gradient_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../utils/AppStyles.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 20.0),
                Text("WELCOME", style: AppTextStyles.appBarHeadingWhite, textAlign: TextAlign.center),
                const SizedBox(height: 50.0),
                Lottie.asset(
                  'assets/lotties/teamwork.json',
                  height: 300,
                ),
                const SizedBox(height: 48.0),

                const Text(
                  'Assistant For You',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 16.0),

                const Text(
                  'Effective Team Management Application',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 48.0),

                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 600;
                    double buttonWidth = isDesktop ? constraints.maxWidth * 0.35 : constraints.maxWidth;
                    return Center(
                      child: SizedBox(
                        width: buttonWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentColor,
                                foregroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: const Text('GET STARTED', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                                );
                              },
                            ),
                            const SizedBox(height: 16.0),

                            // Login Button
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.accentColor, width: 2),
                                foregroundColor: AppColors.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: const Text('LOGIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.accentColor)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginPage()),
                                );
                              },
                            ),
                            const SizedBox(height:10),
                          ]
                        ),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
