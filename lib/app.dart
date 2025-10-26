// app.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'accessibility_settings_provider.dart';

class BoardElement {
  final String label;
  final IconData icon;
  bool active;
  BoardElement({required this.label, required this.icon, this.active = false});
}

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  // Local patient state (no extra provider required)
  String _patientName = 'JOHN DOE';
  String _patientId = 'MRN: 123456';
  bool _editingName = false;
  final TextEditingController _nameController = TextEditingController();

  // Built-in preset elements
  final List<BoardElement> _presets = [
    BoardElement(label: 'Legally blind', icon: Icons.visibility_off),
    BoardElement(label: 'Allergic: Penicillin', icon: Icons.warning_amber_rounded),
    BoardElement(label: 'NPO', icon: Icons.no_food),
    BoardElement(label: 'Mask required', icon: Icons.masks),
    BoardElement(label: 'Fall risk', icon: Icons.warning),
    BoardElement(label: 'DNR', icon: Icons.do_not_disturb_on),
    BoardElement(label: 'Needs translator', icon: Icons.language),
    BoardElement(label: 'Cannot consent', icon: Icons.gavel),
  ];

  // Custom messages created at runtime
  final List<BoardElement> _customMessages = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = _patientName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleElement(BoardElement element) {
    setState(() => element.active = !element.active);
  }

  void _addCustomMessage(String text, {IconData? icon}) {
    setState(() => _customMessages.insert(0, BoardElement(label: text.trim(), icon: icon ?? Icons.note, active: true)));
  }

  void _removeCustomMessage(BoardElement element) {
    setState(() => _customMessages.remove(element));
  }

  void _setPatientName(String name) {
    setState(() {
      _patientName = name.trim().isEmpty ? 'UNKNOWN' : name.toUpperCase();
      _nameController.text = _patientName;
      _editingName = false;
    });
  }

  List<BoardElement> get _activeElements => [
    ..._presets.where((p) => p.active),
    ..._customMessages.where((c) => c.active),
  ];

  Future<void> _showAddCustomDialog(BuildContext context, Color accentColor, TextStyle hintStyle) async {
    final TextEditingController ctrl = TextEditingController();
    IconData selectedIcon = Icons.note;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          contentPadding: const EdgeInsets.all(0),
          content: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add custom message', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Service animal present',
                    hintStyle: hintStyle,
                    border: const OutlineInputBorder(borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white10,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _iconOption(Icons.note, selectedIcon, () => setState(() => selectedIcon = Icons.note), accentColor),
                    _iconOption(Icons.pets, selectedIcon, () => setState(() => selectedIcon = Icons.pets), accentColor),
                    _iconOption(Icons.medical_services, selectedIcon, () => setState(() => selectedIcon = Icons.medical_services), accentColor),
                    _iconOption(Icons.healing, selectedIcon, () => setState(() => selectedIcon = Icons.healing), accentColor),
                    _iconOption(Icons.masks, selectedIcon, () => setState(() => selectedIcon = Icons.masks), accentColor),
                    _iconOption(Icons.visibility_off, selectedIcon, () => setState(() => selectedIcon = Icons.visibility_off), accentColor),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                      onPressed: () {
                        final text = ctrl.text.trim();
                        if (text.isNotEmpty) _addCustomMessage(text, icon: selectedIcon);
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Add'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _iconOption(IconData icon, IconData selected, VoidCallback onTap, Color accentColor) {
    final bool active = icon == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? accentColor : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: active ? Colors.black : Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AccessibilitySettingsProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Accent color derived from provider (sliderActiveColor works well as a visible accent)
    final Color accentColor = settings.sliderActiveColor;
    final Color primaryText = settings.primaryTextColor;
    final Color borderColor = settings.borderColor;
    final Color cardBg = settings.buttonBackgroundColor;
    final TextStyle hintStyle = TextStyle(color: settings.secondaryTextColor.withOpacity(0.7));

    // If provider offers images, use them as background/logo
    final Widget background = settings.backgroundImage.isNotEmpty
        ? Positioned.fill(child: Image.asset(settings.backgroundImage, fit: BoxFit.cover))
        : const SizedBox.shrink();

    return Scaffold(
      body: Stack(
        children: [
          background,
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  // Compact header: home/back + logo (no label text)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back_ios, color: primaryText),
                        tooltip: 'Back',
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Controls pane
                        Flexible(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Patient name card
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 3),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _editingName
                                          ? TextField(
                                        controller: _nameController,
                                        autofocus: true,
                                        style: GoogleFonts.dmSans(fontSize: 26, color: primaryText),
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        onSubmitted: _setPatientName,
                                      )
                                          : Text(_patientName,
                                          style: GoogleFonts.dmSans(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            color: primaryText,
                                            letterSpacing: 1.2,
                                          )),
                                    ),
                                    IconButton(
                                      icon: Icon(_editingName ? Icons.check : Icons.edit, color: primaryText),
                                      onPressed: () {
                                        if (_editingName) {
                                          _setPatientName(_nameController.text);
                                        } else {
                                          setState(() => _editingName = true);
                                        }
                                      },
                                      tooltip: _editingName ? 'Save name' : 'Edit name',
                                    )
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              Text('Preset items',
                                  style: GoogleFonts.dmSans(fontSize: 14, color: settings.secondaryTextColor)),

                              const SizedBox(height: 8),

                              Expanded(
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: _presets.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (ctx, idx) {
                                    final el = _presets[idx];
                                    return GestureDetector(
                                      onTap: () => _toggleElement(el),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 220),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: el.active ? accentColor : Colors.white10,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: borderColor, width: 3),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(el.icon, color: el.active ? Colors.black : primaryText, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                el.label,
                                                style: GoogleFonts.dmSans(
                                                  fontWeight: FontWeight.w700,
                                                  color: el.active ? Colors.black : primaryText,
                                                ),
                                              ),
                                            ),
                                            Switch(value: el.active, onChanged: (_) => _toggleElement(el)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showAddCustomDialog(context, accentColor, hintStyle),
                                    icon: Icon(Icons.add, color: settings.primaryTextColor),
                                    label: Text('Add', style: GoogleFonts.dmSans(color: settings.primaryTextColor),),
                                    style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        for (var e in _presets) e.active = false;
                                        for (var c in _customMessages) c.active = false;
                                      });
                                    },
                                    icon:  Icon(Icons.clear_all, color: settings.secondaryTextColor,),
                                    label: Text('Clear active', style: GoogleFonts.dmSans(color: settings.secondaryTextColor)),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: borderColor, width: 2),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        const SizedBox(width: 18),

                        // Board preview
                        Flexible(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 3),
                            ),
                            child: Column(
                              children: [
                                // Large patient name area (center)
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderColor.withOpacity(0.6), width: 2),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                _patientName,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 110,
                                                  fontWeight: FontWeight.w900,
                                                  color: primaryText,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Active elements shown as chips using accent color
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          alignment: WrapAlignment.center,
                                          children: _activeElements.isNotEmpty
                                              ? _activeElements
                                              .map(
                                                (e) => Chip(
                                              avatar: Icon(e.icon, size: 18, color: Colors.black),
                                              label: Text(e.label,
                                                  style: GoogleFonts.dmSans(
                                                      fontSize: 14, fontWeight: FontWeight.w700)),
                                              backgroundColor: accentColor,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            ),
                                          )
                                              .toList()
                                              : [
                                            Chip(
                                              label: Text('No active items',
                                                  style: GoogleFonts.dmSans(color: Colors.black)),
                                              backgroundColor: Colors.white12,
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Custom messages horizontal list
                                SizedBox(
                                  height: 110,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Custom messages', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: primaryText)),
                                          Text('${_customMessages.length} total', style: TextStyle(color: settings.secondaryTextColor)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: _customMessages.isEmpty
                                            ? Center(child: Text('No custom messages.', style: TextStyle(color: settings.secondaryTextColor)))
                                            : ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _customMessages.length,
                                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                                          itemBuilder: (_, idx) {
                                            final custom = _customMessages[idx];
                                            return GestureDetector(
                                              onTap: () => _toggleElement(custom),
                                              child: Container(
                                                width: 220,
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: custom.active ? accentColor : Colors.white10,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: borderColor, width: 2),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(custom.icon, color: custom.active ? Colors.black : primaryText),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(custom.label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: custom.active ? Colors.black : primaryText))),
                                                    IconButton(icon: Icon(Icons.delete_outline, color: primaryText), onPressed: () => _removeCustomMessage(custom)),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
