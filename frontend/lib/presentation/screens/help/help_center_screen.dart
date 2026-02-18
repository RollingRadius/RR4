import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

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
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Help Center'),
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search for help articles, guides, FAQs...',
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
                'No results found for "$_searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or browse categories below',
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
              '${results.length} results found',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
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
                  'Getting Started',
                  Icons.rocket_launch,
                  Colors.blue,
                  () => _showGettingStarted(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Video Tutorials',
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
                  'Contact Support',
                  Icons.support_agent,
                  Colors.green,
                  () => _showContactSupport(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  'Report Issue',
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Articles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showAllArticles(),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildArticleCard(
            'How to add a new vehicle',
            'Step-by-step guide to adding vehicles to your fleet',
            Icons.directions_car,
            Colors.blue,
            '5 min read',
            4.8,
          ),
          _buildArticleCard(
            'Managing driver permissions',
            'Learn how to assign and manage driver roles and permissions',
            Icons.badge,
            Colors.purple,
            '7 min read',
            4.9,
          ),
          _buildArticleCard(
            'Setting up real-time tracking',
            'Configure GPS tracking for your fleet vehicles',
            Icons.location_on,
            Colors.red,
            '4 min read',
            4.7,
          ),
          _buildArticleCard(
            'Creating maintenance schedules',
            'Keep your fleet running smoothly with scheduled maintenance',
            Icons.build_circle,
            Colors.orange,
            '6 min read',
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
    final categories = [
      {
        'title': 'Vehicle Management',
        'icon': Icons.directions_car,
        'color': Colors.blue,
        'articles': 24,
        'description': 'Adding, editing, and managing vehicles'
      },
      {
        'title': 'Driver Management',
        'icon': Icons.badge,
        'color': Colors.teal,
        'articles': 18,
        'description': 'Driver profiles, licenses, and assignments'
      },
      {
        'title': 'Trip Management',
        'icon': Icons.route,
        'color': Colors.purple,
        'articles': 15,
        'description': 'Creating and monitoring trips'
      },
      {
        'title': 'Real-time Tracking',
        'icon': Icons.location_on,
        'color': Colors.red,
        'articles': 12,
        'description': 'GPS tracking and location services'
      },
      {
        'title': 'Financial Management',
        'icon': Icons.account_balance,
        'color': Colors.amber,
        'articles': 20,
        'description': 'Expenses, invoices, and payments'
      },
      {
        'title': 'Maintenance',
        'icon': Icons.build_circle,
        'color': Colors.orange,
        'articles': 16,
        'description': 'Schedules, repairs, and inspections'
      },
      {
        'title': 'Roles & Permissions',
        'icon': Icons.security,
        'color': Colors.indigo,
        'articles': 22,
        'description': 'User roles and access control'
      },
      {
        'title': 'Reports & Analytics',
        'icon': Icons.analytics,
        'color': Colors.deepPurple,
        'articles': 14,
        'description': 'Generating and exporting reports'
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Category',
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
          const Text(
            'Need More Help?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our support team is available 24/7 to assist you',
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
                  label: const Text('Email Us', style: TextStyle(color: Colors.white)),
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
                  label: const Text('Live Chat'),
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
          const Text(
            'Average response time: 2 minutes',
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
    final allArticles = [
      {
        'title': 'How to add a new vehicle',
        'description': 'Step-by-step guide to adding vehicles to your fleet',
        'icon': Icons.directions_car,
        'color': Colors.blue,
      },
      {
        'title': 'Managing driver permissions',
        'description': 'Learn how to assign and manage driver roles',
        'icon': Icons.badge,
        'color': Colors.purple,
      },
      {
        'title': 'Setting up GPS tracking',
        'description': 'Configure real-time vehicle tracking',
        'icon': Icons.location_on,
        'color': Colors.red,
      },
      {
        'title': 'Creating maintenance schedules',
        'description': 'Schedule regular vehicle maintenance',
        'icon': Icons.build_circle,
        'color': Colors.orange,
      },
      {
        'title': 'Generating financial reports',
        'description': 'Create and export financial reports',
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
                'This is a detailed article about: ${article['title']}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Article content would go here with step-by-step instructions, screenshots, and helpful tips.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Article marked as helpful')),
              );
            },
            child: const Text('Was this helpful?'),
          ),
        ],
      ),
    );
  }

  void _openCategory(String category) {
    context.go('/help');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $category articles...')),
    );
  }

  void _showGettingStarted() {
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
              const Text(
                'Getting Started Guide',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildStepCard(1, 'Create Your Account', 'Sign up with your details'),
              _buildStepCard(2, 'Set Up Your Organization', 'Create or join an organization'),
              _buildStepCard(3, 'Add Your Fleet', 'Add vehicles to the system'),
              _buildStepCard(4, 'Invite Team Members', 'Add drivers and staff'),
              _buildStepCard(5, 'Start Managing', 'Begin tracking and managing your fleet'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video tutorials coming soon!')),
    );
  }

  void _showContactSupport() {
    _showContactOptions();
  }

  void _showReportIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Issue Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Issue reported successfully')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showAllArticles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Showing all articles...')),
    );
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Contact Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.email, color: Colors.white),
              ),
              title: const Text('Email Support'),
              subtitle: const Text('support@fleetmanagement.com'),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.phone, color: Colors.white),
              ),
              title: const Text('Phone Support'),
              subtitle: const Text('+1 (555) 123-4567'),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.chat, color: Colors.white),
              ),
              title: const Text('Live Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () => _showLiveChat(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveChat() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening live chat...')),
    );
  }
}
