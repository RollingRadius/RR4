import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/profile_provider.dart';
import 'package:fleet_management/providers/company_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
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
  final _businessTypeController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Join company
  String? _selectedCompanyId;
  String? _selectedCompanyName;
  String? _selectedRoleKey;
  final _companySearchController = TextEditingController();

  // Predefined roles available when joining a company
  static const List<Map<String, String>> _predefinedRoles = [
    {'key': 'fleet_manager', 'label': 'Fleet Manager'},
    {'key': 'dispatcher', 'label': 'Dispatcher'},
    {'key': 'driver', 'label': 'Driver'},
    {'key': 'accountant', 'label': 'Accountant'},
    {'key': 'maintenance_manager', 'label': 'Maintenance Manager'},
    {'key': 'compliance_officer', 'label': 'Compliance Officer'},
    {'key': 'operations_manager', 'label': 'Operations Manager'},
    {'key': 'maintenance_technician', 'label': 'Maintenance Technician'},
    {'key': 'customer_service', 'label': 'Customer Service'},
    {'key': 'viewer_analyst', 'label': 'Viewer / Analyst'},
  ];

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    _companyNameController.dispose();
    _businessTypeController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _companySearchController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (_selectedRoleType == null) {
      _showError('Please select a role type');
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
      if (_selectedCompanyId == null) {
        _showError('Please select a company to join');
        return;
      }
      profileData['company_id'] = _selectedCompanyId;
      if (_selectedRoleKey != null) {
        profileData['requested_role_key'] = _selectedRoleKey;
      }
    } else if (_selectedRoleType == 'create_company') {
      if (_companyNameController.text.isEmpty) {
        _showError('Please enter company name');
        return;
      }
      if (_businessTypeController.text.isEmpty) {
        _showError('Please enter business type');
        return;
      }
      profileData['company_name'] = _companyNameController.text.trim();
      profileData['business_type'] = _businessTypeController.text.trim();
      profileData['business_email'] = _businessEmailController.text.trim();
      profileData['business_phone'] = _businessPhoneController.text.trim();
      profileData['address'] = _addressController.text.trim();
      profileData['city'] = _cityController.text.trim();
      profileData['state'] = _stateController.text.trim();
      profileData['pincode'] = _pincodeController.text.trim();
      profileData['country'] = 'India';
    }

    // Submit profile
    final success = await ref.read(profileProvider.notifier).completeProfile(profileData);

    if (mounted) {
      if (success) {
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
        // Navigate to dashboard
        context.go(AppConstants.routeDashboard);
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
      await ref.read(companyProvider.notifier).searchCompanies(query);
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
                      ),
                      const SizedBox(height: 12),
                      _buildRoleOption(
                        'driver',
                        'Driver',
                        'Register as a driver with license information',
                        Icons.local_shipping_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildRoleOption(
                        'join_company',
                        'Join Company',
                        'Join an existing company (requires approval)',
                        Icons.business_outlined,
                      ),
                      const SizedBox(height: 12),
                      _buildRoleOption(
                        'create_company',
                        'Create Company',
                        'Create your own company and become the owner',
                        Icons.add_business_outlined,
                      ),

                      const SizedBox(height: 32),

                      // Conditional forms
                      if (_selectedRoleType == 'driver') _buildDriverForm(),
                      if (_selectedRoleType == 'join_company') _buildJoinCompanyForm(),
                      if (_selectedRoleType == 'create_company') _buildCreateCompanyForm(),

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

  Widget _buildRoleOption(String value, String title, String description, IconData icon) {
    final isSelected = _selectedRoleType == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRoleType = value;
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
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
          ],
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
          'Select Company',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _companySearchController,
          decoration: InputDecoration(
            labelText: 'Search Company',
            hintText: 'Enter company name',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            if (value.length >= 2) {
              _searchCompanies(value);
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
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
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
        const SizedBox(height: 16),
        const Text(
          'Requested Role (Optional)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRoleKey,
          decoration: InputDecoration(
            hintText: 'Select your desired role',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('No preference'),
            ),
            ..._predefinedRoles.map((role) => DropdownMenuItem<String>(
              value: role['key'],
              child: Text(role['label']!),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedRoleKey = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCreateCompanyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Company Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
          controller: _businessTypeController,
          decoration: InputDecoration(
            labelText: 'Business Type *',
            hintText: 'Transportation, Logistics, etc.',
            prefixIcon: const Icon(Icons.category),
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
          decoration: InputDecoration(
            labelText: 'Business Phone',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.phone,
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
            labelText: 'Pincode',
            prefixIcon: const Icon(Icons.pin_drop),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
}
