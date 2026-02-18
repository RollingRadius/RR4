import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/data/models/company_model.dart';
import 'package:fleet_management/providers/company_provider.dart';
import 'package:fleet_management/providers/auth_provider.dart';
import 'package:fleet_management/core/constants/app_constants.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

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

  Future<void> _handleSearch(String query) async {
    if (query.length < 3) {
      ref.read(companyProvider.notifier).clearSearchResults();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    await ref.read(companyProvider.notifier).searchCompanies(query);

    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _handleCompanySelection(CompanyModel company) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Company'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You want to join:',
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
                      'You will be added as a Pending User. The company owner must approve your request.',
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Join'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _completeSignupWithCompany(company);
    }
  }

  Future<void> _completeSignupWithCompany(CompanyModel company) async {
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
          const SnackBar(
            content: Text(
                'Registration successful! You are now a Pending User. Please wait for approval.'),
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
            content: Text(error ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyState = ref.watch(companyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Company'),
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
                  hintText: 'Search by company name (min 3 characters)',
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
              child: _buildSearchResults(companyState),
            ),
          ],
        ),
      ),  // closes SafeArea
      ),  // closes PageEntrance
    );
  }

  Widget _buildSearchResults(CompanyState companyState) {
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
              'Search for a company',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter at least 3 characters to search',
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
              'Keep typing...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Minimum 3 characters required',
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
              'Error searching companies',
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
              child: const Text('Retry'),
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
              'No companies found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
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
