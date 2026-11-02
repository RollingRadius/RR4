import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:fleet_management/l10n/app_localizations.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: FadeSlide(delay: 0, child: _buildSearchSection())),
          SliverToBoxAdapter(child: FadeSlide(delay: 100, child: _buildQuickActions())),
          SliverToBoxAdapter(child: FadeSlide(delay: 200, child: _buildPopularArticles())),
          SliverToBoxAdapter(child: FadeSlide(delay: 300, child: _buildCategories())),
          SliverToBoxAdapter(child: FadeSlide(delay: 400, child: _buildContactSupport())),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context);
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(l10n.helpCenterTitle),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.help_center,
              size: 80,
              color: Colors.white54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: l10n.helpCenterSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSearchResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final l10n = AppLocalizations.of(context);
    final results = _getSearchResults(_searchQuery);

    if (results.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.helpCenterNoResults(_searchQuery),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.helpCenterNoResultsHint,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.helpCenterResultsFound(results.length),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...results.map((result) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: result['color'],
                  child: Icon(result['icon'], color: Colors.white, size: 20),
                ),
                title: Text(result['title']),
                subtitle: Text(result['description'], maxLines: 2),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openArticle(result),
              )),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.helpCenterQuickActions,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  l10n.helpCenterGettingStarted,
                  Icons.rocket_launch,
                  Colors.blue,
                  () => _showGettingStarted(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  l10n.helpCenterVideoTutorials,
                  Icons.play_circle_outline,
                  Colors.red,
                  () => _showVideoTutorials(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  l10n.helpCenterContactSupport,
                  Icons.support_agent,
                  Colors.green,
                  () => _showContactSupport(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  l10n.helpCenterReportIssue,
                  Icons.bug_report,
                  Colors.orange,
                  () => _showReportIssue(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularArticles() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.helpCenterPopularArticles,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showAllArticles(),
                child: Text(l10n.helpCenterViewAll),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildArticleCard(
            l10n.helpCenterArticleAddVehicle,
            l10n.helpCenterArticleAddVehicleDesc,
            Icons.directions_car,
            Colors.blue,
            l10n.helpCenterReadMinutes(5),
            4.8,
          ),
          _buildArticleCard(
            l10n.helpCenterArticleDriverPerms,
            l10n.helpCenterArticleDriverPermsDesc,
            Icons.badge,
            Colors.purple,
            l10n.helpCenterReadMinutes(7),
            4.9,
          ),
          _buildArticleCard(
            l10n.helpCenterArticleRealtimeTracking,
            l10n.helpCenterArticleRealtimeTrackingDesc,
            Icons.location_on,
            Colors.red,
            l10n.helpCenterReadMinutes(4),
            4.7,
          ),
          _buildArticleCard(
            l10n.helpCenterArticleMaintenance,
            l10n.helpCenterArticleMaintenanceDesc,
            Icons.build_circle,
            Colors.orange,
            l10n.helpCenterReadMinutes(6),
            4.6,
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String readTime,
    double rating,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openArticle({'title': title}),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          readTime,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.star, size: 14, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final l10n = AppLocalizations.of(context);
    final categories = [
      {
        'title': l10n.helpCenterCatVehicle,
        'icon': Icons.directions_car,
        'color': Colors.blue,
        'articles': 24,
        'description': l10n.helpCenterCatVehicleDesc
      },
      {
        'title': l10n.helpCenterCatDriver,
        'icon': Icons.badge,
        'color': Colors.teal,
        'articles': 18,
        'description': l10n.helpCenterCatDriverDesc
      },
      {
        'title': l10n.helpCenterCatTrip,
        'icon': Icons.route,
        'color': Colors.purple,
        'articles': 15,
        'description': l10n.helpCenterCatTripDesc
      },
      {
        'title': l10n.helpCenterCatTracking,
        'icon': Icons.location_on,
        'color': Colors.red,
        'articles': 12,
        'description': l10n.helpCenterCatTrackingDesc
      },
      {
        'title': l10n.helpCenterCatFinancial,
        'icon': Icons.account_balance,
        'color': Colors.amber,
        'articles': 20,
        'description': l10n.helpCenterCatFinancialDesc
      },
      {
        'title': l10n.helpCenterCatMaintenance,
        'icon': Icons.build_circle,
        'color': Colors.orange,
        'articles': 16,
        'description': l10n.helpCenterCatMaintenanceDesc
      },
      {
        'title': l10n.helpCenterCatRoles,
        'icon': Icons.security,
        'color': Colors.indigo,
        'articles': 22,
        'description': l10n.helpCenterCatRolesDesc
      },
      {
        'title': l10n.helpCenterCatReports,
        'icon': Icons.analytics,
        'color': Colors.deepPurple,
        'articles': 14,
        'description': l10n.helpCenterCatReportsDesc
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.helpCenterBrowseByCategory,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(
                category['title'] as String,
                category['icon'] as IconData,
                category['color'] as Color,
                category['articles'] as int,
                category['description'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    IconData icon,
    Color color,
    int articleCount,
    String description,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _openCategory(title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$articleCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSupport() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            l10n.helpCenterNeedMoreHelp,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.helpCenterSupport247,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showContactOptions(),
                  icon: const Icon(Icons.email, color: Colors.white),
                  label: Text(l10n.helpCenterEmailUs, style: const TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showLiveChat(),
                  icon: const Icon(Icons.chat_bubble),
                  label: Text(l10n.helpCenterLiveChat),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.helpCenterAvgResponse,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getSearchResults(String query) {
    final l10n = AppLocalizations.of(context);
    final allArticles = [
      {
        'title': l10n.helpCenterArticleAddVehicle,
        'description': l10n.helpCenterArticleAddVehicleDesc,
        'icon': Icons.directions_car,
        'color': Colors.blue,
      },
      {
        'title': l10n.helpCenterArticleDriverPerms,
        'description': l10n.helpCenterSearchDriverPermsDesc,
        'icon': Icons.badge,
        'color': Colors.purple,
      },
      {
        'title': l10n.helpCenterSearchGpsTitle,
        'description': l10n.helpCenterSearchGpsDesc,
        'icon': Icons.location_on,
        'color': Colors.red,
      },
      {
        'title': l10n.helpCenterArticleMaintenance,
        'description': l10n.helpCenterSearchMaintenanceDesc,
        'icon': Icons.build_circle,
        'color': Colors.orange,
      },
      {
        'title': l10n.helpCenterSearchReportsTitle,
        'description': l10n.helpCenterSearchReportsDesc,
        'icon': Icons.analytics,
        'color': Colors.deepPurple,
      },
    ];

    return allArticles
        .where((article) =>
            article['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
            article['description'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _openArticle(Map<String, dynamic> article) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(article['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.helpCenterArticleDetailIntro(article['title']),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.helpCenterArticlePlaceholder,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.helpCenterMarkedHelpful)),
              );
            },
            child: Text(l10n.helpCenterWasHelpful),
          ),
        ],
      ),
    );
  }

  void _openCategory(String category) {
    final l10n = AppLocalizations.of(context);
    context.go('/help');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.helpCenterOpeningCategory(category))),
    );
  }

  void _showGettingStarted() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                l10n.helpCenterGuideTitle,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildStepCard(1, l10n.helpCenterStep1Title, l10n.helpCenterStep1Desc),
              _buildStepCard(2, l10n.helpCenterStep2Title, l10n.helpCenterStep2Desc),
              _buildStepCard(3, l10n.helpCenterStep3Title, l10n.helpCenterStep3Desc),
              _buildStepCard(4, l10n.helpCenterStep4Title, l10n.helpCenterStep4Desc),
              _buildStepCard(5, l10n.helpCenterStep5Title, l10n.helpCenterStep5Desc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(int step, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text('$step', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  void _showVideoTutorials() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.helpCenterVideoComingSoon)),
    );
  }

  void _showContactSupport() {
    _showContactOptions();
  }

  void _showReportIssue() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.helpCenterReportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: l10n.helpCenterIssueTitle,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.helpCenterIssueDescription,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.helpCenterIssueReported)),
              );
            },
            child: Text(l10n.commonSubmit),
          ),
        ],
      ),
    );
  }

  void _showAllArticles() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.helpCenterShowingAll)),
    );
  }

  void _showContactOptions() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.helpCenterContactSupport,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.email, color: Colors.white),
              ),
              title: Text(l10n.helpCenterEmailSupport),
              subtitle: const Text('support@fleetmanagement.com'),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.phone, color: Colors.white),
              ),
              title: Text(l10n.helpCenterPhoneSupport),
              subtitle: const Text('+1 (555) 123-4567'),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.chat, color: Colors.white),
              ),
              title: Text(l10n.helpCenterLiveChat),
              subtitle: Text(l10n.helpCenterChatWithTeam),
              onTap: () => _showLiveChat(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveChat() {
    final l10n = AppLocalizations.of(context);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.helpCenterOpeningChat)),
    );
  }
}
