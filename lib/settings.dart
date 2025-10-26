import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'about_session.dart';
import 'accessibility.dart';
import 'accessibility_settings_provider.dart';
import 'edit.dart';

class SettingsScreen extends StatelessWidget {
  final String userName;
  final String institutionName;
  final String sessionId;
  final String hashedInstitutionCode;

  const SettingsScreen({
    super.key,
    required this.userName,
    required this.institutionName,
    required this.sessionId,
    required this.hashedInstitutionCode,
  });

  ButtonStyle _settingsItemButtonStyle(
      double height,
      AccessibilitySettingsProvider settings, {
        double? fixedWidth,
      }) {
    return OutlinedButton.styleFrom(
      side: BorderSide.none,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      padding: EdgeInsets.zero,
      minimumSize: fixedWidth == null ? Size.fromHeight(height) : Size(fixedWidth, height),
      fixedSize: fixedWidth != null ? Size(fixedWidth, height) : null,
      alignment: Alignment.centerLeft,
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, {
        required String title,
        required VoidCallback onPressed,
        required double itemWidth,
        required double itemHeight,
        required AccessibilitySettingsProvider settings,
      }) {
    return SizedBox(
      width: itemWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: onPressed,
            style: _settingsItemButtonStyle(itemHeight, settings, fixedWidth: itemWidth).copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 15.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: settings.primaryTextColor,
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: settings.primaryTextColor, size: 24),
              ],
            ),
          ),
          Container(
            height: 3.0,
            width: itemWidth,
            color: settings.borderColor,
          ),
        ],
      ),
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
    final itemWidth = screenWidth * 0.8;
    final double topPadding = screenHeight * 0.08;
    final double settingsItemHeight = screenHeight * 0.08;

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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: topPadding),
                  Text(
                    'Settings',
                    style: GoogleFonts.dmSans(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: settings.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSettingsItem(
                    context,
                    title: 'About this Session',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AboutSessionScreen(
                            userName: userName,
                            institutionName: institutionName,
                            sessionId: sessionId,
                            hashedInstitutionCode: hashedInstitutionCode,
                          ),
                        ),
                      );
                    },
                    itemWidth: itemWidth,
                    itemHeight: settingsItemHeight,
                    settings: settings,
                  ),
                  const SizedBox(height: 5),
                  _buildSettingsItem(
                    context,
                    title: 'Accessibility',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AccessibilityScreen()),
                      );
                    },
                    itemWidth: itemWidth,
                    itemHeight: settingsItemHeight,
                    settings: settings,
                  ),
                  const SizedBox(height: 5),
                  _buildSettingsItem(
                    context,
                    title: 'Edit Defaults',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditScreen()),
                      );
                    },
                    itemWidth: itemWidth,
                    itemHeight: settingsItemHeight,
                    settings: settings,
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: screenWidth * 0.4,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: _pageButtonStyle(screenHeight, screenWidth * 0.4, settings),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
