import 'package:flutter/material.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  final _specialSkillsController = TextEditingController();

  final List<Map<String, dynamic>> _certifications = [
    {'id': 'defensive', 'label': 'Defensive Driving', 'checked': true},
    {'id': 'hazmat', 'label': 'HAZMAT Handling', 'checked': false},
    {'id': 'firstaid', 'label': 'First Aid/CPR', 'checked': true},
    {'id': 'fuel', 'label': 'Fuel Efficiency Training', 'checked': false},
  ];

  @override
  void dispose() {
    _specialSkillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkedCerts = _certifications.where((c) => c['checked'] == true).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Sticky header
          Material(
            color: _bg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    // Title row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Onboarding',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'STEP 2 OF 3',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text('66% Complete',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: 0.66,
                              minHeight: 8,
                              backgroundColor: _primary.withAlpha(40),
                              valueColor: const AlwaysStoppedAnimation(_primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Section heading
                const Text(
                  'Training & Certifications',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide details of your professional certifications and specialized skills.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.4),
                ),
                const SizedBox(height: 24),

                // Core Certifications
                const _SubHeader(text: 'CORE CERTIFICATIONS'),
                const SizedBox(height: 10),
                ..._certifications.asMap().entries.map((entry) {
                  final cert = entry.value;
                  final isChecked = cert['checked'] as bool;
                  return _CertCheckbox(
                    label: cert['label'] as String,
                    checked: isChecked,
                    onChanged: (val) {
                      setState(() => _certifications[entry.key]['checked'] = val ?? false);
                    },
                  );
                }),
                const SizedBox(height: 24),

                // Certification Details (shown for checked items)
                if (checkedCerts.isNotEmpty) ...[
                  const _SubHeader(text: 'CERTIFICATION DETAILS'),
                  const SizedBox(height: 10),
                  ...checkedCerts.map((cert) => _CertDetailCard(label: cert['label'] as String)),
                  const SizedBox(height: 24),
                ],

                // Specialized Skills
                const _SubHeader(text: 'SPECIALIZED SKILLS'),
                const SizedBox(height: 8),
                Text(
                  'List any other relevant qualifications or equipment experience (e.g., forklift license, refrigerated cargo handling).',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: TextField(
                    controller: _specialSkillsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      hintText: 'Type your additional skills here...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Sticky footer
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: _bg,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Next: Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String text;

  const _SubHeader({required this.text});

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _primary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _CertCheckbox extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  const _CertCheckbox({required this.label, required this.checked, required this.onChanged});

  static const _primary = Color(0xFFEC5B13);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checked ? _primary.withAlpha(80) : Colors.grey[200]!,
          width: checked ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: _primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
          if (checked)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.verified, color: _primary, size: 20),
            ),
        ],
      ),
    );
  }
}

class _CertDetailCard extends StatefulWidget {
  final String label;

  const _CertDetailCard({required this.label});

  @override
  State<_CertDetailCard> createState() => _CertDetailCardState();
}

class _CertDetailCardState extends State<_CertDetailCard> {
  DateTime? _completionDate;
  DateTime? _expirationDate;

  static const _primary = Color(0xFFEC5B13);

  Future<void> _pickDate(DateTime? initial, void Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primary.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const Icon(Icons.edit, color: _primary, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniDate(
                label: 'COMPLETION DATE',
                date: _completionDate,
                onTap: () => _pickDate(_completionDate, (d) => setState(() => _completionDate = d)),
                formatDate: _formatDate,
              )),
              const SizedBox(width: 12),
              Expanded(child: _MiniDate(
                label: 'EXPIRATION DATE',
                date: _expirationDate,
                onTap: () => _pickDate(_expirationDate, (d) => setState(() => _expirationDate = d)),
                formatDate: _formatDate,
              )),
            ],
          ),
          const SizedBox(height: 12),
          // Upload area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primary.withAlpha(80), style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.upload_file, color: _primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Upload Certificate (PDF/JPG)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.cloud_upload, color: _primary, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDate extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final String Function(DateTime?) formatDate;

  const _MiniDate({
    required this.label,
    required this.date,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[500])),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatDate(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: date != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
