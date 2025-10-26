import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'accessibility_settings_provider.dart';
import 'accessibility.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> with SingleTickerProviderStateMixin {

  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _scrollTimer;
  double _currentPageValue = 0.0;
  Timer? _inactivityTimer;
  AnimationController? _loadingAnimationController;
  Animation<double>? _loadingAnimation;

  bool _isSaying = false;
  late FlutterTts _flutterTts;
  bool _isTtsInitializedAndConfigured = false;

  List<String> _currentPhrases = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.33,
    );
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPageValue = _pageController.page!;
        });
      }
    });

    _flutterTts = FlutterTts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPhrasesAndSetup();
      }
    });

    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(_loadingAnimationController!)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _resetToCycling();
        }
      });
  }

  Future<void> _loadPhrasesAndSetup() async {
    if (!mounted) return;
    final settings = Provider.of<AccessibilitySettingsProvider>(context, listen: false);

    _currentPhrases = List<String>.from(settings.customPhrases);

    if (_currentPhrases.isEmpty) {
      _currentPhrases = ["No phrases configured."];
    }

    _currentIndex = _currentPhrases.length * 1000;
    _currentPageValue = _currentIndex.toDouble();

    _pageController.dispose();
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.33,
    );
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPageValue = _pageController.page!;
        });
      }
    });

    await _setupTtsAndStartScroll();
  }


  Future<void> _setupTtsAndStartScroll() async {
    if (!mounted) return;
    final settings = Provider.of<AccessibilitySettingsProvider>(context, listen: false);

    String langCode = settings.language;
    if (settings.language.contains("(") && settings.language.endsWith(")")) {
      final startIndex = settings.language.lastIndexOf("(");
      langCode = settings.language.substring(startIndex + 1, settings.language.length - 1);
    }
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.setVolume(settings.appVolume / 100.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    if (settings.voice != "Achernar" && settings.voice != "Default" && settings.rawAvailableVoices.isNotEmpty) {
      final selectedVoiceData = settings.rawAvailableVoices.firstWhere(
            (v) => "${v['name']} (${v['locale']})" == settings.voice,
        orElse: () => settings.rawAvailableVoices.firstWhere(
              (v) => v['name'] == settings.voice,
          orElse: () => {},
        ),
      );
      if (selectedVoiceData.isNotEmpty) {
        await _flutterTts.setVoice(selectedVoiceData);
      }
    }

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        print("TTS Error on AppScreen: $msg");
        _resetToCycling();
      }
    });

    _isTtsInitializedAndConfigured = true;
    if (_currentPhrases.isNotEmpty && _currentPhrases.first != "No phrases configured.") {
      _startAutoScroll();
    }
  }

  Future<void> _speak(String text) async {
    if (!mounted || !_isTtsInitializedAndConfigured || text.isEmpty || text == "No phrases configured.") return;

    final settings = Provider.of<AccessibilitySettingsProvider>(context, listen: false);
    String langCode = settings.language;
    if (settings.language.contains("(") && settings.language.endsWith(")")) {
      final startIndex = settings.language.lastIndexOf("(");
      langCode = settings.language.substring(startIndex + 1, settings.language.length - 1);
    }
    await _flutterTts.setLanguage(langCode);
    await _flutterTts.setVolume(settings.appVolume / 100.0);
    if (settings.voice != "Achernar" && settings.voice != "Default" && settings.rawAvailableVoices.isNotEmpty) {
      final selectedVoiceData = settings.rawAvailableVoices.firstWhere(
              (v) => "${v['name']} (${v['locale']})" == settings.voice,
          orElse: () => settings.rawAvailableVoices.firstWhere(
                (v) => v['name'] == settings.voice,
            orElse: () => {},
          )
      );
      if (selectedVoiceData.isNotEmpty) {
        await _flutterTts.setVoice(selectedVoiceData);
      }
    }
    await _flutterTts.speak(text);
  }

  void _startAutoScroll() {
    if (!mounted || _isSaying || !_isTtsInitializedAndConfigured || _currentPhrases.isEmpty || _currentPhrases.first == "No phrases configured.") return;
    final settings = Provider.of<AccessibilitySettingsProvider>(context, listen: false);
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(Duration(milliseconds: (2500 / settings.cycleSpeed).round()), (timer) {
      if (_pageController.hasClients && mounted && !_isSaying) {
        _currentIndex++;
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      } else if (_isSaying || !mounted) {
        timer.cancel();
      }
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _loadingAnimationController?.reset();
    if (mounted && _isSaying) {
      _loadingAnimationController?.forward();
    }
    _inactivityTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isSaying) {
        _resetToCycling();
      }
    });
  }

  void _resetToCycling() {
    if (mounted) {
      _flutterTts.stop();
      _inactivityTimer?.cancel();
      _loadingAnimationController?.reset();
      if (_isSaying) {
        setState(() {
          _isSaying = false;
        });
      }
      if (_currentPhrases.isNotEmpty && _currentPhrases.first != "No phrases configured.") {
        _startAutoScroll();
      }
    }
  }

  void _handleScreenTap() {
    if (!mounted || !_isTtsInitializedAndConfigured || _currentPhrases.isEmpty) return;

    final String currentMessage = _currentPhrases[_currentIndex % _currentPhrases.length];
    if (currentMessage == "No phrases configured.") return;

    if (_isSaying) {
      _flutterTts.stop();
      _speak(currentMessage);
      _resetInactivityTimer();
    } else {
      setState(() {
        _isSaying = true;
      });
      _scrollTimer?.cancel();
      _speak(currentMessage);
      _resetInactivityTimer();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollTimer?.cancel();
    _inactivityTimer?.cancel();
    _loadingAnimationController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AccessibilitySettingsProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (!listEquals(_currentPhrases, settings.customPhrases)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print("Custom phrases changed, reloading...");
          _isSaying = false;
          _flutterTts.stop();
          _scrollTimer?.cancel();
          _inactivityTimer?.cancel();
          _loadingAnimationController?.reset();
          _isTtsInitializedAndConfigured = false;
          _loadPhrasesAndSetup();
        }
      });
    }

    if (_currentPhrases.isEmpty) {
      _currentPhrases = ["No phrases available."];
    }

    final String currentMessage = _currentPhrases.isNotEmpty
        ? _currentPhrases[_currentIndex % _currentPhrases.length]
        : "Loading phrases...";

    final bool canInteract = _currentPhrases.isNotEmpty && _currentPhrases.first != "No phrases configured." && _currentPhrases.first != "No phrases available.";

    const goldColor = Color(0xFFF1C232);

    return Semantics(
      label: _isSaying ? "Speaking: $currentMessage. Tap to speak again." : "Tap to speak: $currentMessage. Current cycle speed: ${settings.cycleSpeed}x",
      hint: _isSaying ? "Will return to cycling messages after a short period." : "Cycles through messages. Tap screen to select and say the displayed message.",
      button: true,
      excludeSemantics: false,
      child: GestureDetector(
        onTap: canInteract ? _handleScreenTap : null,
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  settings.backgroundImage,
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Semantics(
                              label: "Settings",
                              hint: "Opens accessibility settings screen",
                              button: true,
                              child: IconButton(
                                icon: Icon(
                                  Icons.settings,
                                  color: settings.primaryTextColor,
                                  size: 50,
                                ),
                                onPressed: () async {
                                  _scrollTimer?.cancel();
                                  await _flutterTts.stop();
                                  if (mounted) {
                                    setState(() {
                                      _isSaying = false;
                                    });
                                    _loadingAnimationController?.reset();
                                    _inactivityTimer?.cancel();
                                  }

                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AccessibilityScreen()),
                                  );
                                  if(mounted) {
                                    _isTtsInitializedAndConfigured = false;
                                    _loadPhrasesAndSetup();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Semantics(
                              label: "Go Back",
                              hint: "Returns to the previous screen",
                              button: true,
                              child: IconButton(
                                icon: Icon(
                                  Icons.home,
                                  color: settings.primaryTextColor,
                                  size: 50,
                                ),
                                onPressed: () {
                                  _resetToCycling();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                          builder: (context, constraints) {
                            final topSectionHeight = constraints.maxHeight * 0.35;
                            final middleSectionHeight = constraints.maxHeight * 0.30;
                            final bottomSectionHeight = constraints.maxHeight * 0.35;
                            final clickToSayFontSize = 24.0;

                            return Semantics(
                              liveRegion: true,
                              label: _isSaying ? "Saying: $currentMessage" : "Displaying: $currentMessage",
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    height: topSectionHeight,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (_isSaying)
                                          Text(
                                            "SAYING",
                                            style: GoogleFonts.dmSans(
                                              fontSize: clickToSayFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: settings.borderColor,
                                            ),
                                          )
                                        else if (canInteract)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/clickicon.png',
                                                height: clickToSayFontSize,
                                                semanticLabel: "",
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "CLICK TO SAY",
                                                style: GoogleFonts.dmSans(
                                                  fontSize: clickToSayFontSize,
                                                  fontWeight: FontWeight.bold,
                                                  color: settings.borderColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                                          child: Text(
                                            currentMessage,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 70,
                                              fontWeight: FontWeight.bold,
                                              color: _isSaying ? settings.borderColor : goldColor,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                        if (_isSaying) ...[
                                          const SizedBox(height: 15),
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircularProgressIndicator(
                                              value: _loadingAnimation?.value ?? 0.0,
                                              strokeWidth: 5,
                                              valueColor: const AlwaysStoppedAnimation<Color>(goldColor),
                                              backgroundColor: settings.borderColor.withOpacity(0.3),
                                              semanticsLabel: "Saying progress",
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/clickicon.png',
                                                height: clickToSayFontSize * 0.8,
                                                semanticLabel: "",
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "CLICK TO SAY AGAIN",
                                                style: GoogleFonts.dmSans(
                                                  fontSize: clickToSayFontSize * 0.8,
                                                  fontWeight: FontWeight.bold,
                                                  color: settings.borderColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                  if (!_isSaying && canInteract)
                                    SizedBox(
                                      height: middleSectionHeight,
                                      child: Center(
                                        child: SizedBox(
                                          height: screenHeight * 0.18,
                                          child: Semantics(
                                            label: "Available messages to select. Currently displaying options.",
                                            child: PageView.builder(
                                              controller: _pageController,
                                              physics: _isSaying ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
                                              itemCount: _currentPhrases.isNotEmpty ? null : 0,
                                              itemBuilder: (context, index) {
                                                if (_currentPhrases.isEmpty) return const SizedBox.shrink();

                                                final itemIndex = index % _currentPhrases.length;
                                                final message = _currentPhrases[itemIndex];

                                                double scale = 1.0;
                                                double opacity = 1.0;
                                                double difference = index - _currentPageValue;

                                                if (difference.abs() >= 0 && difference.abs() < 1) {
                                                  scale = 1.0 - difference.abs() * 0.2;
                                                  opacity = 1.0 - difference.abs() * 0.4;
                                                } else if (difference.abs() >= 1 && difference.abs() < 2) {
                                                  scale = 0.8 - (difference.abs() -1) * 0.2;
                                                  opacity = 0.6 - (difference.abs()-1) * 0.3;
                                                } else {
                                                  scale = 0.6;
                                                  opacity = 0.3;
                                                }
                                                scale = scale.clamp(0.6, 1.0);
                                                opacity = opacity.clamp(0.3, 1.0);

                                                return ExcludeSemantics(
                                                  excluding: (difference.abs() > 0.5),
                                                  child: Transform.scale(
                                                    scale: scale,
                                                    child: Opacity(
                                                      opacity: opacity,
                                                      child: Center(
                                                        child: Container(
                                                          width: screenWidth * 0.38,
                                                          height: screenHeight * 0.15,
                                                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                                          decoration: BoxDecoration(
                                                            color: settings.colorScheme == ColorSchemeOption.light
                                                                ? Colors.white
                                                                : settings.buttonBackgroundColor,
                                                            borderRadius: BorderRadius.circular(25),
                                                            border: Border.all(
                                                              color: settings.borderColor,
                                                              width: 4,
                                                            ),
                                                          ),
                                                          child: Center(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(10.0),
                                                              child: FittedBox(
                                                                fit: BoxFit.scaleDown,
                                                                child: Text(
                                                                  message,
                                                                  textAlign: TextAlign.center,
                                                                  style: GoogleFonts.dmSans(
                                                                    fontSize: 40,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: settings.borderColor,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    SizedBox(height: middleSectionHeight),
                                  SizedBox(height: bottomSectionHeight),
                                ],
                              ),
                            );
                          }
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
