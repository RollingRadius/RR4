import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/data/models/branding_model.dart';
import 'package:fleet_management/providers/branding_provider.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class BrandingSettingsScreen extends ConsumerStatefulWidget {
  const BrandingSettingsScreen({super.key});

  @override
  ConsumerState<BrandingSettingsScreen> createState() =>
      _BrandingSettingsScreenState();
}

class _BrandingSettingsScreenState
    extends ConsumerState<BrandingSettingsScreen> {
  // Color editing state
  BrandingColors? _editedColors;
  bool _hasChanges = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load branding on init
    Future.microtask(() => ref.read(brandingProvider.notifier).loadBranding());
  }

  @override
  Widget build(BuildContext context) {
    final brandingState = ref.watch(brandingProvider);
    final currentBranding = brandingState.branding;

    // Initialize edited colors from current branding
    if (_editedColors == null && currentBranding != null) {
      _editedColors = currentBranding.colors;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branding Settings'),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
      ),
      body: brandingState.isLoading && currentBranding == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Section
                  FadeSlide(delay: 0, child: _buildLogoSection(currentBranding)),

                  const SizedBox(height: 24),

                  // Colors Section
                  FadeSlide(delay: 100, child: _buildColorsSection()),

                  const SizedBox(height: 24),

                  // Preview Section
                  FadeSlide(delay: 200, child: _buildPreviewSection()),

                  const SizedBox(height: 24),

                  // Messages
                  if (brandingState.successMessage != null)
                    FadeSlide(delay: 300, child: _buildSuccessMessage(brandingState.successMessage!)),

                  if (brandingState.error != null)
                    _buildErrorMessage(brandingState.error!),
                ],
              ),
            ),
    );
  }

  Widget _buildLogoSection(OrganizationBranding? branding) {
    final brandingState = ref.watch(brandingProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Logo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Logo preview
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.textTertiary.withOpacity(0.3)),
              ),
              child: branding?.logo?.url != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        branding!.getLogoUrl(AppConfig.apiBaseUrl) ?? '',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          );
                        },
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, size: 48, color: AppTheme.textTertiary),
                          SizedBox(height: 8),
                          Text('No logo uploaded', style: TextStyle(color: AppTheme.textTertiary)),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Logo actions
            if (brandingState.isUploading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  if (branding?.logo?.url == null)
                    ElevatedButton.icon(
                      onPressed: _uploadLogo,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Logo'),
                    )
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _uploadLogo,
                      icon: const Icon(Icons.change_circle),
                      label: const Text('Change Logo'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _deleteLogo,
                      icon: const Icon(Icons.delete),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.statusError,
                        side: const BorderSide(color: AppTheme.statusError),
                      ),
                    ),
                  ],
                ],
              ),

            const SizedBox(height: 8),
            Text(
              'Supported formats: PNG, JPG, JPEG, SVG (max 2MB)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorsSection() {
    if (_editedColors == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand Colors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _buildColorTile('Primary Color', _editedColors!.primaryColor,
                (color) => _updateColor('primary', color)),
            _buildColorTile('Primary Dark', _editedColors!.primaryDark,
                (color) => _updateColor('primaryDark', color)),
            _buildColorTile('Primary Light', _editedColors!.primaryLight,
                (color) => _updateColor('primaryLight', color)),
            _buildColorTile('Secondary Color', _editedColors!.secondaryColor,
                (color) => _updateColor('secondary', color)),
            _buildColorTile('Accent Color', _editedColors!.accentColor,
                (color) => _updateColor('accent', color)),
            _buildColorTile('Background Primary', _editedColors!.backgroundPrimary,
                (color) => _updateColor('backgroundPrimary', color)),
            _buildColorTile('Background Secondary', _editedColors!.backgroundSecondary,
                (color) => _updateColor('backgroundSecondary', color)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTile(
      String label, String hexColor, Function(Color) onColorChanged) {
    final color = _parseHexColor(hexColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showColorPicker(label, color, onColorChanged),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.textTertiary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              // Color preview
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 12),

              // Label and hex
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      hexColor.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const Icon(Icons.edit, size: 20, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_editedColors == null) return const SizedBox.shrink();

    final primaryColor = _parseHexColor(_editedColors!.primaryColor);
    final secondaryColor = _parseHexColor(_editedColors!.secondaryColor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Preview buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Primary Button'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                  ),
                  child: const Text('Outlined Button'),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                  child: const Text('Text Button'),
                ),
                Chip(
                  label: const Text('Chip'),
                  backgroundColor: primaryColor.withOpacity(0.15),
                ),
                Chip(
                  label: const Text('Secondary'),
                  backgroundColor: secondaryColor.withOpacity(0.15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.statusActive.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.statusActive.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.statusActive),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => ref.read(brandingProvider.notifier).clearMessages(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.statusError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.statusError.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: AppTheme.statusError),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => ref.read(brandingProvider.notifier).clearMessages(),
          ),
        ],
      ),
    );
  }

  // Actions

  Future<void> _uploadLogo() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await ref.read(brandingProvider.notifier).uploadLogo(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _deleteLogo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Logo'),
        content: const Text('Are you sure you want to delete the logo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(brandingProvider.notifier).deleteLogo();
    }
  }

  void _showColorPicker(
      String label, Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $label'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _updateColor(String colorKey, Color color) {
    if (_editedColors == null) return;

    final hexColor = _colorToHex(color);

    setState(() {
      switch (colorKey) {
        case 'primary':
          _editedColors = _editedColors!.copyWith(primaryColor: hexColor);
          break;
        case 'primaryDark':
          _editedColors = _editedColors!.copyWith(primaryDark: hexColor);
          break;
        case 'primaryLight':
          _editedColors = _editedColors!.copyWith(primaryLight: hexColor);
          break;
        case 'secondary':
          _editedColors = _editedColors!.copyWith(secondaryColor: hexColor);
          break;
        case 'accent':
          _editedColors = _editedColors!.copyWith(accentColor: hexColor);
          break;
        case 'backgroundPrimary':
          _editedColors = _editedColors!.copyWith(backgroundPrimary: hexColor);
          break;
        case 'backgroundSecondary':
          _editedColors = _editedColors!.copyWith(backgroundSecondary: hexColor);
          break;
      }
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (_editedColors == null) return;

    await ref.read(brandingProvider.notifier).updateColors(
          colors: _editedColors!,
        );

    setState(() {
      _hasChanges = false;
    });
  }

  Color _parseHexColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppTheme.primaryBlue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
