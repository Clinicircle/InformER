import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'accessibility_settings_provider.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  List<String> _phrases = [];
  int? _selectedIndex;
  bool _isEditing = false;
  final TextEditingController _editingController = TextEditingController();
  final FocusNode _editingFocusNode = FocusNode();
  bool _showHelperText = true;
  final GlobalKey _listKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<AccessibilitySettingsProvider>(context, listen: false);
      setState(() {
        _phrases = List<String>.from(settings.customPhrases);
      });
    });
  }

  ButtonStyle _pageButtonStyle(
      double screenHeight,
      double buttonWidth,
      AccessibilitySettingsProvider settings, {
        Color? specificBackgroundColor,
      }) {
    return OutlinedButton.styleFrom(
      side: const BorderSide(color: Colors.black, width: 2),
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

  Widget _buildIconButton(
      IconData icon, VoidCallback onPressed, AccessibilitySettingsProvider settings) {
    return IconButton(
      icon: Icon(icon, color: settings.primaryTextColor, size: 28),
      onPressed: onPressed,
      padding: const EdgeInsets.all(12.0),
      constraints: const BoxConstraints(),
    );
  }

  void _savePhrasesToProvider() {
    final settings = Provider.of<AccessibilitySettingsProvider>(context, listen: false);
    settings.setCustomPhrases(List<String>.from(_phrases));
  }

  void _startEditing(int? index, {bool isNew = false}) {
    setState(() {
      _isEditing = true;
      _selectedIndex = index;
      _showHelperText = false;
      if (isNew) {
        _editingController.text = "";
        final newPhrase = "";
        if (_phrases.isEmpty || index == null || index >= _phrases.length -1) {
          _phrases.add(newPhrase);
          _selectedIndex = _phrases.length - 1;
        } else {
          _phrases.insert(index + 1, newPhrase);
          _selectedIndex = index + 1;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_listKey.currentContext != null && _selectedIndex != null) {
            Scrollable.ensureVisible(
              _listKey.currentContext!
                  .findRenderObject()!
                  .getTransformTo(null)
                  .getTranslation() as BuildContext,
              duration: const Duration(milliseconds: 300),
              alignment: 0.5,
            );
          }
        });

      } else if (index != null) {
        _editingController.text = _phrases[index];
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editingFocusNode.requestFocus();
    });
  }

  void _cancelEditing({bool removeNew = false}) {
    final originalText = (_selectedIndex != null && !isNewPhrase()) ? _phrases[_selectedIndex!] : "";
    setState(() {
      _isEditing = false;
      _showHelperText = true;
      if (removeNew && _selectedIndex != null && isNewPhrase() && _editingController.text.isEmpty) {
        _phrases.removeAt(_selectedIndex!);
        _selectedIndex = null;
      } else if (_selectedIndex != null) {
        _editingController.text = originalText;
      }
      if(!removeNew) _selectedIndex = null;
      if(_selectedIndex == null && !removeNew) _editingController.clear();

    });
    _editingFocusNode.unfocus();
  }

  bool isNewPhrase(){
    if(_selectedIndex == null) return false;
    return _phrases[_selectedIndex!].isEmpty && _editingController.text.isEmpty;
  }


  void _saveEditing() {
    if (_selectedIndex != null) {
      setState(() {
        _phrases[_selectedIndex!] = _editingController.text;
        _isEditing = false;
        _showHelperText = true;
      });
      _savePhrasesToProvider();
    }
    _editingFocusNode.unfocus();
  }

  void _deleteSelectedPhrase() {
    if (_selectedIndex != null) {
      setState(() {
        _phrases.removeAt(_selectedIndex!);
        _selectedIndex = null;
        _isEditing = false;
        _showHelperText = true;
      });
      _savePhrasesToProvider();
    }
  }

  @override
  void dispose() {
    _editingController.dispose();
    _editingFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AccessibilitySettingsProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = screenHeight * 0.08;
    final double boxHeight = screenHeight * 0.5;
    final itemWidth = screenWidth * 0.8;
    const double borderWidth = 2.0;

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
                    'Edit Phrase List',
                    style: GoogleFonts.dmSans(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: settings.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Opacity(
                    opacity: _showHelperText ? 1.0 : 0.0,
                    child: Text(
                      'Select a phrase to modify it:',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: settings.primaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: itemWidth,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: borderWidth),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.black, width: borderWidth)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: _isEditing
                                ? [
                              _buildIconButton(Icons.check, _saveEditing, settings),
                              _buildIconButton(Icons.close, () => _cancelEditing(removeNew: true), settings),
                            ]
                                : _selectedIndex != null
                                ? [
                              _buildIconButton(Icons.add, () => _startEditing(_selectedIndex, isNew: true), settings),
                              _buildIconButton(Icons.remove, _deleteSelectedPhrase, settings),
                              _buildIconButton(Icons.edit, () => _startEditing(_selectedIndex), settings),
                            ]
                                : [
                              _buildIconButton(Icons.add, () => _startEditing(null, isNew: true), settings),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: boxHeight - 58 - (borderWidth * 2),
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView.builder(
                              key: _listKey,
                              itemCount: _phrases.length,
                              itemBuilder: (context, index) {
                                final isSelected = _selectedIndex == index;
                                return Material(
                                  color: isSelected ? const Color(0xFFFFD966) : Colors.white,
                                  child: InkWell(
                                    onTap: () {
                                      if (_isEditing && _selectedIndex == index) return;

                                      if (_isEditing) {
                                        _saveEditing();
                                        setState(() {
                                          _selectedIndex = index;
                                          _isEditing = false;
                                          _showHelperText = true;
                                        });
                                      } else {
                                        setState(() {
                                          _selectedIndex = index;
                                          _showHelperText = true;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.black,
                                            width: borderWidth,
                                          ),
                                        ),
                                      ),
                                      child: _isEditing && isSelected
                                          ? TextField(
                                        controller: _editingController,
                                        focusNode: _editingFocusNode,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        maxLines: null,
                                        onSubmitted: (_) => _saveEditing(),
                                      )
                                          : Text(
                                        _phrases.isEmpty || index >= _phrases.length ? "" : _phrases[index],
                                        style: GoogleFonts.dmSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: screenWidth * 0.4,
                        child: OutlinedButton(
                          onPressed: () {
                            if (_isEditing) _saveEditing();
                            _savePhrasesToProvider();
                            Navigator.pop(context);
                          },
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
