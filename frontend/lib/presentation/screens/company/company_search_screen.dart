import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/data/models/company_model.dart';
import 'package:fleet_management/providers/company_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:fleet_management/l10n/app_localizations.dart';

class CompanySearchScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? signupData;

  const CompanySearchScreen({super.key, this.signupData});

  @override
  ConsumerState<CompanySearchScreen> createState() =>
      _CompanySearchScreenState();
}

class _CompanySearchScreenState extends ConsumerState<CompanySearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Maps the selected role in signupData to the company business_type filter.
  /// LP workers should only see logistic_partner companies, LO workers only load_owner.
  String? get _businessTypeFilter {
    final role = widget.signupData?['role'] as String?
        ?? widget.signupData?['business_type'] as String?;
    switch (role) {
      case 'logistic_partner_worker': return 'logistic_partner';
      case 'lp_rr_operations':        return 'logistic_partner';
      case 'load_owner_worker':       return 'load_owner';
      default:                        return null; // no filter — show all
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.length < 3) {
      ref.read(companyProvider.notifier).clearSearchResults();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    await ref.read(companyProvider.notifier).searchCompanies(
      query,
      businessType: _businessTypeFilter,
    );

    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _handleCompanySelection(CompanyModel company) async {
    final l10n = AppLocalizations.of(context);
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companySearchJoinTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.companySearchJoinPrompt,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              company.companyName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (company.city != null) ...[
              const SizedBox(height: 4),
              Text('${company.city}, ${company.state ?? ''}'),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.companySearchJoinNotice,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.companySearchJoinButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _completeSignupWithCompany(company);
    }
  }

  Future<void> _completeSignupWithCompany(CompanyModel company) async {
    final l10n = AppLocalizations.of(context);
    // Add company to signup data
    final updatedSignupData = {
      ...?widget.signupData,
      'company_type': 'existing',
      'company_id': company.id,
    };

    // Complete signup
    final response =
        await ref.read(authProvider.notifier).signup(updatedSignupData);

    if (mounted) {
      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.companySearchRegisterSuccess),
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
            content: Text(error ?? l10n.companySearchRegisterFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final companyState = ref.watch(companyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.companySearchTitle),
      ),
      body: PageEntrance(
        child: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _businessTypeFilter == 'logistic_partner'
                      ? l10n.companySearchHintLp
                      : _businessTypeFilter == 'load_owner'
                          ? l10n.companySearchHintLo
                          : l10n.companySearchHintDefault,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(companyProvider.notifier).clearSearchResults();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                  _handleSearch(value);
                },
              ),
            ),

            // Search results
            Expanded(
              child: _buildSearchResults(companyState, l10n),
            ),
          ],
        ),
      ),  // closes SafeArea
      ),  // closes PageEntrance
    );
  }

  Widget _buildSearchResults(CompanyState companyState, AppLocalizations l10n) {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.companySearchEmptyTitle,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.companySearchEmptyHint,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.length < 3) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.keyboard,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.companySearchKeepTyping,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.companySearchMinChars,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (_isSearching || companyState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (companyState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.companySearchError,
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              companyState.error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _handleSearch(_searchController.text),
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }

    if (companyState.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.companySearchNoResults,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.companySearchTryOther,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: companyState.searchResults.length,
      itemBuilder: (context, index) {
        final company = companyState.searchResults[index];
        return _CompanyCard(
          company: company,
          onTap: () => _handleCompanySelection(company),
        );
      },
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final CompanyModel company;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.company,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Company icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.business,
                  color: Colors.blue.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),

              // Company details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (company.city != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${company.city}, ${company.state ?? ''}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
