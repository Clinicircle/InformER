import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bglight.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/informerlogo.png',
                  width: screenWidth * 0.55,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.dmSans(
                        fontSize: 66,
                        fontWeight: FontWeight.bold,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Get patient ',
                          style: TextStyle(color: Color(0xFF000000)),
                        ),
                        TextSpan(
                          text: 'information',
                          style: TextStyle(color: Color(0xFF0F6D51)),
                        ),
                        TextSpan(
                          text: ' when you need it.',
                          style: TextStyle(color: Color(0xFF000000)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: screenWidth * 0.767,
                  height: screenHeight * 0.086,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                    style: _buttonStyle(screenHeight),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/clinicircleicon.png',
                          width: screenHeight * 0.04,
                          height: screenHeight * 0.04,
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: GoogleFonts.dmSans(
                                textStyle: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Continue with Clinicircle ',
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Tooltip(
                                    message:
                                    'The usage of this app requires an active\n'
                                        'subscription with Clinicircle. Subscriptions\n'
                                        'are available for medical institutions or\n'
                                        'local clinics or health-related centers and\n'
                                        'include all apps offered by Clinicircle,\n'
                                        'including InformER. To purchase a\n'
                                        'subscription, please contact (888) 880-CIRC.',
                                    textStyle: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 8.0),
                                    preferBelow: true,
                                    waitDuration:
                                    const Duration(milliseconds: 300),
                                    showDuration: const Duration(seconds: 5),
                                    child: Text(
                                      'ⓘ',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle(double height) {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.black, width: 5),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      minimumSize: Size.fromHeight(height * 0.086),
    );
  }
}
