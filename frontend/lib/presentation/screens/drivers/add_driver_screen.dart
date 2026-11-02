import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fleet_management/providers/driver_provider.dart';
import 'package:fleet_management/l10n/app_localizations.dart';
import 'package:fleet_management/core/utils/vehicle_driver_labels.dart';

class AddDriverScreen extends ConsumerStatefulWidget {
  const AddDriverScreen({super.key});

  @override
  ConsumerState<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends ConsumerState<AddDriverScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  final _formKey = GlobalKey<FormState>();

  // Login Credentials
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Basic Information
  final _employeeIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  DateTime _joinDate = DateTime.now();

  // Address (kept for API)
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedState;
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  // License
  final _licenseNumberController = TextEditingController();
  String _licenseType = 'LMV';
  DateTime? _issueDate;
  DateTime? _expiryDate;
  final _issuingAuthorityController = TextEditingController();
  String? _issuingState;

  // Emergency Contact
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  String? _emergencyContactRelationship;

  // Role
  String _selectedRole = 'driver';

  // Photo
  File? _selectedPhoto;

  bool _isSubmitting = false;

  static const _licenseTypes = ['LMV', 'HMV', 'MCWG', 'HPMV'];


  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _licenseNumberController.dispose();
    _issuingAuthorityController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  // ── Validators ──────────────────────────────────────────────────────────────

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) return AppLocalizations.of(context).drvAddFieldRequired(fieldName);
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
      return AppLocalizations.of(context).drvAddEmailInvalid;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.drvAddPhoneRequired;
    if (!RegExp(r'^\d{10}$').hasMatch(value)) return l10n.drvAddPhoneDigits;
    return null;
  }

  String? _validateUsername(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.drvAddUsernameRequired;
    if (!RegExp(r'^[a-zA-Z0-9_]{3,50}$').hasMatch(value)) {
      return l10n.drvAddUsernameFormat;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.drvAddPasswordRequired;
    if (value.length < 8) return l10n.drvAddPasswordLength;
    if (!RegExp(r'[A-Z]').hasMatch(value)) return l10n.drvAddPasswordUpper;
    if (!RegExp(r'[a-z]').hasMatch(value)) return l10n.drvAddPasswordLower;
    if (!RegExp(r'\d').hasMatch(value)) return l10n.drvAddPasswordDigit;
    return null;
  }

  String? _validateLicenseNumber(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return l10n.drvAddLicenseRequired;
    if (!RegExp(r'^[A-Z0-9\-]{10,50}$').hasMatch(value.toUpperCase())) {
      return l10n.drvAddLicenseFormat;
    }
    return null;
  }

  // ── Date Picker ──────────────────────────────────────────────────────────────

  Future<void> _pickDate(DateTime? initial, void Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  // ── Photo Picker ─────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedPhoto = File(picked.path));
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.drvAddFixErrors)),
      );
      return;
    }

    if (_issueDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.drvAddDatesRequired)),
      );
      return;
    }

    if (_expiryDate!.isBefore(_issueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.drvAddExpiryAfterIssue)),
      );
      return;
    }

    if (_expiryDate!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.drvAddExpiryFuture)),
      );
      return;
    }

    if (_joinDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.drvAddJoinFuture)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic> driverData = {
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
        'employee_id': _employeeIdController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'join_date': _joinDate.toIso8601String().split('T')[0],
        'country': _countryController.text.trim(),
        'license': {
          'license_number': _licenseNumberController.text.trim().toUpperCase(),
          'license_type': _licenseType,
          'issue_date': _issueDate!.toIso8601String().split('T')[0],
          'expiry_date': _expiryDate!.toIso8601String().split('T')[0],
        },
      };

      if (_emailController.text.isNotEmpty) {
        driverData['email'] = _emailController.text.trim();
      }
      if (_dateOfBirth != null) {
        driverData['date_of_birth'] = _dateOfBirth!.toIso8601String().split('T')[0];
      }
      if (_addressController.text.isNotEmpty) {
        driverData['address'] = _addressController.text.trim();
      }
      if (_cityController.text.isNotEmpty) {
        driverData['city'] = _cityController.text.trim();
      }
      if (_selectedState != null) driverData['state'] = _selectedState!;
      if (_pincodeController.text.isNotEmpty) {
        driverData['pincode'] = _pincodeController.text.trim();
      }
      if (_issuingAuthorityController.text.isNotEmpty) {
        (driverData['license'] as Map<String, dynamic>)['issuing_authority'] =
            _issuingAuthorityController.text.trim();
      }
      if (_issuingState != null) {
        (driverData['license'] as Map<String, dynamic>)['issuing_state'] = _issuingState!;
      }
      if (_emergencyContactNameController.text.isNotEmpty) {
        driverData['emergency_contact_name'] = _emergencyContactNameController.text.trim();
      }
      if (_emergencyContactPhoneController.text.isNotEmpty) {
        driverData['emergency_contact_phone'] = _emergencyContactPhoneController.text.trim();
      }
      if (_emergencyContactRelationship != null) {
        driverData['emergency_contact_relationship'] = _emergencyContactRelationship!;
      }

      final result = await ref.read(driverApiProvider).createDriver(driverData);
      final driverId = result['driver_id'] as String?;

      // Upload photo if selected
      String? photoError;
      if (_selectedPhoto != null && driverId != null) {
        try {
          await ref.read(driverApiProvider).uploadDriverPhoto(
            driverId: driverId,
            filePath: _selectedPhoto!.path,
          );
        } catch (e) {
          photoError = e.toString().replaceFirst('Exception: ', '');
          debugPrint('Driver photo upload error: $e');
        }
      }

      // Reload drivers list
      await ref.read(driverProvider.notifier).loadDrivers();

      if (mounted) {
        if (photoError != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.drvAddPhotoFailed(photoError)),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.drvAddSuccess)),
          );
        }
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────────

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primary.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primary.withAlpha(50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ── Build ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Sticky header ──────────────────────────────────────────────────
          Material(
            color: _bg,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Title row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: _primary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            l10n.drvAddTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.drvAddProgress,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(l10n.drvAddStep,
                                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: 1 / 3,
                            minHeight: 8,
                            backgroundColor: _primary.withAlpha(30),
                            valueColor: const AlwaysStoppedAnimation(_primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Scrollable form ─────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  // Photo upload
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: _primary.withAlpha(13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _primary.withAlpha(50)),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8),
                                  ],
                                ),
                                child: _selectedPhoto != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _selectedPhoto!,
                                          fit: BoxFit.cover,
                                          width: 96,
                                          height: 96,
                                        ),
                                      )
                                    : Icon(Icons.add_a_photo, size: 36, color: Colors.grey[400]),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.edit, size: 12, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedPhoto != null ? l10n.drvAddPhotoSelected : l10n.drvAddUploadPhoto,
                            style: const TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(l10n.drvAddPhotoHint,
                              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Section: Personal Information ──────────────────────────
                  _SectionHeader(icon: Icons.person, label: l10n.driverDashBPersonalInfo),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _FieldWrap(
                          label: l10n.drvAddFirstName,
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: _inputDecor(l10n.drvAddHintExample('Jonathan')),
                            validator: (v) => _validateRequired(v, l10n.drvAddFirstName),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FieldWrap(
                          label: l10n.drvAddLastName,
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: _inputDecor(l10n.drvAddHintExample('Miller')),
                            validator: (v) => _validateRequired(v, l10n.drvAddLastName),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: l10n.driverDashBEmployeeId,
                    child: TextFormField(
                      controller: _employeeIdController,
                      decoration: _inputDecor(l10n.drvAddHintExample('DRV-001')),
                      validator: (v) => _validateRequired(v, l10n.driverDashBEmployeeId),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: l10n.drvAddEmail,
                    child: TextFormField(
                      controller: _emailController,
                      decoration: _inputDecor('driver@fleet.com'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: l10n.authPhoneNumber,
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecor('+91 XXXXX XXXXX'),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: l10n.drvAddJoinDate,
                    child: GestureDetector(
                      onTap: () => _pickDate(_joinDate, (d) => setState(() => _joinDate = d)),
                      child: _DateBox(label: _fmtDate(_joinDate)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Section: Login Credentials ─────────────────────────────
                  _SectionHeader(icon: Icons.lock_outline, label: l10n.drvAddSectionLogin),
                  const SizedBox(height: 14),
                  _FieldWrap(
                    label: l10n.authUsername,
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecor('fleet_driver'),
                      validator: _validateUsername,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: l10n.authPassword,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecor(l10n.drvAddPasswordHint).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Section: License Details ───────────────────────────────
                  _SectionHeader(icon: Icons.badge, label: l10n.driverDashBLicenseDetails),
                  const SizedBox(height: 14),
                  _FieldWrap(
                    label: l10n.driverDashBLicenseNumber,
                    child: TextFormField(
                      controller: _licenseNumberController,
                      decoration: _inputDecor('ABC-123456-XYZ'),
                      textCapitalization: TextCapitalization.characters,
                      validator: _validateLicenseNumber,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: l10n.drvAddLicenseClass,
                    child: DropdownButtonFormField<String>(
                      value: _licenseType,
                      decoration: _inputDecor(''),
                      items: _licenseTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(licenseClassLabel(l10n, t), style: const TextStyle(fontSize: 14)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _licenseType = v!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Upload placeholder for license scan
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _primary.withAlpha(50), style: BorderStyle.solid),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.upload_file, color: _primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.drvAddLicenseScan,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(l10n.drvAddLicenseScanHint,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(l10n.recvDocsUpload.toUpperCase(),
                              style: const TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FieldWrap(
                          label: l10n.driverDashBIssueDate,
                          child: GestureDetector(
                            onTap: () =>
                                _pickDate(_issueDate, (d) => setState(() => _issueDate = d)),
                            child: _DateBox(label: _issueDate != null ? _fmtDate(_issueDate!) : l10n.drvAddSelect),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FieldWrap(
                          label: l10n.driverDashBExpiryDate,
                          child: GestureDetector(
                            onTap: () =>
                                _pickDate(_expiryDate, (d) => setState(() => _expiryDate = d)),
                            child: _DateBox(label: _expiryDate != null ? _fmtDate(_expiryDate!) : l10n.drvAddSelect),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Section: Assignment & Role ─────────────────────────────
                  _SectionHeader(icon: Icons.assignment, label: l10n.drvAddSectionRole),
                  const SizedBox(height: 14),
                  _FieldWrap(
                    label: l10n.drvAddSystemRole,
                    child: Row(
                      children: [
                        Expanded(
                          child: _RoleButton(
                            icon: Icons.drive_eta,
                            label: driverSystemRoleLabel(l10n, 'driver'),
                            value: 'driver',
                            selected: _selectedRole,
                            onTap: () => setState(() => _selectedRole = 'driver'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RoleButton(
                            icon: Icons.local_shipping,
                            label: driverSystemRoleLabel(l10n, 'logistics'),
                            value: 'logistics',
                            selected: _selectedRole,
                            onTap: () => setState(() => _selectedRole = 'logistics'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RoleButton(
                            icon: Icons.support_agent,
                            label: driverSystemRoleLabel(l10n, 'support'),
                            value: 'support',
                            selected: _selectedRole,
                            onTap: () => setState(() => _selectedRole = 'support'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Emergency contact (hidden fields for API compatibility) ─
                  const SizedBox(height: 0),
                  Opacity(
                    opacity: 0,
                    child: Column(children: [
                      TextFormField(controller: _addressController),
                      TextFormField(controller: _cityController),
                      TextFormField(controller: _pincodeController),
                      TextFormField(controller: _issuingAuthorityController),
                      TextFormField(controller: _emergencyContactNameController),
                      TextFormField(controller: _emergencyContactPhoneController),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Fixed footer ──────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        color: Colors.white.withAlpha(230),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add, size: 18),
                label: Text(
                  _isSubmitting ? l10n.drvAddAdding : l10n.drvAddButton,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  disabledBackgroundColor: _primary.withAlpha(120),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.drvAddCancelReturn,
                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _FieldWrap extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldWrap({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;

  const _DateBox({required this.label});

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = label == AppLocalizations.of(context).drvAddSelect;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _primary.withAlpha(50)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isPlaceholder ? Colors.grey[400] : Colors.black87,
              ),
            ),
          ),
          Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withAlpha(13) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? _primary : Colors.grey[400], size: 22),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isSelected ? _primary : Colors.grey[400],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
