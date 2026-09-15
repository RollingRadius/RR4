import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:fleet_management/core/config/app_config.dart';
import 'package:fleet_management/data/models/receiving_document_model.dart';
import 'package:fleet_management/presentation/widgets/trip_search_field.dart';
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

/// "Receiving Docs" sidebar feature — LP/RR-ops upload one image (a
/// physical receiving sheet that can cover several trips) and link it to
/// every trip number it covers; looking up any one of those trips then
/// surfaces the same shared document.
class ReceivingDocumentsScreen extends ConsumerStatefulWidget {
  const ReceivingDocumentsScreen({super.key});

  @override
  ConsumerState<ReceivingDocumentsScreen> createState() => _ReceivingDocumentsScreenState();
}

class _ReceivingDocumentsScreenState extends ConsumerState<ReceivingDocumentsScreen> {
  bool _loading = true;
  String? _error;
  List<ReceivingDocumentModel> _docs = [];
  final _searchCtrl = TextEditingController();
  final _biltySearchCtrl = TextEditingController();
  String _query = '';
  String _biltyQuery = '';
  Timer? _debounce;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _biltySearchCtrl.dispose();
    super.dispose();
  }

  /// Fires on either search box's onChanged — mirrors the main dashboard's
  /// independent trip-number + bilty-number boxes, ANDed together server-side.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    final trip = _searchCtrl.text.trim();
    final bilty = _biltySearchCtrl.text.trim();
    if (trip.isEmpty && bilty.isEmpty) {
      // Clearing should feel instant, same as everywhere else in this feature.
      if (_query.isEmpty && _biltyQuery.isEmpty) return; // already unfiltered
      setState(() { _query = ''; _biltyQuery = ''; });
      _load();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() { _query = trip; _biltyQuery = bilty; });
      _load();
    });
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(receivingDocumentApiProvider).list(q: _query, bilty: _biltyQuery);
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

  Future<void> _openEdit(ReceivingDocumentModel doc) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _EditReceivingDocumentScreen(doc: doc)),
    );
    if (changed == true) _load();
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
            child: Row(children: [
              Expanded(
                child: TripSearchField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  hintText: 'Search trip number',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TripSearchField(
                  controller: _biltySearchCtrl,
                  onChanged: _onSearchChanged,
                  hintText: 'Search bilty number',
                ),
              ),
            ]),
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
                (_query.isEmpty && _biltyQuery.isEmpty)
                    ? 'No receiving docs uploaded yet'
                    : 'No receiving docs found for that search',
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
        itemBuilder: (_, i) => _ReceivingDocCard(doc: _docs[i], onTap: () => _openEdit(_docs[i])),
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
                Text('${doc.trips.length} trip${doc.trips.length == 1 ? '' : 's'} linked',
                    style: _manrope(size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: doc.trips.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(t.displayLabel, style: _inter(size: 11, weight: FontWeight.w600, color: _primary)),
                  )).toList(),
                ),
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
  final _tripSearchCtrl = TextEditingController();
  final _biltySearchCtrl = TextEditingController();
  final List<TripSearchResult> _selectedTrips = [];
  List<TripSearchResult> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;
  int _searchSeq = 0;
  bool _uploading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _tripSearchCtrl.dispose();
    _biltySearchCtrl.dispose();
    super.dispose();
  }

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

  /// Fires on either search box's onChanged — reads both boxes' current
  /// text and searches with whatever is non-empty, ANDed together, mirroring
  /// the main dashboard's independent trip-number + bilty-number boxes.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    final tripQ = _tripSearchCtrl.text.trim();
    final biltyQ = _biltySearchCtrl.text.trim();
    if (tripQ.isEmpty && biltyQ.isEmpty) {
      _searchSeq++; // invalidate any in-flight request for the cleared query
      setState(() { _searchResults = []; _searching = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final seq = ++_searchSeq;
    final tripQ = _tripSearchCtrl.text.trim();
    final biltyQ = _biltySearchCtrl.text.trim();
    setState(() => _searching = true);
    try {
      final results = await ref.read(receivingDocumentApiProvider).searchTrips(
        query: tripQ.isEmpty ? null : tripQ,
        biltyQuery: biltyQ.isEmpty ? null : biltyQ,
      );
      if (!mounted || seq != _searchSeq) return; // a newer search superseded this one
      final selectedIds = _selectedTrips.map((t) => t.id).toSet();
      setState(() {
        _searchResults = results.where((t) => !selectedIds.contains(t.id)).take(20).toList();
        _searching = false;
      });
    } catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() { _searching = false; _error = e.toString(); });
    }
  }

  void _addTrip(TripSearchResult trip) {
    _debounce?.cancel();
    _searchSeq++; // discard any in-flight search for the query we're clearing
    setState(() {
      _selectedTrips.add(trip);
      _searchResults = [];
      _tripSearchCtrl.clear();
      _biltySearchCtrl.clear();
    });
  }

  void _removeTrip(TripSearchResult trip) {
    setState(() => _selectedTrips.removeWhere((t) => t.id == trip.id));
  }

  Future<void> _upload() async {
    if (_image == null) {
      setState(() => _error = 'Please attach the receiving sheet image');
      return;
    }
    if (_selectedTrips.isEmpty) {
      setState(() => _error = 'Link at least one trip to this document');
      return;
    }
    setState(() { _uploading = true; _error = null; });
    try {
      final bytes = await _image!.readAsBytes();
      await ref.read(receivingDocumentApiProvider).upload(
        fileBytes: bytes,
        fileName: _image!.name,
        tripIds: _selectedTrips.map((t) => t.id).toList(),
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
          Text('Link trips this sheet covers', style: _manrope(size: 14, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Search by trip number (RR4 or RR web) and/or bilty number', style: _inter(size: 12)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TripSearchField(
                controller: _tripSearchCtrl,
                onChanged: _onSearchChanged,
                hintText: 'Search trip number',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TripSearchField(
                controller: _biltySearchCtrl,
                onChanged: _onSearchChanged,
                hintText: 'Search bilty number',
              ),
            ),
          ]),
          if (_searching) ...[
            const SizedBox(height: 8),
            const Center(child: SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primary))),
          ],
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
                itemBuilder: (_, i) {
                  final trip = _searchResults[i];
                  return ListTile(
                    dense: true,
                    title: Text(trip.displayLabel, style: _inter(size: 13, weight: FontWeight.w600)),
                    subtitle: Text('${trip.origin} → ${trip.destination}', style: _inter(size: 11)),
                    trailing: const Icon(Icons.add_circle_outline_rounded, color: _primary, size: 20),
                    onTap: () => _addTrip(trip),
                  );
                },
              ),
            ),
          ],
          if (_selectedTrips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Linked (${_selectedTrips.length})', style: _manrope(size: 13, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _selectedTrips.map((t) => Chip(
                label: Text(t.displayLabel, style: _inter(size: 12, weight: FontWeight.w600)),
                backgroundColor: _primary.withValues(alpha: 0.08),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => _removeTrip(t),
              )).toList(),
            ),
          ],
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

