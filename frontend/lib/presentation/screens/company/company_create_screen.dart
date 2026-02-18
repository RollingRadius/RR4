import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/company_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class CompanyCreateScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? signupData;

  const CompanyCreateScreen({super.key, this.signupData});

  @override
  ConsumerState<CompanyCreateScreen> createState() =>
      _CompanyCreateScreenState();
}

class _CompanyCreateScreenState extends ConsumerState<CompanyCreateScreen> {
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
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // GSTIN format: 15 characters alphanumeric
    if (value.length != 15) {
      return 'GSTIN must be exactly 15 characters';
    }

    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(value)) {
      return 'Invalid GSTIN format';
    }

    return null;
  }

  String? _validatePAN(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // PAN format: 10 characters alphanumeric
    if (value.length != 10) {
      return 'PAN must be exactly 10 characters';
    }

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
      return 'Invalid PAN format';
    }

    return null;
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    // Prepare company data
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
        'gstin': _gstinController.text.trim().toUpperCase(),
      if (_panController.text.isNotEmpty)
        'pan_number': _panController.text.trim().toUpperCase(),
    };

    // Validate GSTIN/PAN if provided
    if (_gstinController.text.isNotEmpty || _panController.text.isNotEmpty) {
      final validation = await ref.read(companyProvider.notifier).validateCompanyDetails(
        gstin: _gstinController.text.isNotEmpty ? _gstinController.text.trim() : null,
        panNumber: _panController.text.isNotEmpty ? _panController.text.trim() : null,
      );

      if (validation != null && mounted) {
        if (validation['valid'] == false) {
          setState(() {
            _isCreating = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validation['message'] ?? 'Invalid company details'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    // Complete signup with new company
    final updatedSignupData = {
      ...?widget.signupData,
      'company_type': 'new',
      'company_details': companyData,
    };

    final response = await ref.read(authProvider.notifier).signup(updatedSignupData);

    if (mounted) {
      setState(() {
        _isCreating = false;
      });

      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Company created successfully! You are now the Owner.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to appropriate screen based on auth method
        if (widget.signupData?['auth_method'] == AppConstants.authMethodEmail) {
          context.go('/verify-email',
              extra: {'email': widget.signupData?['email']});
        } else {
          context.go(AppConstants.routeLogin);
        }
      } else {
        final error = ref.read(authProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Company creation failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Company'),
      ),
      body: SafeArea(
        child: PageEntrance(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Register Your Company',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You will become the company Owner with full administrative access.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                // Company Information
                Text(
                  'Company Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.validationRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _businessTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Business Type *',
                    hintText: 'e.g., Logistics, Transportation',
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.validationRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _businessEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Business Email *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.validationRequired;
                    }
                    if (!value.contains('@')) {
                      return AppConstants.validationEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _businessPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Business Phone *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.validationRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Address Information
                Text(
                  'Address Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppConstants.validationRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppConstants.validationRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'State *',
                          prefixIcon: Icon(Icons.map),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppConstants.validationRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Pincode *',
                          prefixIcon: Icon(Icons.pin_drop),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppConstants.validationRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country *',
                          prefixIcon: Icon(Icons.flag),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppConstants.validationRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Legal Information (Optional)
                Row(
                  children: [
                    Text(
                      'Legal Information (Optional)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showLegalInfo = !_showLegalInfo;
                        });
                      },
                      child: Text(_showLegalInfo ? 'Hide' : 'Show'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You can add GSTIN and PAN details now or later from company settings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),

                if (_showLegalInfo) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstinController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'GSTIN (Optional)',
                      hintText: '15-character GSTIN',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    validator: _validateGSTIN,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _panController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'PAN Number (Optional)',
                      hintText: '10-character PAN',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    validator: _validatePAN,
                  ),
                ],

                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _handleCreate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Create Company'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),  // closes SingleChildScrollView
        ),  // closes PageEntrance
      ),
    );
  }
}
