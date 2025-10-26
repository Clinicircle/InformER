import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'accessibility_settings_provider.dart';

String? _apiKey;

class FreddieScreen extends StatefulWidget {
  final String userName;
  final String institutionName;
  final String sessionId;
  final String hashedInstitutionCode;

  const FreddieScreen({
    super.key,
    required this.userName,
    required this.institutionName,
    required this.sessionId,
    required this.hashedInstitutionCode,
  });

  @override
  State<FreddieScreen> createState() => _FreddieScreenState();
}

class _FreddieScreenState extends State<FreddieScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _canSend = false;
  GenerativeModel? _model;
  ChatSession? _chat;
  final List<MessageBubble> _messages = [];
  bool _isLoading = false;
  String? _systemPrompt;
  bool _isFirstMessageSent = false;
  final ScrollController _scrollController = ScrollController();
  bool _isApiKeyLoaded = false;

  final List<String> _suggestions = [
    "How can I log out of my current session?",
    "How can I contact InformER?",
    "What screen-editing tools are available?"
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKeyAndInitChat();
    _textController.addListener(() {
      setState(() {
        _canSend = _textController.text.isNotEmpty;
      });
    });
  }

  Future<void> _loadApiKeyAndInitChat() async {
    try {
      _apiKey = (await rootBundle.loadString('assets/gemini/API_KEY')).trim();
      _systemPrompt =
      await rootBundle.loadString('assets/gemini/gemini_prompt.txt');

      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception(
            "API Key not found or is empty in assets/gemini/API_KEY");
      }

      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey!,
      );
      _chat = _model!.startChat(history: [
        Content.model([TextPart("Hi, I'm Freddie!")])
      ]);
      if (mounted) {
        setState(() {
          _isApiKeyLoaded = true;
          _messages.add(MessageBubble(text: "Hi, I'm Freddie!", isUser: false));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isApiKeyLoaded = false;
          _messages.add(MessageBubble(
              text:
              "Error loading API key, system prompt or initializing chat: $e",
              isUser: false));
        });
      }
      print("Error in _loadApiKeyAndInitChat: $e");
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    if (!_isApiKeyLoaded || _systemPrompt == null || _chat == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Chat not initialized. Check API Key and prompt loading.")));
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _messages.add(MessageBubble(text: message, isUser: true));
        _isFirstMessageSent = true;
      });
    }
    _textController.clear();
    setState(() {
      _canSend = false;
    });
    _scrollToBottom();

    try {
      final currentTurnPrompt = _systemPrompt!
          .replaceFirst('{{USER_PROMPT}}', message)
          .replaceFirst(
          '{{CONVERSATION}}', _buildConversationHistoryForPrompt());

      final response =
      await _chat!.sendMessage(Content.text(currentTurnPrompt));
      final text = response.text?.trim();

      if (mounted) {
        setState(() {
          if (text != null && text.isNotEmpty) {
            _messages.add(MessageBubble(text: text, isUser: false));
          } else {
            _messages.add(MessageBubble(
                text: "No response from Freddie or empty response.",
                isUser: false));
          }
          _isLoading = false;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
              MessageBubble(text: "Error sending message: $e", isUser: false));
          _isLoading = false;
        });
      }
      print("Error in _sendMessage: $e");
      _scrollToBottom();
    }
  }

  String _buildConversationHistoryForPrompt() {
    StringBuffer history = StringBuffer();
    List<MessageBubble> historyForPrompt = List.from(_messages);
    if (historyForPrompt.isNotEmpty && historyForPrompt.last.isUser) {
      historyForPrompt.removeLast();
    }

    bool firstUserMessageFound = false;
    for (int i = 0; i < historyForPrompt.length; i++) {
      final msg = historyForPrompt[i];
      if (msg.text == "Hi, I'm Freddie!" && !msg.isUser && i == 0) {
        history.writeln("You: ${msg.text}");
        continue;
      }
      if (msg.isUser) {
        firstUserMessageFound = true;
        history.writeln("User: ${msg.text}");
      } else if (firstUserMessageFound) {
        history.writeln("You: ${msg.text}");
      }
    }
    return history.toString().trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showFreddieInfoPopup(BuildContext context) {
    final settings =
    Provider.of<AccessibilitySettingsProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double popupBorderThickness = 8.0;

    final double imageHeight = screenHeight * 0.25;
    final double imageAspectRatio = 819 / 1024;
    final double imageWidth = imageHeight * imageAspectRatio;

    final paragraphStyle = GoogleFonts.dmSans(
      fontSize: 17,
      fontWeight: FontWeight.bold,
      color: settings.primaryTextColor,
      height: 1.5,
    );

    const String p1 =
    """Freddie Taylor was the heart behind ICUSpeak. A patient at UF Shands Heart and Vascular, he went through the tremendous ordeal of not being able to speak during and after his surgery, with hand gestures being the only way he could communicate with his family members and doctors.""";
    const String p2 =
    """His experience was what gave rise to ICUSpeak, an app that bridges the communication gap for post-operative patients.\n\nInfluenced by Freddie's experience, brothers Aarin and Aarav Dave developed ICUSpeak with the goal of empowering patients like Freddie who have been rendered voiceless during moments of crisis. Freddie's resolve and courage guided not only the development of the""";
    const String p3 =
    """app but also led to its Congressional App Challenge success.\n\nThough Freddie has passed away, his legacy remains. The AI assistant for all Clinicircle apps is named “Freddie” and is meant to carry forward his empathy, strength, and optimism to offer support to those suffering from the same silence as he once did. Every time our apps help a patient express their needs, Freddie's story lives on.""";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06, vertical: screenHeight * 0.04),
          child: Container(
            width: screenWidth * 0.88,
            height: screenHeight * 0.85,
            padding: const EdgeInsets.all(popupBorderThickness + 40),
            decoration: BoxDecoration(
              color: settings.buttonBackgroundColor,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: settings.borderColor,
                width: popupBorderThickness,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 30.0),
                  child: Text(
                    "About Freddie Taylor",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: settings.primaryTextColor,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p1, style: paragraphStyle),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  right: 20.0, top: 6.0, bottom: 12.0),
                              child: Container(
                                width: imageWidth,
                                height: imageHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: settings.borderColor,
                                    width: popupBorderThickness,
                                  ),
                                  image: const DecorationImage(
                                    image: AssetImage(
                                        'assets/images/freddiepicture.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(p2, style: paragraphStyle),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(p3, style: paragraphStyle),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30.0, bottom: 24.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: settings.primaryTextColor,
                        foregroundColor: settings.buttonBackgroundColor,
                        minimumSize: Size(screenWidth * 0.4, 55),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 20),
                        textStyle: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Close"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChip(
      String text, AccessibilitySettingsProvider settings) {
    return GestureDetector(
      onTap: () {
        if (_isApiKeyLoaded && !_isLoading) {
          _sendMessage(text);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            color: settings.primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AccessibilitySettingsProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final double sendBarHorizontalPadding = screenWidth * 0.08;

    Color placeholderColor =
    settings.colorScheme == ColorSchemeOption.highContrast
        ? Colors.black
        : const Color(0xFFD9D9D9);

    Color sendButtonColor = _canSend ? Colors.black : placeholderColor;

    Color freddieIconBorderColor =
    settings.colorScheme == ColorSchemeOption.highContrast
        ? const Color(0xFFFFFF00)
        : settings.borderColor;

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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.home,
                        color: settings.primaryTextColor,
                        size: 50,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                if (!_isFirstMessageSent && _isApiKeyLoaded)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: screenWidth * 0.2,
                              height: screenWidth * 0.2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: freddieIconBorderColor,
                                  width: 7.0,
                                ),
                                image: const DecorationImage(
                                  image: AssetImage(
                                      'assets/images/freddieicon.jpg'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              "Hi, I’m Freddie!",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 75,
                                fontWeight: FontWeight.bold,
                                color: settings.primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            InkWell(
                              onTap: () {
                                _showFreddieInfoPopup(context);
                              },
                              child: Text(
                                "Learn more about my name →",
                                style: GoogleFonts.dmSans(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: settings.primaryTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_isFirstMessageSent ||
                    (!_isFirstMessageSent && _messages.isNotEmpty))
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                          horizontal: sendBarHorizontalPadding,
                          vertical: 16.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return Align(
                          alignment: message.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: screenWidth -
                                  (sendBarHorizontalPadding * 2) -
                                  16,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 5.0),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 18.0),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? const Color(0xFF199FF1)
                                  : (message.text.startsWith("Error")
                                  ? Colors.redAccent.withOpacity(0.8)
                                  : const Color(0xFF999999)),
                              borderRadius: BorderRadius.circular(22.0),
                            ),
                            child: Text(
                              message.text,
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : _messages.isNotEmpty
                          ? Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _messages.first.text,
                          style: GoogleFonts.dmSans(
                              color: Colors.red, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                      )
                          : const CircularProgressIndicator(),
                    ),
                  ),
                if (!_isFirstMessageSent && _isApiKeyLoaded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0, top: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _suggestions
                          .map((suggestion) => Flexible(
                        child: Container(
                          width: screenWidth / 3.5,
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: _buildSuggestionChip(suggestion, settings),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                      left: sendBarHorizontalPadding,
                      right: sendBarHorizontalPadding,
                      bottom: _isFirstMessageSent
                          ? 20.0
                          : (_isApiKeyLoaded ? 20.0 : 60.0),
                      top: _isFirstMessageSent
                          ? 20.0
                          : (_isApiKeyLoaded ? 0.0 : 20.0)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 25.0),
                                child: TextField(
                                  controller: _textController,
                                  enabled: _isApiKeyLoaded,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _isApiKeyLoaded
                                        ? "Ask anything..."
                                        : "Loading Freddie...",
                                    hintStyle: GoogleFonts.dmSans(
                                      color: placeholderColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: _isApiKeyLoaded &&
                                      _canSend &&
                                      !_isLoading
                                      ? (text) => _sendMessage(text)
                                      : null,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _isLoading
                                  ? const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.black,
                                  ),
                                ),
                              )
                                  : IconButton(
                                icon: Icon(
                                  Icons.send,
                                  color: sendButtonColor,
                                  size: 36,
                                ),
                                onPressed: _isApiKeyLoaded &&
                                    _canSend &&
                                    !_isLoading
                                    ? () =>
                                    _sendMessage(_textController.text)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isFirstMessageSent)
                        Padding(
                          padding:
                          const EdgeInsets.only(top: 12.0, bottom: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  color: settings.primaryTextColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "Information provided may be inaccurate.",
                                style: GoogleFonts.dmSans(
                                  color: settings.primaryTextColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble {
  final String text;
  final bool isUser;

  MessageBubble({required this.text, required this.isUser});
}
