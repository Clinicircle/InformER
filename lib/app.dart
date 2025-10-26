// app.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  // Basic patient info stored locally (no Provider)
  String _patientName = 'JOHN DOE';
  String _patientId = 'MRN: 123456';
  bool _editingName = false;
  final TextEditingController _nameController = TextEditingController();

  // Local preset elements frequently useful in ER displays
  final List<BoardElement> _presets = [
    BoardElement(label: 'Legally blind', icon: Icons.visibility_off),
    BoardElement(label: 'Allergic: Penicillin', icon: Icons.warning),
    BoardElement(label: 'NPO', icon: Icons.no_food),
    BoardElement(label: 'Isolation: Mask', icon: Icons.health_and_safety),
    BoardElement(label: 'Fall risk', icon: Icons.warning_amber_rounded),
    BoardElement(label: 'DNR', icon: Icons.favorite_border),
    BoardElement(label: 'Needs translator', icon: Icons.language),
    BoardElement(label: 'Cannot consent', icon: Icons.gavel),
  ];

  // Custom messages the user can add at runtime
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
    setState(() {
      element.active = !element.active;
    });
  }

  void _addCustomMessage(String text, {IconData? icon}) {
    setState(() {
      _customMessages.insert(
          0, BoardElement(label: text.trim(), icon: icon ?? Icons.note, active: true));
    });
  }

  void _removeCustomMessage(BoardElement element) {
    setState(() {
      _customMessages.remove(element);
    });
  }

  void _setPatientName(String name) {
    setState(() {
      _patientName = name.trim().isEmpty ? 'UNKNOWN' : name.toUpperCase();
      _nameController.text = _patientName;
      _editingName = false;
    });
  }

  Future<void> _showAddCustomDialog() async {
    final TextEditingController ctrl = TextEditingController();
    IconData selectedIcon = Icons.note;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0B1220),
          title: Text('Add custom message', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'e.g. Patient uses service animal',
                  hintStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _iconOption(Icons.note, selectedIcon, () => setState(() => selectedIcon = Icons.note)),
                  _iconOption(Icons.pets, selectedIcon, () => setState(() => selectedIcon = Icons.pets)),
                  _iconOption(Icons.medical_services, selectedIcon,
                          () => setState(() => selectedIcon = Icons.medical_services)),
                  _iconOption(Icons.healing, selectedIcon, () => setState(() => selectedIcon = Icons.healing)),
                  _iconOption(Icons.health_and_safety, selectedIcon,
                          () => setState(() => selectedIcon = Icons.health_and_safety)),
                  _iconOption(Icons.visibility_off, selectedIcon,
                          () => setState(() => selectedIcon = Icons.visibility_off)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final text = ctrl.text.trim();
                if (text.isNotEmpty) {
                  _addCustomMessage(text, icon: selectedIcon);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _iconOption(IconData icon, IconData selected, VoidCallback onTap) {
    final active = icon == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF1C232) : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: active ? Colors.black : Colors.white),
      ),
    );
  }

  List<BoardElement> get _activeElements =>
      [..._presets.where((p) => p.active), ..._customMessages.where((c) => c.active)];

  @override
  Widget build(BuildContext context) {
    // Local visual defaults (replace or merge later with your accessibility provider)
    const goldColor = Color(0xFFF1C232);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // simple background gradient; replace with an asset if you wish
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF071027), Color(0xFF091528)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                children: [
                  // header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios),
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text('ER Board', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              final snapshot = {
                                'patient': _patientName,
                                'active': _activeElements.map((e) => e.label).toList(),
                              };
                              // Save/share snapshot hook
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Snapshot captured (demo).')));
                              // ignore: avoid_print
                              print(snapshot);
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Snapshot'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings not present in this demo.'))),
                            icon: const Icon(Icons.settings),
                            color: Colors.white,
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left pane: controls
                        Flexible(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Patient', style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _editingName
                                          ? TextField(
                                        controller: _nameController,
                                        autofocus: true,
                                        style: const TextStyle(fontSize: 26, color: Colors.white),
                                        decoration: const InputDecoration(border: InputBorder.none),
                                        onSubmitted: (v) => _setPatientName(v),
                                      )
                                          : Text(_patientName, style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.w800)),
                                    ),
                                    IconButton(
                                      icon: Icon(_editingName ? Icons.check : Icons.edit, color: Colors.white),
                                      onPressed: () {
                                        if (_editingName) {
                                          _setPatientName(_nameController.text);
                                        } else {
                                          setState(() {
                                            _editingName = true;
                                          });
                                        }
                                      },
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Preset Items', style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 3.2,
                                  ),
                                  itemCount: _presets.length,
                                  itemBuilder: (_, idx) {
                                    final el = _presets[idx];
                                    return GestureDetector(
                                      onTap: () => _toggleElement(el),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 220),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: el.active ? goldColor : Colors.white10,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: el.active ? Colors.black26 : Colors.white12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(el.icon, color: el.active ? Colors.black : Colors.white, size: 22),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text(el.label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: el.active ? Colors.black : Colors.white))),
                                            Switch(value: el.active, onChanged: (_) => _toggleElement(el)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _showAddCustomDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add custom'),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        for (var e in _presets) e.active = false;
                                        for (var c in _customMessages) c.active = false;
                                      });
                                    },
                                    icon: const Icon(Icons.clear_all),
                                    label: const Text('Clear active'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),

                        const SizedBox(width: 18),

                        // Right pane: preview
                        Flexible(
                          flex: 6,
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12),
                              boxShadow: const [BoxShadow(color: Colors.black45, offset: Offset(0, 8), blurRadius: 24)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text('Board Preview', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70)),
                                  Text(_patientId, style: const TextStyle(color: Colors.white54)),
                                ]),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(_patientName,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.dmSans(fontSize: 110, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          alignment: WrapAlignment.center,
                                          children: _activeElements.isNotEmpty
                                              ? _activeElements
                                              .map((e) => Chip(
                                            avatar: Icon(e.icon, size: 18, color: Colors.black),
                                            label: Text(e.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                                            backgroundColor: goldColor,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          ))
                                              .toList()
                                              : [
                                            Chip(
                                              label: Text('No active items', style: GoogleFonts.dmSans(color: Colors.white70)),
                                              backgroundColor: Colors.white12,
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                SizedBox(
                                  height: 110,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                        Text('Custom messages', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                                        Text('${_customMessages.length} total', style: const TextStyle(color: Colors.white54))
                                      ]),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: _customMessages.isEmpty
                                            ? Center(child: Text('No custom messages yet.', style: GoogleFonts.dmSans(color: Colors.white60)))
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
                                                  color: custom.active ? goldColor : Colors.white10,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(custom.icon, color: custom.active ? Colors.black : Colors.white),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(custom.label, style: const TextStyle(fontWeight: FontWeight.w700))),
                                                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _removeCustomMessage(custom)),
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
