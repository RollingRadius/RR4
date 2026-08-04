import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/profile_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/company_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/routing/dashboard_route.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  String? _selectedRoleType;

  // Driver fields
  final _licenseNumberController = TextEditingController();
  final _licenseExpiryController = TextEditingController();

  // Company fields
  final _companyNameController = TextEditingController();
  String? _selectedCompanyType; // 'logistic_partner' or 'load_owner'
  final _businessEmailController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Transporter-specific fields
  final _gstNumberController = TextEditingController();
  final _panNumberController = TextEditingController();

  String? _pincodeError;

  // Join company (worker)
  String? _selectedCompanyId;
  String? _selectedCompanyName;
  // Step 1: which company group — 'logistic_partner' | 'load_owner'
  String? _selectedWorkerCategory;
  // Step 2: actual role key — 'logistic_partner_worker' | 'lp_rr_operations' | 'load_owner_worker'
  String? _selectedWorkerType;
  final _companySearchController = TextEditingController();

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _companyNameController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _companySearchController.dispose();
    _gstNumberController.dispose();
    _panNumberController.dispose();
    super.dispose();
  }


  Future<void> _submitProfile() async {
    if (_selectedRoleType == null) {
      _showError('Please select a role type');
      return;
    }

    // Fix 401: ensure the token is applied to the API service before submitting
    final authState = ref.read(authProvider);
    if (authState.token != null) {
      ref.read(apiServiceProvider).setToken(authState.token!);
    } else {
      _showError('Session expired. Please log in again.');
      return;
    }

    // Build profile data
    Map<String, dynamic> profileData = {
      'role_type': _selectedRoleType,
    };

    // Add fields based on role type
    if (_selectedRoleType == 'driver') {
      if (_licenseNumberController.text.isEmpty) {
        _showError('Please enter your license number');
        return;
      }
      if (_licenseExpiryController.text.isEmpty) {
        _showError('Please enter your license expiry date');
        return;
      }
      profileData['license_number'] = _licenseNumberController.text.trim();
      profileData['license_expiry'] = _licenseExpiryController.text.trim();
    } else if (_selectedRoleType == 'join_company') {
      if (_selectedWorkerType == null) {
        _showError('Please select your worker type');
        return;
      }
      if (_selectedCompanyId == null) {
        _showError('Please select a company to join');
        return;
      }
      profileData['company_id'] = _selectedCompanyId;
      profileData['requested_role_key'] = _selectedWorkerType;
    } else if (_selectedRoleType == 'create_company') {
      if (_selectedCompanyType == null) {
        _showError('Please select a company type');
        return;
      }
      if (_companyNameController.text.isEmpty) {
        _showError('Please enter company name');
        return;
      }
      if (_addressController.text.trim().length < 5) {
        _showError('Address must be at least 5 characters');
        return;
      }
      profileData['company_name'] = _companyNameController.text.trim();
      profileData['business_type'] = _selectedCompanyType!;
      profileData['business_email'] = _businessEmailController.text.trim();
      profileData['business_phone'] = '+91${_businessPhoneController.text.trim()}';
      profileData['address'] = _addressController.text.trim();
      profileData['city'] = _cityController.text.trim();
      profileData['state'] = _stateController.text.trim();
      final pincode = _pincodeController.text.trim();
      if (pincode.length != 6 || pincode[0] == '0') {
        _showError('Enter a valid 6-digit Indian pincode');
        return;
      }
      profileData['pincode'] = pincode;
      profileData['country'] = 'India';
    } else if (_selectedRoleType == 'transporter') {
      if (_companyNameController.text.isEmpty) {
        _showError('Please enter your company name');
        return;
      }
      if (_panNumberController.text.isEmpty) {
        _showError('Please enter your PAN Card Number');
        return;
      }
      if (_addressController.text.trim().length < 5) {
        _showError('Address must be at least 5 characters');
        return;
      }
      profileData['company_name'] = _companyNameController.text.trim();
      profileData['business_type'] = 'transporter';
      if (_gstNumberController.text.trim().isNotEmpty) {
        profileData['gstin'] = _gstNumberController.text.trim().toUpperCase();
      }
      profileData['pan_number'] = _panNumberController.text.trim().toUpperCase();
      profileData['address'] = _addressController.text.trim();
    }

    // Submit profile
    final success = await ref.read(profileProvider.notifier).completeProfile(profileData);

    if (mounted) {
      if (success) {
        if (_selectedRoleType == 'join_company') {
          // Worker join: logout and return to login with a waiting message
          await ref.read(authProvider.notifier).logout();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Request sent! Wait for acceptance by the company owner.',
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFFF6B00),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
            context.go(AppConstants.routeLogin);
          }
        } else {
          // Refresh token so the new JWT carries the updated role/company context,
          // and authState.user reflects the owner role instead of independent.
          await ref.read(authProvider.notifier).refreshToken();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Profile completed successfully!'),
                  ],
                ),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            // Navigate based on role
            final updatedUser = ref.read(authProvider).user;
            context.go(updatedUser != null ? dashboardRouteFor(updatedUser) : AppConstants.routeDashboard);
          }
        }
      } else {
        final error = ref.read(profileProvider).error;
        _showError(error ?? 'Failed to complete profile');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _searchCompanies(String query) async {
    if (query.isEmpty) return;

    try {
      // Map selected worker type to the company business_type filter so only
      // matching companies appear (LP workers → logistic_partner companies, etc.)
      String? businessType;
      if (_selectedWorkerType == 'logistic_partner_worker') businessType = 'logistic_partner';
      if (_selectedWorkerType == 'lp_rr_operations')        businessType = 'logistic_partner';
      if (_selectedWorkerType == 'load_owner_worker')       businessType = 'load_owner';

      await ref.read(companyProvider.notifier).searchCompanies(query, businessType: businessType);
    } catch (e) {
      _showError('Failed to search companies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // Cannot go back
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.02),
              Colors.white,
            ],
          ),
        ),
        child: ScaleFade(
          delay: 0,
          duration: 600,
          child: Center(
            child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 0 : 24.0,
              vertical: 32.0,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : double.infinity,
              ),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Choose Your Role',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This decision is permanent and cannot be changed later.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Role Options
                      _buildRoleOption(
                        'independent',
                        'Independent User',
                        'Use basic features without company affiliation',
                        Icons.person_outline,
                        comingSoon: true,
                      ),
                      const SizedBox(height: 12),
                      _buildRoleOption(
                        'driver',
                        'Driver',
                        'Register as a driver with license information',
                        Icons.local_shipping_outlined,
                        comingSoon: true,
                      ),
                      const SizedBox(height: 12),
                      _buildRoleOption(
                        'join_company',
                        'Join as Worker',
                        'Join an existing company as a worker (requires owner approval)',
                        Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildRoleOption(
                        'create_company',
                        'Create Company',
                        'Register your company and become the Logistic Partner',
                        Icons.add_business_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildRoleOption(
                        'transporter',
                        'Join as Transporter',
                        'Register as an independent transporter to upload loading slips for assigned trips',
                        Icons.airport_shuttle_outlined,
                        comingSoon: true,
                      ),

                      const SizedBox(height: 32),

                      // Conditional forms
                      if (_selectedRoleType == 'driver') _buildDriverForm(),
                      if (_selectedRoleType == 'join_company') _buildJoinCompanyForm(),
                      if (_selectedRoleType == 'create_company') _buildCreateCompanyForm(),
                      if (_selectedRoleType == 'transporter') _buildTransporterForm(),

                      if (_selectedRoleType != null) const SizedBox(height: 32),

                      // Submit button
                      if (_selectedRoleType != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: profileState.isLoading ? null : _submitProfile,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: profileState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Complete Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),  // closes Center
        ),  // closes ScaleFade
      ),
    );
  }

  Widget _buildRoleOption(String value, String title, String description, IconData icon, {bool comingSoon = false}) {
    final isSelected = _selectedRoleType == value;

    return Opacity(
      opacity: comingSoon ? 0.5 : 1.0,
      child: InkWell(
        onTap: comingSoon
            ? null
            : () {
                setState(() {
                  _selectedRoleType       = value;
                  _selectedWorkerCategory = null;
                  _selectedWorkerType     = null;
                  _selectedCompanyId      = null;
                  _selectedCompanyName    = null;
                  _companySearchController.clear();
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (comingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              else if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Driver Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _licenseNumberController,
          decoration: InputDecoration(
            labelText: 'License Number *',
            hintText: 'DL1234567890',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _licenseExpiryController,
          decoration: InputDecoration(
            labelText: 'License Expiry Date (YYYY-MM-DD) *',
            hintText: '2027-12-31',
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinCompanyForm() {
    final companyState = ref.watch(companyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Select Company Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Which type of company do you want to work for?',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // Step 1 — Company category cards
        _buildWorkerTypeCard(
          value: 'logistic_partner',
          title: 'Logistic Partner Company',
          description: 'Work at a fleet/logistics company (Field Executive or RR Operations)',
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFFFF6B00),
          selectedValue: _selectedWorkerCategory,
          onSelect: (v) => setState(() {
            _selectedWorkerCategory = v;
            _selectedWorkerType     = null;   // reset sub-type
            _selectedCompanyId      = null;
            _selectedCompanyName    = null;
            _companySearchController.clear();
            ref.read(companyProvider.notifier).clearSearchResults();
          }),
        ),
        const SizedBox(height: 10),
        _buildWorkerTypeCard(
          value: 'load_owner',
          title: 'Load Owner Company',
          description: 'Work at a cargo/load company',
          icon: Icons.inventory_2_outlined,
          color: Colors.blue,
          comingSoon: true,
          selectedValue: _selectedWorkerCategory,
          onSelect: (v) => setState(() {
            _selectedWorkerCategory = v;
            _selectedWorkerType     = 'load_owner_worker';
            _selectedCompanyId      = null;
            _selectedCompanyName    = null;
            _companySearchController.clear();
            ref.read(companyProvider.notifier).clearSearchResults();
          }),
        ),

        // Step 2 — LP sub-type selection (Field Executive or RR Ops)
        if (_selectedWorkerCategory == 'logistic_partner') ...[
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          const Text(
            'Select Your Role',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'What will you do at the logistics company?',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 14),
          _buildWorkerTypeCard(
            value: 'logistic_partner_worker',
            title: 'Field Executive',
            description: 'Manage trip stages and fleet status on the ground',
            icon: Icons.badge_outlined,
            color: const Color(0xFFFF6B00),
            selectedValue: _selectedWorkerType,
            onSelect: (v) => setState(() {
              _selectedWorkerType  = v;
              _selectedCompanyId   = null;
              _selectedCompanyName = null;
              _companySearchController.clear();
              ref.read(companyProvider.notifier).clearSearchResults();
            }),
          ),
          const SizedBox(height: 10),
          _buildWorkerTypeCard(
            value: 'lp_rr_operations',
            title: 'RR Operations',
            description: 'Handle RR sync and trip data entry in the RR system',
            icon: Icons.sync_alt,
            color: const Color(0xFF1B6CA8),
            selectedValue: _selectedWorkerType,
            onSelect: (v) => setState(() {
              _selectedWorkerType  = v;
              _selectedCompanyId   = null;
              _selectedCompanyName = null;
              _companySearchController.clear();
              ref.read(companyProvider.notifier).clearSearchResults();
            }),
          ),
        ],

        if (_selectedWorkerType != null) ...[
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          const Text(
            'Search Company',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _companySearchController,
            decoration: InputDecoration(
              labelText: 'Search Company',
              hintText: 'Enter at least 3 characters',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              if (value.trim().length >= 3) {
                _searchCompanies(value.trim());
              } else if (value.trim().length < 3) {
                ref.read(companyProvider.notifier).clearSearchResults();
              }
            },
          ),
          const SizedBox(height: 16),
          if (companyState.searchResults.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: companyState.searchResults.length,
                itemBuilder: (context, index) {
                  final company = companyState.searchResults[index];
                  final isSelected = _selectedCompanyId == company.id;
                  return ListTile(
                    selected: isSelected,
                    leading: const Icon(Icons.business),
                    title: Text(company.companyName),
                    subtitle: Text('${company.city}, ${company.state}'),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCompanyId = company.id;
                        _selectedCompanyName = company.companyName;
                      });
                    },
                  );
                },
              ),
            ),
          if (_selectedCompanyName != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selected: $_selectedCompanyName',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildWorkerTypeCard({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool comingSoon = false,
    // Optional overrides for two-level selection
    String? selectedValue,
    void Function(String)? onSelect,
  }) {
    final isSelected = (selectedValue ?? _selectedWorkerType) == value;
    return Opacity(
      opacity: comingSoon ? 0.5 : 1.0,
      child: _WorkerTypeCardInner(
        value: value, title: title, description: description,
        icon: icon, color: color, comingSoon: comingSoon,
        isSelected: isSelected,
        onTap: comingSoon ? null : () {
          if (onSelect != null) {
            onSelect(value);
          } else {
            setState(() {
              _selectedWorkerType  = value;
              _selectedCompanyId   = null;
              _selectedCompanyName = null;
              _companySearchController.clear();
              ref.read(companyProvider.notifier).clearSearchResults();
            });
          }
        },
      ),
    );
  }
}

// ─── Helper widget to avoid Opacity + InkWell nesting issues ─────────────────
class _WorkerTypeCardInner extends StatelessWidget {
  final String value, title, description;
  final IconData icon;
  final Color color;
  final bool comingSoon, isSelected;
  final VoidCallback? onTap;

  const _WorkerTypeCardInner({
    required this.value, required this.title, required this.description,
    required this.icon, required this.color, required this.comingSoon,
    required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                ),
              )
            else if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Back in main state class ─────────────────────────────────────────────────
extension _ProfileCompletionScreenStateMethods on _ProfileCompletionScreenState {
  Widget _buildCreateCompanyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'What type of company are you registering?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the category that best describes your business',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),

        // Logistics / Fleet Company card
        _buildCompanyTypeCard(
          value: 'logistic_partner',
          title: 'Logistic Partner Company',
          description: 'You manage a fleet of vehicles for transportation — your role: Logistic Partner',
          icon: Icons.local_shipping_outlined,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),

        // Load Provider Company card
        _buildCompanyTypeCard(
          value: 'load_owner',
          title: 'Load Provider Company',
          description: 'You have cargo/goods that need to be transported',
          icon: Icons.inventory_2_outlined,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),

        // Load Receiver Company card
        _buildCompanyTypeCard(
          value: 'load_receiver',
          title: 'Load Receiver Company',
          description: 'You receive deliveries — you are the consignee',
          icon: Icons.move_to_inbox_outlined,
          color: const Color(0xFF00796B),
          comingSoon: true,
        ),

        // Company detail form — shown only after type is selected
        if (_selectedCompanyType != null) ...[
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          const Text(
            'Company Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _companyNameController,
            decoration: InputDecoration(
              labelText: 'Company Name *',
              prefixIcon: const Icon(Icons.business),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _businessEmailController,
            decoration: InputDecoration(
              labelText: 'Business Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _businessPhoneController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              labelText: 'Business Phone',
              hintText: '9876543210',
              prefixIcon: const Icon(Icons.phone),
              prefix: const Text(
                '+91 ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 2,
            maxLength: 150,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pincodeController,
            decoration: InputDecoration(
              labelText: 'Pincode (6 digits)',
              prefixIcon: const Icon(Icons.pin_drop),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTransporterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Transporter Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your transport business details',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _companyNameController,
          decoration: InputDecoration(
            labelText: 'Company Name *',
            hintText: 'Your transport company name',
            prefixIcon: const Icon(Icons.business),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _gstNumberController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'GST Number (optional)',
            hintText: '22AAAAA0000A1Z5',
            prefixIcon: const Icon(Icons.receipt_long),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _panNumberController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'PAN Card Number *',
            hintText: 'ABCDE1234F',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address *',
            hintText: 'Your business address',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCompanyTypeCard({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    bool comingSoon = false,
  }) {
    final isSelected = _selectedCompanyType == value;
    return Opacity(
      opacity: comingSoon ? 0.5 : 1.0,
      child: _CompanyTypeCardWrapper(
        comingSoon: comingSoon,
        isSelected: isSelected,
        color: color,
        icon: icon,
        title: title,
        description: description,
        onTap: comingSoon ? null : () => setState(() => _selectedCompanyType = value),
      ),
    );
  }
}

class _CompanyTypeCardWrapper extends StatelessWidget {
  final bool comingSoon, isSelected;
  final Color color;
  final IconData icon;
  final String title, description;
  final VoidCallback? onTap;

  const _CompanyTypeCardWrapper({
    required this.comingSoon, required this.isSelected, required this.color,
    required this.icon, required this.title, required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600], size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (comingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                ),
              )
            else if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