// ─── Edit flow — unlink existing trips / link more trips ──────────────────

class _EditReceivingDocumentScreen extends ConsumerStatefulWidget {
  final ReceivingDocumentModel doc;
  const _EditReceivingDocumentScreen({required this.doc});

  @override
  ConsumerState<_EditReceivingDocumentScreen> createState() => _EditReceivingDocumentScreenState();
}

class _EditReceivingDocumentScreenState extends ConsumerState<_EditReceivingDocumentScreen> {
  late ReceivingDocumentModel _doc;
  final _tripSearchCtrl = TextEditingController();
  final _biltySearchCtrl = TextEditingController();
  List<TripSearchResult> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;
  int _searchSeq = 0;
  bool _busy = false;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _doc = widget.doc;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tripSearchCtrl.dispose();
    _biltySearchCtrl.dispose();
    super.dispose();
  }

  /// Fires on either search box's onChanged — reads both boxes' current
  /// text and searches with whatever is non-empty, ANDed together, mirroring
  /// the main dashboard's independent trip-number + bilty-number boxes.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    final tripQ = _tripSearchCtrl.text.trim();
    final biltyQ = _biltySearchCtrl.text.trim();
    if (tripQ.isEmpty && biltyQ.isEmpty) {
      _searchSeq++; // invalidate any in-flight request for the cleared query
      setState(() { _searchResults = []; _searching = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    final seq = ++_searchSeq;
    final tripQ = _tripSearchCtrl.text.trim();
    final biltyQ = _biltySearchCtrl.text.trim();
    setState(() => _searching = true);
    try {
      final results = await ref.read(receivingDocumentApiProvider).searchTrips(
        query: tripQ.isEmpty ? null : tripQ,
        biltyQuery: biltyQ.isEmpty ? null : biltyQ,
      );
      if (!mounted || seq != _searchSeq) return; // a newer search superseded this one
      final linkedIds = _doc.trips.map((t) => t.id).toSet();
      setState(() {
        _searchResults = results.where((t) => !linkedIds.contains(t.id)).take(20).toList();
        _searching = false;
      });
    } catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() { _searching = false; _error = e.toString(); });
    }
  }

  Future<void> _addTrip(TripSearchResult trip) async {
    _debounce?.cancel();
    _searchSeq++; // discard any in-flight search for the query we're clearing
    setState(() { _busy = true; _error = null; });
    try {
      final updated = await ref.read(receivingDocumentApiProvider).addTrips(
        documentId: _doc.id,
        tripIds: [trip.id],
      );
      if (!mounted) return;
      setState(() {
        _doc = updated;
        _changed = true;
        _busy = false;
        _searchResults = [];
        _tripSearchCtrl.clear();
        _biltySearchCtrl.clear();
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _busy = false; });
    }
  }

  Future<void> _removeTrip(LinkedTripRef trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink trip?'),
        content: Text('Remove ${trip.tripNumber} from this receiving document?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlink', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() { _busy = true; _error = null; });
    try {
      final updated = await ref.read(receivingDocumentApiProvider).removeTrip(
        documentId: _doc.id,
        tripId: trip.id,
      );
      if (!mounted) return;
      setState(() { _doc = updated; _changed = true; _busy = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _onSurface, size: 20),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
          title: Text('Edit Receiving Doc', style: _manrope(size: 16, weight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                '${AppConfig.apiBaseUrl}${_doc.fileUrl}',
                height: 180, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180, color: _surface,
                  child: const Icon(Icons.image_not_supported_outlined, color: _secondary),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Link more trips', style: _manrope(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Search by trip number (RR4 or RR web) and/or bilty number', style: _inter(size: 12)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TripSearchField(
                  controller: _tripSearchCtrl,
                  onChanged: _onSearchChanged,
                  hintText: 'Search trip number',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TripSearchField(
                  controller: _biltySearchCtrl,
                  onChanged: _onSearchChanged,
                  hintText: 'Search bilty number',
                ),
              ),
            ]),
            if (_searching) ...[
              const SizedBox(height: 8),
              const Center(child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _primary))),
            ],
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: _border),
                  itemBuilder: (_, i) {
                    final trip = _searchResults[i];
                    return ListTile(
                      dense: true,
                      title: Text(trip.displayLabel, style: _inter(size: 13, weight: FontWeight.w600)),
                      subtitle: Text('${trip.origin} → ${trip.destination}', style: _inter(size: 11)),
                      trailing: const Icon(Icons.add_circle_outline_rounded, color: _primary, size: 20),
                      onTap: _busy ? null : () => _addTrip(trip),
                    );
                  },
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator(color: _primary)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: _inter(size: 12, color: Colors.red.shade700)),
            ],
            const SizedBox(height: 20),
            Text('Linked trips (${_doc.trips.length})', style: _manrope(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_doc.trips.isEmpty)
              Text('No trips linked. Search above to link some.', style: _inter(size: 12))
            else
              ..._doc.trips.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(t.displayLabel, style: _inter(size: 13, weight: FontWeight.w600, color: _onSurface))),
                    IconButton(
                      icon: const Icon(Icons.link_off_rounded, size: 18, color: Colors.red),
                      onPressed: _busy ? null : () => _removeTrip(t),
                      tooltip: 'Unlink',
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}
