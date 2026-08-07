import 'package:flutter/material.dart';

/// Compact search field for filtering an already-loaded trip list by trip
/// number, reused across the Fleet Status / RR Web Trips sections of the LP,
/// FE, and RR-ops dashboards.
class TripSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const TripSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search by trip number',
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF5F6F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}

/// Case-insensitive match against a trip's own trip number and, if present,
/// its RR-assigned trip number — users may search by either.
bool matchesTripSearch(String query, String tripNumber, String? rrTripNumber) {
  if (query.isEmpty) return true;
  final q = query.trim().toLowerCase();
  if (tripNumber.toLowerCase().contains(q)) return true;
  if (rrTripNumber != null && rrTripNumber.toLowerCase().contains(q)) return true;
  return false;
}

/// Case-insensitive match against a trip's Stage 4 Bilty Number.
bool matchesBiltySearch(String query, String? biltyNumber) {
  if (query.isEmpty) return true;
  if (biltyNumber == null || biltyNumber.isEmpty) return false;
  return biltyNumber.toLowerCase().contains(query.trim().toLowerCase());
}
