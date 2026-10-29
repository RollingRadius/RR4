import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/company_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:fleet_management/l10n/app_localizations.dart';

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
  bool _isLogisticPartner = false;
  bool _isLoadOwner = false;
  bool _businessTypeError = false;
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

  // Email live-validation state
  bool _emailTouched = false;
  bool _emailValid = false;

  bool _isValidEmail(String value) {
    if (value.trim().isEmpty) return false;
    if (!value.contains('@')) return false;
    final parts = value.split('@');
    if (parts.length != 2 || parts[1].isEmpty) return false;
    if (!parts[1].contains('.')) return false;
    final domainParts = parts[1].split('.');
    if (domainParts.last.length < 2) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _businessEmailController.addListener(() {
      final valid = _isValidEmail(_businessEmailController.text);
      if (valid != _emailValid || !_emailTouched) {
        setState(() {
          _emailTouched = true;
          _emailValid = valid;
        });
      }
    });
  }

  @override
  void dispose() {
    _companyNameController.dispose();
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
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // GSTIN format: 15 characters alphanumeric
    if (value.length != 15) {
      return l10n.companyCreateGstinLength;
    }

    if (!RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(value)) {
      return l10n.companyCreateGstinInvalid;
    }

    return null;
  }

  String? _validatePAN(String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    // PAN format: 10 characters alphanumeric
    if (value.length != 10) {
      return l10n.companyCreatePanLength;
    }

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
      return l10n.companyCreatePanInvalid;
    }

    return null;
  }

  Future<void> _handleCreate() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLogisticPartner && !_isLoadOwner) {
      setState(() {
        _businessTypeError = true;
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _businessTypeError = false;
    });

    final businessType = _isLogisticPartner && _isLoadOwner
        ? 'logistic_partner'
        : _isLogisticPartner
            ? 'logistic_partner'
            : 'load_owner';

    // Prepare company data
    final companyData = {
      'company_name': _companyNameController.text.trim(),
      'business_type': businessType,
      'business_email': _businessEmailController.text.trim(),
      'business_phone': '+91${_businessPhoneController.text.trim()}',
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
              content: Text(validation['message'] ?? l10n.companyCreateInvalidDetails),
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
          SnackBar(
            content: Text(l10n.companyCreateSuccess),
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
            content: Text(error ?? l10n.companyCreateFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companyCreateTitle),
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
                  l10n.companyCreateHeading,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.companyCreateSubheading,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                // Company Information
                Text(
                  l10n.companyCreateSectionCompany,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _companyNameController,
                  decoration: InputDecoration(
                    labelText: l10n.companyCreateNameLabel,
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.authFieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.companyCreateBusinessType,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: Text(l10n.roleLogisticPartner),
                      subtitle: Text(l10n.companyCreateLpDesc),
                      value: _isLogisticPartner,
                      onChanged: (val) {
                        setState(() {
                          _isLogisticPartner = val ?? false;
                          _businessTypeError = false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: Text(l10n.roleLoadOwner),
                      subtitle: Text(l10n.companyCreateLoDesc),
                      value: _isLoadOwner,
                      onChanged: (val) {
                        setState(() {
                          _isLoadOwner = val ?? false;
                          _businessTypeError = false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_businessTypeError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                        child: Text(
                          l10n.companyCreateBusinessTypeError,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _businessEmailController,
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: l10n.companyCreateEmailLabel,
                    hintText: 'name@company.com',
                    prefixIcon: const Icon(Icons.email),
                    suffixIcon: _emailTouched
                        ? _emailValid
                            ? const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF006B5E), size: 22)
                            : const Icon(Icons.warning_rounded,
                                color: Colors.red, size: 22)
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.companyCreateEmailRequired;
                    }
                    if (!value.contains('@')) {
                      return l10n.companyCreateEmailNoAt;
                    }
                    final parts = value.split('@');
                    if (parts.length != 2 || parts[1].isEmpty) {
                      return l10n.companyCreateEmailInvalid;
                    }
                    if (!parts[1].contains('.')) {
                      return l10n.companyCreateEmailNoDomain;
                    }
                    final domainParts = parts[1].split('.');
                    if (domainParts.last.length < 2) {
                      return l10n.companyCreateEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _businessPhoneController,
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.companyCreatePhoneLabel,
                    hintText: '9876543210',
                    prefixIcon: Icon(Icons.phone),
                    prefix: Text(
                      '+91 ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.companyCreatePhoneRequired;
                    }
                    if (value.trim().length < 10) {
                      return l10n.companyCreatePhoneLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Address Information
                Text(
                  l10n.companyCreateSectionAddress,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.companyCreateAddressLabel,
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.authFieldRequired;
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
                        decoration: InputDecoration(
                          labelText: l10n.companyCreateCityLabel,
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authFieldRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: InputDecoration(
                          labelText: l10n.companyCreateStateLabel,
                          prefixIcon: Icon(Icons.map),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authFieldRequired;
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.companyCreatePincodeLabel,
                          prefixIcon: Icon(Icons.pin_drop),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authFieldRequired;
                          }
                          if (value.length != 6) {
                            return l10n.companyCreatePincodeInvalid;
                          }
                          if (value[0] == '0') {
                            return l10n.companyCreatePincodeInvalid;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: InputDecoration(
                          labelText: l10n.companyCreateCountryLabel,
                          prefixIcon: Icon(Icons.flag),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authFieldRequired;
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
                      l10n.companyCreateSectionLegal,
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
                      child: Text(_showLegalInfo ? l10n.companyCreateHide : l10n.companyCreateShow),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.companyCreateLegalHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),

                if (_showLegalInfo) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _gstinController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.companyCreateGstinLabel,
                      hintText: l10n.companyCreateGstinHint,
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    validator: _validateGSTIN,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _panController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: l10n.companyCreatePanLabel,
                      hintText: l10n.companyCreatePanHint,
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
                          : Text(l10n.companyCreateButton),
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
