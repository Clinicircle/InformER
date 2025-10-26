import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'accessibility_settings_provider.dart';

class AboutSessionScreen extends StatelessWidget {
  final String userName;
  final String institutionName;
  final String sessionId;
  final String hashedInstitutionCode;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AboutSessionScreen({
    super.key,
    required this.userName,
    required this.institutionName,
    required this.sessionId,
    required this.hashedInstitutionCode,
  });

  Future<void> _endSessionInFirestore(BuildContext context) async {
    try {
      await _firestore.collection('Information').doc(hashedInstitutionCode).update({
        'SessionIdentifiers': FieldValue.arrayRemove([sessionId])
      });

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ending session: ${e.toString()}')),
        );
      }
    }
  }

  void _showEndSessionConfirmationDialog(BuildContext context, AccessibilitySettingsProvider settings) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: settings.buttonBackgroundColor,
          title: Text(
            'Are you sure you want to end this session? This frees up the session identifier for your institution.',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                color: settings.primaryTextColor
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: settings.colorScheme == ColorSchemeOption.highContrast
                      ? Colors.black
                      : const Color(0xFFEFEFEF),
                  side: BorderSide(color: settings.borderColor, width: 2)
              ),
              child: Text(
                'No',
                style: GoogleFonts.dmSans(
                    color: settings.colorScheme == ColorSchemeOption.highContrast
                        ? settings.secondaryTextColor
                        : Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6D51),
                  side: BorderSide(color: settings.borderColor, width: 2)
              ),
              child: Text(
                'Yes',
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _endSessionInFirestore(context);
              },
            ),
          ],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
              side: BorderSide(color: settings.borderColor, width: 2)
          ),
        );
      },
    );
  }

  ButtonStyle _pageButtonStyle(
      double screenHeight,
      double buttonWidth,
      AccessibilitySettingsProvider settings, {
        Color? specificBackgroundColor,
      }) {
    return OutlinedButton.styleFrom(
      side: BorderSide(color: settings.borderColor, width: 5),
      backgroundColor: specificBackgroundColor ?? settings.buttonBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      minimumSize: Size(buttonWidth, screenHeight * 0.086),
      fixedSize: Size(buttonWidth, screenHeight * 0.086),
      alignment: Alignment.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AccessibilitySettingsProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = screenHeight * 0.08;
    final double contentPaddingHorizontal = screenWidth * 0.1;
    final double buttonWidth = screenWidth * 0.4;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: screenWidth,
        height: screenHeight,
        color: settings.colorScheme == ColorSchemeOption.dark
            ? Colors.black
            : settings.colorScheme == ColorSchemeOption.highContrast
            ? Colors.black
            : Colors.white,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              settings.backgroundImage,
              fit: BoxFit.cover,
              width: screenWidth,
              height: screenHeight,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.red, child: Center(child: Text("Error loading image", style: TextStyle(color: Colors.white))));
              },
            ),
            SafeArea(
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: contentPaddingHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: topPadding),
                      Text(
                        'About this Session',
                        style: GoogleFonts.dmSans(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: settings.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'InformER 2025.1.1\n$institutionName\nSession Identifier: $sessionId\nStarted by: $userName',
                        style: GoogleFonts.dmSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: settings.primaryTextColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                        width: buttonWidth,
                        child: OutlinedButton(
                          onPressed: () {
                            _showEndSessionConfirmationDialog(context, settings);
                          },
                          style: _pageButtonStyle(
                            screenHeight,
                            buttonWidth,
                            settings,
                            specificBackgroundColor: const Color(0xFF0F6D51),
                          ),
                          child: Text(
                            'End Session',
                            style: GoogleFonts.dmSans(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: buttonWidth,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: _pageButtonStyle(
                              screenHeight,
                              buttonWidth,
                              settings
                          ),
                          child: Text(
                            '← Back',
                            style: GoogleFonts.dmSans(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: settings.secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
