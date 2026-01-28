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
  final _formKey = GlobalKey<FormState>();

  // Basic Information Controllers
  final _employeeIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  DateTime _joinDate = DateTime.now();

  // Address Information Controllers
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedState;
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  // License Information Controllers
  final _licenseNumberController = TextEditingController();
  String _licenseType = 'LMV';
  DateTime? _issueDate;
  DateTime? _expiryDate;
  final _issuingAuthorityController = TextEditingController();
  String? _issuingState;

  // Emergency Contact Controllers
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  String? _emergencyContactRelationship;

  bool _isSubmitting = false;

  // Indian States
  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Jammu and Kashmir', 'Ladakh'
  ];

  // License Types
  final List<Map<String, String>> _licenseTypes = [
    {'value': 'LMV', 'label': 'LMV (Light Motor Vehicle)'},
    {'value': 'HMV', 'label': 'HMV (Heavy Motor Vehicle)'},
    {'value': 'MCWG', 'label': 'MCWG (Motorcycle with Gear)'},
    {'value': 'HPMV', 'label': 'HPMV (Heavy Passenger Motor Vehicle)'},
  ];

  // Emergency Contact Relationships
  final List<String> _relationships = [
    'Parent', 'Spouse', 'Sibling', 'Friend', 'Relative', 'Other'
  ];

  @override
  void dispose() {
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

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Phone number must be 10 digits';
    }
    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field
    final pincodeRegex = RegExp(r'^\d{6}$');
    if (!pincodeRegex.hasMatch(value)) {
      return 'Pincode must be 6 digits';
    }
    return null;
  }

  String? _validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'License number is required';
    }
    final licenseRegex = RegExp(r'^[A-Z0-9\-]{10,50}$');
    if (!licenseRegex.hasMatch(value.toUpperCase())) {
      return 'License number must be 10-50 alphanumeric characters';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context, DateTime? initialDate, Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form')),
      );
      return;
    }

    // Validate dates
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Build driver data
      final Map<String, dynamic> driverData = {
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

      // Add optional fields
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
      if (_selectedState != null) {
        driverData['state'] = _selectedState;
      }
      if (_pincodeController.text.isNotEmpty) {
        driverData['pincode'] = _pincodeController.text.trim();
      }
      if (_issuingAuthorityController.text.isNotEmpty) {
        (driverData['license'] as Map<String, dynamic>)['issuing_authority'] = _issuingAuthorityController.text.trim();
      }
      if (_issuingState != null) {
        (driverData['license'] as Map<String, dynamic>)['issuing_state'] = _issuingState;
      }
      if (_emergencyContactNameController.text.isNotEmpty) {
        driverData['emergency_contact_name'] = _emergencyContactNameController.text.trim();
      }
      if (_emergencyContactPhoneController.text.isNotEmpty) {
        driverData['emergency_contact_phone'] = _emergencyContactPhoneController.text.trim();
      }
      if (_emergencyContactRelationship != null) {
        driverData['emergency_contact_relationship'] = _emergencyContactRelationship;
      }

      // Submit via provider
      final success = await ref.read(driverProvider.notifier).addDriver(driverData);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver added successfully!')),
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(driverProvider).error ?? 'Failed to add driver';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Driver'),
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Basic Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(
                        labelText: 'Employee ID *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., DRV001',
                      ),
                      validator: (value) => _validateRequired(value, 'Employee ID'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => _validateRequired(value, 'First name'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => _validateRequired(value, 'Last name'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'example@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone *',
                        border: OutlineInputBorder(),
                        hintText: '10-digit number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date of Birth (Optional)'),
                      subtitle: Text(
                        _dateOfBirth != null
                            ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                            : 'Not selected',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, _dateOfBirth, (date) {
                        setState(() {
                          _dateOfBirth = date;
                        });
                      }),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Join Date *'),
                      subtitle: Text(
                        '${_joinDate.day}/${_joinDate.month}/${_joinDate.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, _joinDate, (date) {
                        setState(() {
                          _joinDate = date;
                        });
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City (Optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedState,
                            decoration: const InputDecoration(
                              labelText: 'State (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            items: _indianStates.map((state) {
                              return DropdownMenuItem(
                                value: state,
                                child: Text(state),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedState = value;
                              });
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
                            decoration: const InputDecoration(
                              labelText: 'Pincode (Optional)',
                              border: OutlineInputBorder(),
                              hintText: '6 digits',
                            ),
                            keyboardType: TextInputType.number,
                            validator: _validatePincode,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              border: OutlineInputBorder(),
                            ),
                            enabled: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // License Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'License Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _licenseNumberController,
                      decoration: const InputDecoration(
                        labelText: 'License Number *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., DL1420110012345',
                      ),
                      validator: _validateLicenseNumber,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _licenseType,
                      decoration: const InputDecoration(
                        labelText: 'License Type *',
                        border: OutlineInputBorder(),
                      ),
                      items: _licenseTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _licenseType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Issue Date *'),
                            subtitle: Text(
                              _issueDate != null
                                  ? '${_issueDate!.day}/${_issueDate!.month}/${_issueDate!.year}'
                                  : 'Not selected',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context, _issueDate, (date) {
                              setState(() {
                                _issueDate = date;
                              });
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Expiry Date *'),
                            subtitle: Text(
                              _expiryDate != null
                                  ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                                  : 'Not selected',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () => _selectDate(context, _expiryDate, (date) {
                              setState(() {
                                _expiryDate = date;
                              });
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _issuingAuthorityController,
                      decoration: const InputDecoration(
                        labelText: 'Issuing Authority (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _issuingState,
                      decoration: const InputDecoration(
                        labelText: 'Issuing State (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: _indianStates.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _issuingState = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Contact Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Contact',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyContactNameController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyContactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone (Optional)',
                        border: OutlineInputBorder(),
                        hintText: '10-digit number',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _emergencyContactRelationship,
                      decoration: const InputDecoration(
                        labelText: 'Relationship (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: _relationships.map((relationship) {
                        return DropdownMenuItem(
                          value: relationship,
                          child: Text(relationship),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _emergencyContactRelationship = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Driver', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
