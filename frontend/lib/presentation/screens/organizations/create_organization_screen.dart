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
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

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
        // Refresh JWT token to include new organization context
        await ref.read(authProvider.notifier).refreshToken();

        // Reload user organizations
        await ref.read(organizationProvider.notifier).loadOrganizations();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Organization "${response['company_name']}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to dashboard
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create organization: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Organization'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlide(
                delay: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Company Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        hintText: 'Enter company name',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Company name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Company name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Business Type *',
                        hintText: 'e.g., Transportation, Logistics',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business type is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeSlide(
                delay: 100,
                child: const Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              FadeSlide(
                delay: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _businessEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Business Email *',
                        hintText: 'company@example.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business email is required';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Invalid email format';
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
                        hintText: '+91 1234567890',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business phone is required';
                        }
                        if (value.trim().length < 10) {
                          return 'Phone number must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeSlide(
                delay: 200,
                child: const Text(
                  'Address',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  hintText: 'Street address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
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
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'City is required';
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
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'State is required';
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
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pincode is required';
                        }
                        if (value.trim().length != 6) {
                          return 'Invalid pincode';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FadeSlide(
                delay: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showLegalInfo = !_showLegalInfo;
                        });
                      },
                      icon: Icon(_showLegalInfo
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down),
                      label: Text(
                        _showLegalInfo
                            ? 'Hide Legal Information (Optional)'
                            : 'Add Legal Information (Optional)',
                      ),
                    ),
                    if (_showLegalInfo) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Legal Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gstinController,
                        decoration: const InputDecoration(
                          labelText: 'GSTIN (Optional)',
                          hintText: '15 characters',
                          prefixIcon: Icon(Icons.receipt_long),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateGSTIN,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _panController,
                        decoration: const InputDecoration(
                          labelText: 'PAN Number (Optional)',
                          hintText: '10 characters',
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validatePAN,
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isCreating ? null : _handleCreate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create Organization'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isCreating ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
