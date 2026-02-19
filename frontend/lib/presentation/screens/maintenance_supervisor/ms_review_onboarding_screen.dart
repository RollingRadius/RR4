import 'package:flutter/material.dart';

class MsReviewOnboardingScreen extends StatefulWidget {
  const MsReviewOnboardingScreen({super.key});

  @override
  State<MsReviewOnboardingScreen> createState() => _MsReviewOnboardingScreenState();
}

class _MsReviewOnboardingScreenState extends State<MsReviewOnboardingScreen> {
  static const _primary = Color(0xFFEC5B13);
  static const _bg = Color(0xFFF8F6F6);

  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _buildProfileSection(),
                const SizedBox(height: 20),
                _buildPersonalDetails(),
                const SizedBox(height: 16),
                _buildLicenseInfo(),
                const SizedBox(height: 16),
                _buildCertifications(),
                const SizedBox(height: 16),
                _buildAssignedLogistics(),
                const SizedBox(height: 20),
                _buildConfirmCheckbox(),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildFooter(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: Colors.white.withOpacity(0.9),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: _primary),
                  ),
                  const Expanded(
                    child: Text(
                      'Review & Submit',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ProgressDot(active: false),
                  const SizedBox(width: 10),
                  _ProgressDot(active: false),
                  const SizedBox(width: 10),
                  _ProgressDot(active: true, wide: true),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E2E2)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 116, height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE2D9F3),
                border: Border.all(color: _primary.withOpacity(0.25), width: 4),
                boxShadow: [BoxShadow(color: _primary.withOpacity(0.15), blurRadius: 24, spreadRadius: 2)],
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            Positioned(
              bottom: 0, right: 110,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Johnathan Miller', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Class A Commercial Driver', style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildPersonalDetails() {
    return _InfoCard(
      icon: Icons.person_outline,
      title: 'Personal Details',
      onEdit: () {},
      children: [
        _InfoRow(label: 'Email', value: 'j.miller@logistics.com'),
        _InfoRow(label: 'Phone', value: '+1 (555) 902-4421'),
        _InfoRow(label: 'Address', value: '124 Industrial Pkwy,\nChicago, IL 60601'),
      ],
    );
  }

  Widget _buildLicenseInfo() {
    return _InfoCard(
      icon: Icons.badge_outlined,
      title: 'License Information',
      onEdit: () {},
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LICENSE NO.', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('IL-99023411', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CLASS', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('CDL Class A', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EXPIRES', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('Oct 12, 2028', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DOCUMENT SCAN', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              width: 140, height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _primary.withOpacity(0.1)),
              ),
              child: const Icon(Icons.description_outlined, size: 36, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCertifications() {
    return _InfoCard(
      icon: Icons.verified_outlined,
      title: 'Certifications',
      onEdit: () {},
      children: [
        _CertRow(name: 'Hazmat Handling Safety', date: 'Completed: Sep 2023'),
        const SizedBox(height: 8),
        _CertRow(name: 'Advanced Logistics Tech', date: 'Completed: Aug 2023'),
      ],
    );
  }

  Widget _buildAssignedLogistics() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _primary.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: _primary, size: 20),
                const SizedBox(width: 8),
                const Text('Assigned Logistics', style: TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_car_outlined, color: _primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Freightliner Cascadia 2024', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Unit ID: #TRK-8821-B', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ROLE', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                    SizedBox(height: 2),
                    Text('Regional OTR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _confirmed,
          onChanged: (v) => setState(() => _confirmed = v ?? false),
          activeColor: _primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'I hereby confirm that all the information provided above is accurate and complete to the best of my knowledge.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        border: const Border(top: BorderSide(color: Color(0xFFE2E2E2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: const BorderSide(color: _primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _confirmed ? () => Navigator.of(context).pop() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primary.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  final bool active;
  final bool wide;

  const _ProgressDot({required this.active, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: wide ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEC5B13) : const Color(0xFFEC5B13).withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEC5B13).withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFFEC5B13), size: 20),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(color: Color(0xFFEC5B13), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
                  child: const Text('Edit', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertRow extends StatelessWidget {
  final String name;
  final String date;

  const _CertRow({required this.name, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEC5B13).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEC5B13).withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 22),
        ],
      ),
    );
  }
}
