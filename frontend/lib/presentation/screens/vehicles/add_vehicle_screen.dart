import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fleet_management/data/services/vehicle_api.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/providers/vehicle_provider.dart';
import 'package:fleet_management/l10n/app_localizations.dart';
import 'package:fleet_management/core/utils/vehicle_driver_labels.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  final _vehicleNumberController = TextEditingController();
  final _vinController = TextEditingController();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _odometerController = TextEditingController();

  String _fuelType = 'diesel';
  String _vehicleType = 'car';
  String? _selectedImagePath;
  Uint8List? _selectedImageBytes; // for web-safe preview
  bool _isSubmitting = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _vinController.dispose();
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.vehAddChoosePhoto,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: _primary),
                ),
                title: Text(l10n.stageCommonChooseGallery),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: _primary),
                ),
                title: Text(l10n.vehAddTakePhoto),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              if (_selectedImagePath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: Text(l10n.vehAddRemovePhoto,
                      style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    setState(() => _selectedImagePath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImagePath = picked.path;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _handleSubmit() async {
    final l10n = AppLocalizations.of(context);
    final vehicleNumber = _vehicleNumberController.text.trim();
    final plate = _plateController.text.trim();
    final make = _makeController.text.trim();
    final model = _modelController.text.trim();
    final yearText = _yearController.text.trim();

    if (vehicleNumber.isEmpty || plate.isEmpty || make.isEmpty ||
        model.isEmpty || yearText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.vehAddFillRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final year = int.tryParse(yearText);
    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.vehAddInvalidYear),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final vehicleApi = VehicleApi(apiService);

      // Step 1: Create vehicle
      final result = await vehicleApi.createVehicle(
        vehicleNumber: vehicleNumber,
        registrationNumber: plate,
        manufacturer: make,
        model: model,
        year: year,
        vehicleType: _vehicleType,
        fuelType: _fuelType,
        currentOdometer: int.tryParse(_odometerController.text.trim()) ?? 0,
        vinNumber: _vinController.text.trim(),
      );

      final vehicleId = result['vehicle_id'] as String?;

      // Step 2: Upload photo if selected
      String? photoError;
      if (vehicleId != null && _selectedImagePath != null) {
        try {
          await vehicleApi.uploadVehiclePhoto(
            vehicleId: vehicleId,
            filePath: _selectedImagePath!,
          );
        } catch (e) {
          photoError = e.toString().replaceFirst('Exception: ', '');
          debugPrint('Photo upload error: $e');
        }
      }

      if (mounted) {
        // Refresh vehicle list
        ref.read(vehicleProvider.notifier).loadVehicles();

        if (photoError != null) {
          // Show vehicle created but photo failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.vehAddPhotoFailed(photoError)),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.vehAddSuccess),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        }
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.lpDashAddVehicle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoSection(),
            _buildSection(l10n.vehAddSectionIdentification, Column(
              children: [
                _buildField(l10n.vehAddVehicleNumber, _vehicleNumberController,
                    hint: l10n.vehAddHintExample('VH-001')),
                const SizedBox(height: 12),
                _buildField(l10n.vehAddLicensePlate, _plateController,
                    hint: 'ABC-1234'),
                const SizedBox(height: 12),
                _buildField(l10n.vehAddVin, _vinController,
                    hint: l10n.vehAddVinHint),
              ],
            )),
            _buildSection(l10n.vehAddSectionSpecifications, Column(
              children: [
                _buildField(l10n.vehAddMake, _makeController, hint: l10n.vehAddHintExample('Ford')),
                const SizedBox(height: 12),
                _buildField(l10n.vehAddModel, _modelController, hint: l10n.vehAddHintExample('F-150')),
                const SizedBox(height: 12),
                _buildField(l10n.vehAddYear, _yearController, hint: '2024',
                    keyboardType: TextInputType.number),
              ],
            )),
            _buildSection(l10n.vehAddSectionTechnical, Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.vehAddVehicleType,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _buildVehicleTypeSelector(),
                const SizedBox(height: 16),
                Text(l10n.vehAddFuelType,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _buildFuelToggle(),
                const SizedBox(height: 16),
                _buildOdometerField(),
              ],
            )),
            _buildInfoNote(),
          ],
        ),
      ),
      bottomNavigationBar: _buildFooter(context),
    );
  }

  Widget _buildPhotoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _pickPhoto,
        child: _selectedImagePath != null
            ? _buildPhotoPreview()
            : _buildPhotoPlaceholder(),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_a_photo_outlined,
                color: _primary, size: 32),
          ),
          const SizedBox(height: 10),
          Text(l10n.vehAddPhotoTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(l10n.vehAddPhotoSubtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
                color: _primary, borderRadius: BorderRadius.circular(10)),
            child: Text(l10n.vehAddChooseFile,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: kIsWeb
              ? Image.memory(
                  _selectedImageBytes!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(_selectedImagePath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(AppLocalizations.of(context).driverSelectVehicleChange,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String? hint, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeSelector() {
    final l10n = AppLocalizations.of(context);
    const types = [
      ('car', Icons.directions_car_outlined),
      ('truck', Icons.local_shipping_outlined),
      ('van', Icons.airport_shuttle_outlined),
      ('bus', Icons.directions_bus_outlined),
      ('motorcycle', Icons.two_wheeler_outlined),
      ('other', Icons.commute_outlined),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final selected = _vehicleType == t.$1;
        return GestureDetector(
          onTap: () => setState(() => _vehicleType = t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? _primary : Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$2,
                    size: 16,
                    color: selected ? Colors.white : Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  vehicleTypeLabel(l10n, t.$1),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFuelToggle() {
    final l10n = AppLocalizations.of(context);
    const options = [
      ('diesel', 'Diesel'),
      ('petrol', 'Petrol'),
      ('electric', 'Electric'),
      ('hybrid', 'Hybrid'),
      ('cng', 'CNG'),
      ('lpg', 'LPG'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final selected = _fuelType == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _fuelType = opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _primary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? _primary : Colors.grey.shade300),
            ),
            child: Text(
              fuelTypeLabel(l10n, opt.$1),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? _primary : Colors.grey.shade600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOdometerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).vehAddOdometer,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _odometerController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: const Icon(Icons.speed_outlined,
                color: Colors.grey, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: _primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).vehAddInfoNote,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade700, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _handleSubmit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(_isSubmitting ? AppLocalizations.of(context).vehAddRegistering : AppLocalizations.of(context).vehAddRegister),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _primary.withOpacity(0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}
