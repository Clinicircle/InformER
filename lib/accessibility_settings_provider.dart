import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorSchemeOption { light, dark, highContrast }

class AccessibilitySettingsProvider with ChangeNotifier {
  ColorSchemeOption _colorScheme = ColorSchemeOption.light;
  double _cycleSpeed = 1.0;
  String _language = "English (US)";
  String _voice = "Achernar";
  double _appVolume = 50.0;
  List<String> _customPhrases = [];

  late FlutterTts _flutterTts;
  List<String> _availableLanguages = ["en-US"];
  List<Map<String, String>> _rawAvailableVoices = [];
  List<String> _voiceDisplayNames = ["Albert (en-US)"];

  ColorSchemeOption get colorScheme => _colorScheme;
  double get cycleSpeed => _cycleSpeed;
  String get language => _language;
  String get voice => _voice;
  double get appVolume => _appVolume;
  List<String> get customPhrases => _customPhrases;

  List<String> get availableLanguages => _availableLanguages;
  List<String> get voiceDisplayNames => _voiceDisplayNames;
  List<Map<String, String>> get rawAvailableVoices => _rawAvailableVoices;

  String get backgroundImage {
    switch (_colorScheme) {
      case ColorSchemeOption.light:
        return 'assets/images/bglight.png';
      case ColorSchemeOption.dark:
        return 'assets/images/bgdark.png';
      case ColorSchemeOption.highContrast:
        return 'assets/images/bghighcontrast.png';
    }
  }

  Color get primaryTextColor {
    switch (_colorScheme) {
      case ColorSchemeOption.light:
        return Colors.black;
      case ColorSchemeOption.dark:
        return Colors.white;
      case ColorSchemeOption.highContrast:
        return const Color(0xFFFFFF00);
    }
  }

  Color get secondaryTextColor {
    switch (_colorScheme) {
      case ColorSchemeOption.light:
        return Colors.black;
      case ColorSchemeOption.dark:
        return Colors.white;
      case ColorSchemeOption.highContrast:
        return const Color(0xFF00FF00);
    }
  }

  Color get borderColor {
    switch (_colorScheme) {
      case ColorSchemeOption.light:
        return Colors.black;
      case ColorSchemeOption.dark:
        return Colors.white;
      case ColorSchemeOption.highContrast:
        return const Color(0xFF00FF00);
    }
  }

  Color get buttonBackgroundColor {
    switch (_colorScheme) {
      case ColorSchemeOption.light:
        return const Color(0xFFEFEFEF);
      case ColorSchemeOption.dark:
        return const Color(0xFF19191B);
      case ColorSchemeOption.highContrast:
        return const Color(0xFF000000);
    }
  }

  Color get sliderActiveColor {
    switch (_colorScheme) {
      case ColorSchemeOption.light:
      case ColorSchemeOption.dark:
        return const Color(0xFF199FF1);
      case ColorSchemeOption.highContrast:
        return const Color(0xFFFFFF00);
    }
  }

  Color get sliderInactiveColor {
    switch (_colorScheme) {
      case ColorSchemeOption.light:
      case ColorSchemeOption.dark:
        return const Color(0xFFEFEFEF);
      case ColorSchemeOption.highContrast:
        return Colors.white;
    }
  }

  AccessibilitySettingsProvider() {
    _flutterTts = FlutterTts();
    _loadSettingsAndInitializeTts();
  }

  Future<void> _loadSettingsAndInitializeTts() async {
    await _loadSettings();
    await _initializeTtsAndFetchOptions();
    await _applyToTtsEngine();
    notifyListeners();
  }

