import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'settings.dart';
import 'accessibility_settings_provider.dart';
import 'freddie.dart';
import 'app.dart';

ButtonStyle mainAppButtonStyle(
    double screenWidth,
    double screenHeight,
    AccessibilitySettingsProvider settings,
    ) {
  return OutlinedButton.styleFrom(
    side: BorderSide(color: settings.borderColor, width: 5),
    backgroundColor: settings.buttonBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
    minimumSize: Size(screenWidth * 0.8, screenHeight * 0.086),
  );
}

class MainAppScreen extends StatelessWidget {
  final String userName;
  final String institutionName;
  final String sessionId;
  final String hashedInstitutionCode;

  const MainAppScreen({
    super.key,
    required this.userName,
    required this.institutionName,
    required this.sessionId,
    required this.hashedInstitutionCode,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AccessibilitySettingsProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonWidth = screenWidth * 0.8;
    final buttonHeight = screenHeight * 0.086;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              settings.backgroundImage,
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      settings.logoImage,
                      width: screenWidth * 0.55,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppScreen(),
                            ),
                          );
                        },
                        style: mainAppButtonStyle(screenWidth, screenHeight, settings),
                        child: Text(
                          'Launch App',
                          style: GoogleFonts.dmSans(
                            fontSize: 31,
                            fontWeight: FontWeight.bold,
                            color: settings.primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FreddieScreen(
                                userName: userName,
                                institutionName: institutionName,
                                sessionId: sessionId,
                                hashedInstitutionCode: hashedInstitutionCode,
                              ),
                            ),
                          );
                        },
                        style: mainAppButtonStyle(screenWidth, screenHeight, settings),
                        child: Text(
                          'Talk with Freddie™',
                          style: GoogleFonts.dmSans(
                            fontSize: 31,
                            fontWeight: FontWeight.bold,
                            color: settings.primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: buttonWidth,
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                userName: userName,
                                institutionName: institutionName,
                                sessionId: sessionId,
                                hashedInstitutionCode: hashedInstitutionCode,
                              ),
                            ),
                          );
                        },
                        style: mainAppButtonStyle(screenWidth, screenHeight, settings),
                        child: Text(
                          'Settings',
                          style: GoogleFonts.dmSans(
                            fontSize: 31,
                            fontWeight: FontWeight.bold,
                            color: settings.primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
