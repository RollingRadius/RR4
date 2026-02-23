import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/company_provider.dart';
import 'package:fleet_management/providers/organization_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class CreateOrganizationScreen extends ConsumerStatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  ConsumerState<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState
    extends ConsumerState<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Company Info
  final _companyNameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessPhoneController = TextEditingController();

  // Address Info
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  // Legal Info (Optional)
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();

  bool _isCreating = false;
  bool _showLegalInfo = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _businessTypeController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    super.dispose();
  }

  String? _validateGSTIN(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length != 15) return 'GSTIN must be exactly 15 characters';
    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(value)) return 'Invalid GSTIN format';
    return null;
  }

  String? _validatePAN(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.length != 10) return 'PAN must be exactly 10 characters';
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value))
      return 'Invalid PAN format';
    return null;
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final companyApi = ref.read(companyApiProvider);

      final companyData = {
        'company_name': _companyNameController.text.trim(),
        'business_type': _businessTypeController.text.trim(),
        'business_email': _businessEmailController.text.trim(),
        'business_phone': _businessPhoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'country': _countryController.text.trim(),
        if (_gstinController.text.isNotEmpty)
          'gstin': _gstinController.text.trim(),
        if (_panController.text.isNotEmpty)
          'pan_number': _panController.text.trim(),
      };

      final response = await companyApi.createCompany(companyData);

      if (mounted) {
        await ref.read(authProvider.notifier).refreshToken();
        await ref.read(organizationProvider.notifier).loadOrganizations();

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Organization "${response['company_name']}" created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));

        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to create organization: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: theme.primaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('Create Organization',
                  style: TextStyle(color: Colors.white, fontSize: 17)),
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(context),
              ),
            ),

            // ── Form Sections ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeSlide(
                    delay: 0,
                    child: _SectionCard(
                      step: 1,
                      icon: Icons.business_outlined,
                      title: 'Company Information',
                      color: theme.primaryColor,
                      children: [
                        _buildField(
                          controller: _companyNameController,
                          label: 'Company Name',
                          hint: 'e.g., Acme Logistics Pvt. Ltd.',
                          icon: Icons.corporate_fare_outlined,
                          required: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Company name is required';
                            if (v.trim().length < 2)
                              return 'Must be at least 2 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _businessTypeController,
                          label: 'Business Type',
                          hint: 'e.g., Transportation, Logistics',
                          icon: Icons.category_outlined,
                          required: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Business type is required';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlide(
                    delay: 80,
                    child: _SectionCard(
                      step: 2,
                      icon: Icons.contact_mail_outlined,
                      title: 'Contact Information',
                      color: Colors.teal,
                      children: [
                        _buildField(
                          controller: _businessEmailController,
                          label: 'Business Email',
                          hint: 'company@example.com',
                          icon: Icons.email_outlined,
                          required: true,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Business email is required';
                            if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(v))
                              return 'Invalid email format';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _businessPhoneController,
                          label: 'Business Phone',
                          hint: '+91 98765 43210',
                          icon: Icons.phone_outlined,
                          required: true,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Business phone is required';
                            if (v.trim().length < 10)
                              return 'Must be at least 10 digits';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlide(
                    delay: 160,
                    child: _SectionCard(
                      step: 3,
                      icon: Icons.location_on_outlined,
                      title: 'Address',
                      color: Colors.orange,
                      children: [
                        _buildField(
                          controller: _addressController,
                          label: 'Street Address',
                          hint: 'Building, street, area…',
                          icon: Icons.home_outlined,
                          required: true,
                          maxLines: 2,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Address is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _cityController,
                                label: 'City',
                                hint: 'Mumbai',
                                icon: Icons.location_city_outlined,
                                required: true,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Required';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                controller: _stateController,
                                label: 'State',
                                hint: 'Maharashtra',
                                icon: Icons.map_outlined,
                                required: true,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Required';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                controller: _pincodeController,
                                label: 'Pincode',
                                hint: '400001',
                                icon: Icons.pin_outlined,
                                required: true,
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Required';
                                  if (v.trim().length != 6)
                                    return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildField(
                                controller: _countryController,
                                label: 'Country',
                                hint: 'India',
                                icon: Icons.flag_outlined,
                                enabled: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Legal Info (collapsible) ──────────────────────────
                  FadeSlide(
                    delay: 240,
                    child: _LegalInfoSection(
                      expanded: _showLegalInfo,
                      onToggle: () =>
                          setState(() => _showLegalInfo = !_showLegalInfo),
                      gstinController: _gstinController,
                      panController: _panController,
                      validateGSTIN: _validateGSTIN,
                      validatePAN: _validatePAN,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Submit ───────────────────────────────────────────
                  FadeSlide(
                    delay: 300,
                    child: _buildSubmitButton(context, theme),
                  ),
                  const SizedBox(height: 12),
                  FadeSlide(
                    delay: 340,
                    child: TextButton(
                      onPressed: _isCreating ? null : () => context.pop(),
                      child: Text('Cancel',
                          style: TextStyle(color: Colors.grey[500])),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.business_center_outlined,
              size: 140,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_business_outlined,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Organization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Set up your fleet workspace',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final fillColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade50;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: enabled ? fillColor : Colors.grey.withOpacity(0.08),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _isCreating ? null : _handleCreate,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCreating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Create Organization',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        color: theme.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                    color: color.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$step',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legal Info Section (collapsible) ────────────────────────────────────────

class _LegalInfoSection extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController gstinController;
  final TextEditingController panController;
  final String? Function(String?) validateGSTIN;
  final String? Function(String?) validatePAN;

  const _LegalInfoSection({
    required this.expanded,
    required this.onToggle,
    required this.gstinController,
    required this.panController,
    required this.validateGSTIN,
    required this.validatePAN,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Colors.purple;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded
              ? color.withOpacity(0.3)
              : theme.dividerColor.withOpacity(0.4),
        ),
        color: theme.cardColor,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Toggle header
          InkWell(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: expanded
                    ? color.withOpacity(0.06)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.gavel_outlined,
                          size: 16, color: color),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legal Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          'GSTIN & PAN — Optional',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          expanded ? 'Hide' : 'Add',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                Divider(
                    height: 1, color: color.withOpacity(0.15)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _legalField(
                        context: context,
                        controller: gstinController,
                        label: 'GSTIN',
                        hint: '22AAAAA0000A1Z5',
                        icon: Icons.receipt_long_outlined,
                        color: color,
                        validator: validateGSTIN,
                        helper: '15 characters',
                      ),
                      const SizedBox(height: 14),
                      _legalField(
                        context: context,
                        controller: panController,
                        label: 'PAN Number',
                        hint: 'ABCDE1234F',
                        icon: Icons.credit_card_outlined,
                        color: color,
                        validator: validatePAN,
                        helper: '10 characters',
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

  Widget _legalField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required String? Function(String?) validator,
    required String helper,
  }) {
    final theme = Theme.of(context);
    final fillColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade50;

    return TextFormField(
      controller: controller,
      validator: validator,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(fontSize: 14, letterSpacing: 1),
      decoration: InputDecoration(
        labelText: '$label (Optional)',
        hintText: hint,
        helperText: helper,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: color),
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