  Future<void> _initializeTtsAndFetchOptions() async {
    _flutterTts.setCompletionHandler(() {});
    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
    });

    await _fetchAvailableLanguagesFromTts();
    await _fetchAvailableVoicesFromTts();

    if (!_availableLanguages.contains(_language) && _availableLanguages.isNotEmpty) {
      _language = _availableLanguages.first;
    }
    if (!_voiceDisplayNames.contains(_voice) && _voiceDisplayNames.isNotEmpty) {
      _voice = _voiceDisplayNames.first;
    }
  }

  Future<void> _fetchAvailableLanguagesFromTts() async {
    try {
      dynamic languages = await _flutterTts.getLanguages;
      if (languages != null && languages is List && languages.isNotEmpty) {
        _availableLanguages = languages.map((lang) {
          if (lang is String) return lang;
          if (lang is Map && lang.containsKey('name') && lang.containsKey('code')) {
            return "${lang['name']} (${lang['code']})";
          }
          if (lang is Map && lang.containsKey('display_name') && lang.containsKey('iso3_language')) {
            return "${lang['display_name']} (${lang['iso3_language']})";
          }
          return lang.toString();
        }).toSet().toList();
        _availableLanguages.sort();
      } else {
        _availableLanguages = ["English (US)"];
      }
    } catch (e) {
      print("Error fetching TTS languages: $e");
      _availableLanguages = ["English (US)"];
    }
  }

  Future<void> _fetchAvailableVoicesFromTts() async {
    try {
      dynamic voices = await _flutterTts.getVoices;
      if (voices != null && voices is List && voices.isNotEmpty) {
        _rawAvailableVoices = List<Map<String, String>>.from(
            voices.map((v) => Map<String, String>.from(v as Map)));
        _voiceDisplayNames = _rawAvailableVoices
            .map((v) => "${v['name']} (${v['locale']})")
            .toSet().toList();
        _voiceDisplayNames.sort();

        if(_voiceDisplayNames.isEmpty && _rawAvailableVoices.isNotEmpty){
          _voiceDisplayNames = _rawAvailableVoices.map((v) => v['name'] ?? 'Unknown Voice').toSet().toList();
          _voiceDisplayNames.sort();
        }

      } else {
        _voiceDisplayNames = ["Achernar"];
        _rawAvailableVoices = [];
      }
    } catch (e) {
      print("Error fetching TTS voices: $e");
      _voiceDisplayNames = ["Achernar"];
      _rawAvailableVoices = [];
    }
    if (_voiceDisplayNames.isEmpty) _voiceDisplayNames = ["Achernar"];
  }

  Future<void> _applyToTtsEngine() async {
    try {
      String langCodeToSet = _language;
      if (_language.contains("(") && _language.endsWith(")")) {
        final startIndex = _language.lastIndexOf("(");
        langCodeToSet = _language.substring(startIndex + 1, _language.length - 1);
      }
      await _flutterTts.setLanguage(langCodeToSet);

      if (_voice != "Achernar" && _voice != "Default" && _rawAvailableVoices.isNotEmpty) {
        final selectedVoiceData = _rawAvailableVoices.firstWhere(
                (v) => "${v['name']} (${v['locale']})" == _voice,
            orElse: () => _rawAvailableVoices.firstWhere(
                  (v) => v['name'] == _voice,
              orElse: () => {},
            )
        );
        if (selectedVoiceData.isNotEmpty) {
          await _flutterTts.setVoice(selectedVoiceData);
        }
      }

      await _flutterTts.setVolume(_appVolume / 100.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);

    } catch (e) {
      print("Error applying settings to TTS engine: $e");
    }
  }

  void setColorScheme(ColorSchemeOption scheme) {
    _colorScheme = scheme;
    _saveSettings();
    notifyListeners();
  }

  void setCycleSpeed(double speed) {
    _cycleSpeed = speed;
    _saveSettings();
    notifyListeners();
  }

  Future<void> setLanguage(String langDisplayName) async {
    _language = langDisplayName;
    await _applyToTtsEngine();
    _saveSettings();
    notifyListeners();
  }

  Future<void> setVoice(String voiceDisplayName) async {
    _voice = voiceDisplayName;
    await _applyToTtsEngine();
    _saveSettings();
    notifyListeners();
  }

  Future<void> setAppVolume(double volume) async {
    _appVolume = volume.clamp(0.0, 100.0);
    await _flutterTts.setVolume(_appVolume / 100.0);
    _saveSettings();
    notifyListeners();
  }

  void setCustomPhrases(List<String> phrases) {
    _customPhrases = phrases;
    _saveSettings();
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorScheme', _colorScheme.index);
    await prefs.setDouble('cycleSpeed', _cycleSpeed);
    await prefs.setString('language', _language);
    await prefs.setString('voice', _voice);
    await prefs.setDouble('appVolume', _appVolume);
    await prefs.setStringList('customPhrases', _customPhrases);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _colorScheme = ColorSchemeOption.values[prefs.getInt('colorScheme') ?? ColorSchemeOption.light.index];
    _cycleSpeed = prefs.getDouble('cycleSpeed') ?? 1.0;
    _language = prefs.getString('language') ?? "English (US)";
    _voice = prefs.getString('voice') ?? "Achernar";
    _appVolume = prefs.getDouble('appVolume') ?? 50.0;
    _customPhrases = prefs.getStringList('customPhrases') ??
        [
          "Legally blind.",
          "Hearing impairment.",
          "Mask required before entering.",
          "Mobility assistance required.",
          "NPO — nothing by mouth.",
          "On insulin / diabetic.",
          "Has allergies; check chart.",
          "Isolation precautions required.",
          "Do not resuscitate (DNR).",
          "Service animal present.",
          "InformER is very helpful!",
        ];
  }
}
