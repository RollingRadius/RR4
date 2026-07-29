import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _secondary = Color(0xFF546067);

/// A debounced async-search text field with a suggestions dropdown —
/// used by the RR quick-add screens (Add Vehicle/Company/User) wherever
/// they need to look up an existing RR user/company/engine-model by
/// typing a few characters, since this app has no flutter_typeahead
/// dependency and each screen would otherwise duplicate this logic.
class RrSearchField<T> extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final Future<List<T>> Function(String query) search;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;
  final void Function(T item) onSelected;
  final VoidCallback? onCleared;
  final TextInputType keyboardType;
  final String? hintText;

  const RrSearchField({
    super.key,
    required this.label,
    required this.controller,
    required this.search,
    required this.itemLabel,
    required this.onSelected,
    this.itemSubtitle,
    this.onCleared,
    this.keyboardType = TextInputType.text,
    this.hintText,
  });

  @override
  State<RrSearchField<T>> createState() => _RrSearchFieldState<T>();
}

class _RrSearchFieldState<T> extends State<RrSearchField<T>> {
  Timer? _debounce;
  List<T> _results = [];
  bool _loading = false;
  bool _showResults = false;
  // Debounce only cancels the pending *timer* — an in-flight network call from
  // an earlier keystroke isn't cancelled by it. If that older, more generic
  // query (e.g. a single typed letter, matching far more rows) resolves AFTER
  // a later, more specific one, it can silently overwrite the list with stale,
  // wrong results the user never actually searched for — and RR's own
  // `get_user_by_phone` name search returns unsorted natural-DB-order matches,
  // so an old test/seed account can easily be among a short query's top hits.
  // Tag each request and only apply the response if it's still the latest.
  int _requestId = 0;

  void _onChanged(String q) {
    widget.onCleared?.call();
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      _requestId++;
      setState(() { _results = []; _showResults = false; });
      return;
    }
    setState(() { _loading = true; _showResults = true; });
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final myRequestId = ++_requestId;
      try {
        final items = await widget.search(q.trim());
        if (!mounted || myRequestId != _requestId) return;
        setState(() { _results = items; _loading = false; });
      } catch (_) {
        if (!mounted || myRequestId != _requestId) return;
        setState(() { _results = []; _loading = false; });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _onChanged,
        ),
        if (_showResults && !_loading && _results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text('No matches found',
                style: GoogleFonts.inter(fontSize: 12, color: _secondary)),
          ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E5E8)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final item = _results[i];
                return ListTile(
                  dense: true,
                  title: Text(widget.itemLabel(item),
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                  subtitle: widget.itemSubtitle != null
                      ? Text(widget.itemSubtitle!(item),
                          style: GoogleFonts.inter(fontSize: 12, color: _secondary))
                      : null,
                  onTap: () {
                    widget.onSelected(item);
                    setState(() { _results = []; _showResults = false; });
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
