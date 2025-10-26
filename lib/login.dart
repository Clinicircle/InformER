import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'home.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

enum VerificationStatus {
  idle,
  loading,
  success,
  failure
}

class _SignInScreenState extends State<SignInScreen> {
  final _nameController = TextEditingController();
  final _institutionCodeController = TextEditingController();
  final _sessionIdController = TextEditingController();

  bool _isFormComplete = false;
  final double _topSpacing = 90;
  final double _fieldWidthRatio = 0.8;

  String _statusMessage = '';
  Color _statusMessageColor = Colors.black;
  VerificationStatus _verificationStatus = VerificationStatus.idle;
  String _verifiedInstitutionName = "";
  String _finalHashedInstitutionCode = "";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _institutionCodeController.addListener(_formatInstitutionCode);
    _nameController.addListener(_onFieldChange);
    _institutionCodeController.addListener(_onFieldChange);
    _sessionIdController.addListener(_onFieldChange);
    _validateForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionCodeController.dispose();
    _sessionIdController.dispose();
    super.dispose();
  }

  void _formatInstitutionCode() {
    final raw = _institutionCodeController.text.replaceAll(' ', '');
    final StringBuffer formatted = StringBuffer();
    for (int i = 0; i < raw.length && i < 12; i++) {
      if (i > 0 && i % 3 == 0) formatted.write(' ');
      if (RegExp(r'[a-zA-Z0-9]').hasMatch(raw[i])) {
        formatted.write(raw[i]);
      }
    }
    final result = formatted.toString();
    if (result != _institutionCodeController.text) {
      _institutionCodeController.value = TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    }
  }

  void _onFieldChange() {
    if (_verificationStatus == VerificationStatus.success || _verificationStatus == VerificationStatus.failure) {
      setState(() {
        _verificationStatus = VerificationStatus.idle;
        _statusMessage = '';
      });
    }
    _validateForm();
  }


  void _validateForm() {
    final isComplete = _nameController.text.trim().isNotEmpty &&
        _institutionCodeController.text.replaceAll(' ', '').length == 12 &&
        _sessionIdController.text.trim().isNotEmpty;

    if (_isFormComplete != isComplete) {
      setState(() {
        _isFormComplete = isComplete;
        if (!isComplete && _verificationStatus != VerificationStatus.idle && _verificationStatus != VerificationStatus.loading) {
          _verificationStatus = VerificationStatus.idle;
          _statusMessage = '';
        }
      });
    }
  }

  Future<void> _performVerification() async {
    if (!_isFormComplete) return;

    setState(() {
      _statusMessage = 'Verifying session details...';
      _statusMessageColor = Colors.black;
      _verificationStatus = VerificationStatus.loading;
      _finalHashedInstitutionCode = "";
    });

    final userInputInstitutionCode = _institutionCodeController.text.replaceAll(' ', '');
    final userInputName = _nameController.text.trim();
    final userInputSessionId = _sessionIdController.text.trim();

    final String hashedInputInstitutionCode = sha256.convert(utf8.encode(userInputInstitutionCode)).toString();

    try {
      DocumentSnapshot institutionDoc = await _firestore.collection('Information').doc(hashedInputInstitutionCode).get();

      if (!institutionDoc.exists) {
        setState(() {
          _statusMessage = 'Invalid institution code.';
          _statusMessageColor = Colors.red;
          _verificationStatus = VerificationStatus.failure;
        });
        return;
      }

      Map<String, dynamic> data = institutionDoc.data() as Map<String, dynamic>;

      final List<String> authorizedNamesForInstitution = List<String>.from(data['AuthorizedPeople'] ?? []);
      if (!authorizedNamesForInstitution.contains(userInputName)) {
        setState(() {
          _statusMessage = 'Unauthorized session creator.';
          _statusMessageColor = Colors.red;
          _verificationStatus = VerificationStatus.failure;
        });
        return;
      }

      final List<String> activeSessionsForInstitution = List<String>.from(data['SessionIdentifiers'] ?? []);
      if (activeSessionsForInstitution.contains(userInputSessionId)) {
        setState(() {
          _statusMessage = 'Session identifier already in use.';
          _statusMessageColor = Colors.red;
          _verificationStatus = VerificationStatus.failure;
        });
        return;
      }

      final int? maxSessionsForInstitution = data['SessionLimit'] as int?;
      if (maxSessionsForInstitution != null && activeSessionsForInstitution.length >= maxSessionsForInstitution) {
        setState(() {
          _statusMessage = 'Institution session limit reached.';
          _statusMessageColor = Colors.red;
          _verificationStatus = VerificationStatus.failure;
        });
        return;
      }

      final String? institutionNameFromDb = data['Name'] as String?;
      if (institutionNameFromDb == null) {
        setState(() {
          _statusMessage = 'Institution details not found. Please contact Clinicircle for help.';
          _statusMessageColor = Colors.red;
          _verificationStatus = VerificationStatus.failure;
        });
        return;
      }

      await _firestore.collection('Information').doc(hashedInputInstitutionCode).update({
        'SessionIdentifiers': FieldValue.arrayUnion([userInputSessionId])
      });

      setState(() {
        _statusMessage = 'Session created successfully!';
        _statusMessageColor = Colors.green;
        _verificationStatus = VerificationStatus.success;
        _verifiedInstitutionName = institutionNameFromDb;
        _finalHashedInstitutionCode = hashedInputInstitutionCode;
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'An error occurred. Please try again.';
        _statusMessageColor = Colors.red;
        _verificationStatus = VerificationStatus.failure;
      });
    }
  }


  void _navigateToHome() {
    if (_verificationStatus == VerificationStatus.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainAppScreen(
            userName: _nameController.text.trim(),
            institutionName: _verifiedInstitutionName,
            sessionId: _sessionIdController.text.trim(),
            hashedInstitutionCode: _finalHashedInstitutionCode,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double continueButtonWidth = screenWidth * 0.45;

    bool canAttemptVerification = _isFormComplete && _verificationStatus == VerificationStatus.idle;
    bool canProceedToHome = _verificationStatus == VerificationStatus.success;
    bool isLoading = _verificationStatus == VerificationStatus.loading;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bglight.png', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: _topSpacing > 50 ? _topSpacing : 50),
                          Center(
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.dmSans(
                                fontSize: 70,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          _buildLabeledField(
                            label: 'Full Legal Name',
                            controller: _nameController,
                            placeholder: 'John Smith',
                            screenHeight: screenHeight,
                            fieldWidth: screenWidth * _fieldWidthRatio,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 25),
                          _buildLabeledField(
                            label: 'Institution Code',
                            tooltipMessage: 'You can get this from your institution’s champion.\nIf lost, please call (888) 880-CIRC.',
                            controller: _institutionCodeController,
                            placeholder: 'XXX XXX XXX XXX',
                            screenHeight: screenHeight,
                            fieldWidth: screenWidth * _fieldWidthRatio,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            ],
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 25),
                          _buildLabeledField(
                            label: 'Session Identifier',
                            tooltipMessage: 'A unique identifier for this login session,\nlike the serial number of this tablet.',
                            controller: _sessionIdController,
                            placeholder: 'Tablet 136',
                            screenHeight: screenHeight,
                            fieldWidth: screenWidth * _fieldWidthRatio,
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 15),
                          if (_statusMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                              child: Center(
                                child: Text(
                                  _statusMessage,
                                  style: GoogleFonts.dmSans(
                                    color: _statusMessageColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: screenHeight * 0.086,
                                width: screenHeight * 0.086,
                                child: OutlinedButton(
                                  onPressed: isLoading ? null : () {
                                    if (Navigator.canPop(context)) {
                                      Navigator.pop(context);
                                    }
                                  },
                                  style: _buttonStyle(screenHeight, fixedWidth: screenHeight * 0.086, backgroundColor: const Color(0xFFEFEFEF)),
                                  child: Text(
                                    '←',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: continueButtonWidth,
                                height: screenHeight * 0.086,
                                child: OutlinedButton(
                                  onPressed: (canAttemptVerification || canProceedToHome) && !isLoading
                                      ? () {
                                    if (canProceedToHome) {
                                      _navigateToHome();
                                    } else if (canAttemptVerification) {
                                      _performVerification();
                                    }
                                  }
                                      : null,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.black, width: 5),
                                    backgroundColor: canProceedToHome
                                        ? const Color(0xFF0F6D51)
                                        : (canAttemptVerification && !isLoading)
                                        ? const Color(0xFFEFEFEF)
                                        : const Color(0xFFEFEFEF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 3,
                                    ),
                                  )
                                      : Text(
                                    'Continue →',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: canProceedToHome
                                          ? Colors.white
                                          : (canAttemptVerification && !isLoading)
                                          ? Colors.black
                                          : Colors.grey[600],
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
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildLabeledField({
  required String label,
  required TextEditingController controller,
  required String placeholder,
  required double screenHeight,
  required double fieldWidth,
  String? tooltipMessage,
  List<TextInputFormatter>? inputFormatters,
  bool enabled = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (tooltipMessage != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Tooltip(
                message: tooltipMessage,
                textStyle: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                preferBelow: false,
                waitDuration: const Duration(milliseconds: 300),
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
      const SizedBox(height: 10),
      SizedBox(
        width: fieldWidth,
        height: screenHeight * 0.086,
        child: OutlinedButton(
          onPressed: null,
          style: _buttonStyle(screenHeight, fixedWidth: fieldWidth, backgroundColor: enabled ? Colors.white : Colors.grey[200]!),
          child: TextField(
            controller: controller,
            enabled: enabled,
            textAlignVertical: TextAlignVertical.center,
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: enabled ? Colors.black : Colors.grey[700],
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: GoogleFonts.dmSans(
                  color: const Color(0xFFCCCCCC),
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 5.0),
            ),
            inputFormatters: inputFormatters,
          ),
        ),
      ),
    ],
  );
}

ButtonStyle _buttonStyle(double height, {Color backgroundColor = Colors.white, double? fixedWidth}) {
  return OutlinedButton.styleFrom(
    side: const BorderSide(color: Colors.black, width: 5),
    backgroundColor: backgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24),
    minimumSize: fixedWidth == null ? Size.fromHeight(height * 0.086) : Size(fixedWidth, height * 0.086),
    fixedSize: fixedWidth != null ? Size(fixedWidth, height * 0.086) : null,
  );
}
