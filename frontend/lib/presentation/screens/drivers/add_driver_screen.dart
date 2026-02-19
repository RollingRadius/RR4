import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/driver_provider.dart';

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

  bool _isSubmitting = false;

  final List<Map<String, String>> _licenseTypes = [
    {'value': 'LMV', 'label': 'LMV (Light Motor Vehicle)'},
    {'value': 'HMV', 'label': 'HMV (Heavy Motor Vehicle)'},
    {'value': 'MCWG', 'label': 'MCWG (Motorcycle with Gear)'},
    {'value': 'HPMV', 'label': 'HPMV (Heavy Passenger Motor Vehicle)'},
  ];


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
    if (value == null || value.isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Phone must be 10 digits';
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username is required';
    if (!RegExp(r'^[a-zA-Z0-9_]{3,50}$').hasMatch(value)) {
      return 'Username: 3-50 chars (letters, numbers, underscore)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must include an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Must include a lowercase letter';
    if (!RegExp(r'\d').hasMatch(value)) return 'Must include a digit';
    return null;
  }

  String? _validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) return 'License number is required';
    if (!RegExp(r'^[A-Z0-9\-]{10,50}$').hasMatch(value.toUpperCase())) {
      return 'License must be 10-50 alphanumeric characters';
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

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form')),
      );
      return;
    }

    if (_issueDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License issue date and expiry date are required')),
      );
      return;
    }

    if (_expiryDate!.isBefore(_issueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License expiry date must be after issue date')),
      );
      return;
    }

    if (_expiryDate!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License expiry date must be in the future')),
      );
      return;
    }

    if (_joinDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join date cannot be in the future')),
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

      final success = await ref.read(driverProvider.notifier).addDriver(driverData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver added successfully!')),
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(driverProvider).error ?? 'Failed to add driver';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                        const Expanded(
                          child: Text(
                            'Add New Driver',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            const Text(
                              'REGISTRATION PROGRESS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text('Step 1 of 3',
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
                    onTap: () {},
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
                                child: Icon(Icons.add_a_photo, size: 36, color: Colors.grey[400]),
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
                          const Text(
                            'Upload Profile Photo',
                            style: TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text('PNG, JPG up to 5MB',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Section: Personal Information ──────────────────────────
                  const _SectionHeader(icon: Icons.person, label: 'Personal Information'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _FieldWrap(
                          label: 'First Name',
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: _inputDecor('e.g. Jonathan'),
                            validator: (v) => _validateRequired(v, 'First name'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FieldWrap(
                          label: 'Last Name',
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: _inputDecor('e.g. Miller'),
                            validator: (v) => _validateRequired(v, 'Last name'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: 'Employee ID',
                    child: TextFormField(
                      controller: _employeeIdController,
                      decoration: _inputDecor('e.g. DRV-001'),
                      validator: (v) => _validateRequired(v, 'Employee ID'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: 'Email Address',
                    child: TextFormField(
                      controller: _emailController,
                      decoration: _inputDecor('driver@fleet.com'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: 'Phone Number',
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecor('+91 XXXXX XXXXX'),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: 'Join Date',
                    child: GestureDetector(
                      onTap: () => _pickDate(_joinDate, (d) => setState(() => _joinDate = d)),
                      child: _DateBox(label: _fmtDate(_joinDate)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Section: Login Credentials ─────────────────────────────
                  const _SectionHeader(icon: Icons.lock_outline, label: 'Login Credentials'),
                  const SizedBox(height: 14),
                  _FieldWrap(
                    label: 'Username',
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: _inputDecor('fleet_driver'),
                      validator: _validateUsername,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: 'Password',
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _inputDecor('Min 8 chars, with uppercase & digit').copyWith(
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
                  const _SectionHeader(icon: Icons.badge, label: 'License Details'),
                  const SizedBox(height: 14),
                  _FieldWrap(
                    label: 'License Number',
                    child: TextFormField(
                      controller: _licenseNumberController,
                      decoration: _inputDecor('ABC-123456-XYZ'),
                      textCapitalization: TextCapitalization.characters,
                      validator: _validateLicenseNumber,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FieldWrap(
                    label: 'License Class',
                    child: DropdownButtonFormField<String>(
                      value: _licenseType,
                      decoration: _inputDecor(''),
                      items: _licenseTypes
                          .map((t) => DropdownMenuItem(
                                value: t['value'],
                                child: Text(t['label']!, style: const TextStyle(fontSize: 14)),
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
                              const Text('License Document Scan',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('Upload clear scan or photo',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text('UPLOAD',
                              style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FieldWrap(
                          label: 'Issue Date',
                          child: GestureDetector(
                            onTap: () =>
                                _pickDate(_issueDate, (d) => setState(() => _issueDate = d)),
                            child: _DateBox(label: _issueDate != null ? _fmtDate(_issueDate!) : 'Select'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FieldWrap(
                          label: 'Expiry Date',
                          child: GestureDetector(
                            onTap: () =>
                                _pickDate(_expiryDate, (d) => setState(() => _expiryDate = d)),
                            child: _DateBox(label: _expiryDate != null ? _fmtDate(_expiryDate!) : 'Select'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Section: Assignment & Role ─────────────────────────────
                  const _SectionHeader(icon: Icons.assignment, label: 'Assignment & Role'),
                  const SizedBox(height: 14),
                  _FieldWrap(
                    label: 'System Role',
                    child: Row(
                      children: [
                        Expanded(
                          child: _RoleButton(
                            icon: Icons.drive_eta,
                            label: 'Driver',
                            value: 'driver',
                            selected: _selectedRole,
                            onTap: () => setState(() => _selectedRole = 'driver'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RoleButton(
                            icon: Icons.local_shipping,
                            label: 'Logistics',
                            value: 'logistics',
                            selected: _selectedRole,
                            onTap: () => setState(() => _selectedRole = 'logistics'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RoleButton(
                            icon: Icons.support_agent,
                            label: 'Support',
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
                  _isSubmitting ? 'Adding Driver...' : 'Add Driver to Fleet',
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
                'Cancel and return',
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
    final isPlaceholder = label == 'Select';
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
