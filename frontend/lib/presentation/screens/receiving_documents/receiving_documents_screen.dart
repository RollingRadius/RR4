import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/data/models/receiving_document_model.dart';
import 'package:fleet_management/providers/receiving_document_provider.dart';

const _primary = Color(0xFFFF6B00);
const _onSurface = Color(0xFF191C1E);
const _secondary = Color(0xFF546067);
const _bg = Color(0xFFF8F9FB);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFECEEF0);

TextStyle _manrope({double size = 14, FontWeight weight = FontWeight.w600, Color color = _onSurface}) =>
    GoogleFonts.manrope(fontSize: size, fontWeight: weight, color: color);
TextStyle _inter({double size = 13, FontWeight weight = FontWeight.w400, Color color = _secondary}) =>
    GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);

final _apiDateFmt = DateFormat('yyyy-MM-dd');
final _displayDateFmt = DateFormat('d MMM yyyy');

/// "Receiving Docs" sidebar feature — LP/RR-ops upload a photo of a
/// physical receiving sheet tagged with the date it's for; looking up a
/// date then surfaces every doc uploaded for that day.
class ReceivingDocumentsScreen extends ConsumerStatefulWidget {
  const ReceivingDocumentsScreen({super.key});

  @override
  ConsumerState<ReceivingDocumentsScreen> createState() => _ReceivingDocumentsScreenState();
}

class _ReceivingDocumentsScreenState extends ConsumerState<ReceivingDocumentsScreen> {
  bool _loading = true;
  String? _error;
  List<ReceivingDocumentModel> _docs = [];
  DateTime? _searchDate;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _pickSearchDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _searchDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _searchDate = picked);
    _load();
  }

  void _clearSearchDate() {
    if (_searchDate == null) return;
    setState(() => _searchDate = null);
    _load();
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(receivingDocumentApiProvider).list(
            docDate: _searchDate == null ? null : _apiDateFmt.format(_searchDate!),
          );
      if (seq != _loadSeq) return; // a newer load superseded this one
      final docs = (data['documents'] as List<dynamic>)
          .map((e) => ReceivingDocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() { _docs = docs; _loading = false; });
    } catch (e) {
      if (seq != _loadSeq) return;
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openUpload() async {
    final uploaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _UploadReceivingDocumentScreen()),
    );
    if (uploaded == true) _load();
  }

  void _openView(ReceivingDocumentModel doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ViewReceivingDocumentScreen(doc: doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Receiving Docs', style: _manrope(size: 17, weight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUpload,
        backgroundColor: _primary,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload New'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _DatePickerField(
              label: 'Search by date',
              value: _searchDate,
              onTap: _pickSearchDate,
              onClear: _searchDate == null ? null : _clearSearchDate,
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _primary));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load: $_error', style: _inter(size: 13), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_rounded, size: 48, color: _secondary),
              const SizedBox(height: 12),
              Text(
                _searchDate == null
                    ? 'No receiving docs uploaded yet'
                    : 'No receiving docs found for that date',
                style: _inter(size: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ReceivingDocCard(doc: _docs[i], onTap: () => _openView(_docs[i])),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DatePickerField({required this.label, required this.value, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: _secondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value == null ? label : _displayDateFmt.format(value!),
                style: value == null ? _inter(size: 14) : _manrope(size: 14, weight: FontWeight.w600),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 18, color: _secondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReceivingDocCard extends StatelessWidget {
  final ReceivingDocumentModel doc;
  final VoidCallback onTap;
  const _ReceivingDocCard({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              '${AppConfig.apiBaseUrl}${doc.fileUrl}',
              width: 64, height: 64, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64, height: 64, color: _bg,
                child: const Icon(Icons.image_not_supported_outlined, color: _secondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayDateFmt.format(DateTime.parse(doc.docDate)),
                    style: _manrope(size: 13, weight: FontWeight.w700)),
                if (doc.uploadedBy != null) ...[
                  const SizedBox(height: 6),
                  Text('By ${doc.uploadedBy}', style: _inter(size: 11)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _secondary),
        ],
      ),
      ),
    );
  }
}

// ─── Upload flow ────────────────────────────────────────────────────────────

class _UploadReceivingDocumentScreen extends ConsumerStatefulWidget {
  const _UploadReceivingDocumentScreen();

  @override
  ConsumerState<_UploadReceivingDocumentScreen> createState() => _UploadReceivingDocumentScreenState();
}

class _UploadReceivingDocumentScreenState extends ConsumerState<_UploadReceivingDocumentScreen> {
  XFile? _image;
  DateTime? _docDate;
  bool _uploading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (picked == null || !mounted) return;
      setState(() => _image = picked);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not pick image: $e');
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _primary),
              title: const Text('Take Photo'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _primary),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _docDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _docDate = picked);
  }

  Future<void> _upload() async {
    if (_image == null) {
      setState(() => _error = 'Please attach the receiving sheet image');
      return;
    }
    if (_docDate == null) {
      setState(() => _error = 'Please pick the date this receiving sheet is for');
      return;
    }
    setState(() { _uploading = true; _error = null; });
    try {
      final bytes = await _image!.readAsBytes();
      await ref.read(receivingDocumentApiProvider).upload(
        fileBytes: bytes,
        fileName: _image!.name,
        docDate: _apiDateFmt.format(_docDate!),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Upload Receiving Doc', style: _manrope(size: 16, weight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: _image == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_outlined, size: 32, color: _secondary),
                        const SizedBox(height: 8),
                        Text('Attach receiving sheet photo', style: _inter(size: 13)),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: FutureBuilder<Uint8List>(
                        future: _image!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator(color: _primary));
                          }
                          return Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity);
                        },
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Date this sheet is for', style: _manrope(size: 14, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          _DatePickerField(label: 'Pick a date', value: _docDate, onTap: _pickDocDate),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: _inter(size: 12, color: Colors.red.shade700)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _uploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _uploading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Upload'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── View flow ──────────────────────────────────────────────────────────────

class _ViewReceivingDocumentScreen extends StatelessWidget {
  final ReceivingDocumentModel doc;
  const _ViewReceivingDocumentScreen({required this.doc});

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${AppConfig.apiBaseUrl}${doc.fileUrl}';
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Receiving Doc', style: _manrope(size: 16, weight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              imageUrl,
              height: 260, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 260, color: _surface,
                child: const Icon(Icons.image_not_supported_outlined, color: _secondary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Date', style: _inter(size: 12)),
          const SizedBox(height: 2),
          Text(_displayDateFmt.format(DateTime.parse(doc.docDate)), style: _manrope(size: 15, weight: FontWeight.w700)),
          if (doc.uploadedBy != null) ...[
            const SizedBox(height: 14),
            Text('Uploaded by', style: _inter(size: 12)),
            const SizedBox(height: 2),
            Text(doc.uploadedBy!, style: _manrope(size: 14, weight: FontWeight.w600)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(imageUrl), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Open / Download'),
              style: OutlinedButton.styleFrom(foregroundColor: _primary),
            ),
          ),
        ],
      ),
    );
  }
}
