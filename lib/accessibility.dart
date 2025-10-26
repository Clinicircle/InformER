import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'accessibility_settings_provider.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {

  Widget _buildDropdownItem({
    required BuildContext context,
    required String label,
    required String currentValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required AccessibilitySettingsProvider settings,
    String? accessibleName,
  }) {
    if (items.isEmpty) {
      items = [currentValue];
    }
    final bool isCurrentValueInItems = items.contains(currentValue);

    return Semantics(
      label: accessibleName ?? label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: settings.primaryTextColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: settings.buttonBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: settings.borderColor, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: isCurrentValueInItems ? currentValue : (items.isNotEmpty ? items.first : null),
                  dropdownColor: settings.buttonBackgroundColor,
                  icon: Icon(Icons.arrow_drop_down, color: settings.secondaryTextColor),
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: settings.secondaryTextColor,
                  ),
                  items: items.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: items.length > 1 || (items.length == 1 && items.first != currentValue) ? onChanged : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderItem({
    required BuildContext context,
    required String label,
    required double currentValue,
    required double min,
    required double max,
    int? divisions,
    String? valueLabel,
    required ValueChanged<double> onChanged,
    required AccessibilitySettingsProvider settings,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valueLabel ?? '$label: ${currentValue.toStringAsFixed(1)}',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: settings.primaryTextColor,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: settings.sliderActiveColor,
              inactiveTrackColor: settings.sliderInactiveColor,
              thumbColor: settings.sliderActiveColor,
              overlayColor: settings.sliderActiveColor.withOpacity(0.3),
              trackHeight: 8.0,
              valueIndicatorTextStyle: GoogleFonts.dmSans(color: settings.buttonBackgroundColor),
            ),
            child: Slider(
              value: currentValue,
              min: min,
              max: max,
              divisions: divisions,
              label: currentValue.toStringAsFixed(divisions == null ? 1 : 0),
              onChanged: onChanged,
            ),
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
    final double topPadding = screenHeight * 0.08;
    final double contentPaddingHorizontal = screenWidth * 0.1;

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
              padding: EdgeInsets.symmetric(horizontal: contentPaddingHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: topPadding),
                  Text(
                    'Accessibility',
                    style: GoogleFonts.dmSans(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: settings.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildDropdownItem(
                          context: context,
                          label: 'Color Scheme',
                          currentValue: settings.colorScheme.toString().split('.').last,
                          items: ColorSchemeOption.values.map((e) => e.toString().split('.').last).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              settings.setColorScheme(ColorSchemeOption.values.firstWhere((e) => e.toString().split('.').last == newValue));
                            }
                          },
                          settings: settings,
                          accessibleName: "Select Color Scheme",
                        ),
                        _buildDropdownItem(
                          context: context,
                          label: 'Language',
                          currentValue: settings.language,
                          items: settings.availableLanguages.isNotEmpty ? settings.availableLanguages : [settings.language],
                          onChanged: (String? newValue) {
                            if (newValue != null) settings.setLanguage(newValue);
                          },
                          settings: settings,
                          accessibleName: "Select Language",
                        ),
                        _buildDropdownItem(
                          context: context,
                          label: 'Voice',
                          currentValue: settings.voice,
                          items: settings.voiceDisplayNames.isNotEmpty ? settings.voiceDisplayNames : [settings.voice],
                          onChanged: (String? newValue) {
                            if (newValue != null) settings.setVoice(newValue);
                          },
                          settings: settings,
                          accessibleName: "Select Voice",
                        ),
                        _buildSliderItem(
                          context: context,
                          label: 'App Volume',
                          currentValue: settings.appVolume,
                          min: 0,
                          max: 100,
                          divisions: 10,
                          valueLabel: 'App Volume: ${settings.appVolume.toInt()}%',
                          onChanged: (double value) {
                            settings.setAppVolume(value);
                          },
                          settings: settings,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
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
