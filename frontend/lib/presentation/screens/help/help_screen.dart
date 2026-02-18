import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
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
      appBar: AppBar(
        title: const Text('Help & Support'),
        centerTitle: true,
      ),
      body: PageEntrance(
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How can we help you?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find answers to your questions',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search for help...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.all(24.0),
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
                          context,
                          icon: Icons.email_outlined,
                          title: 'Contact Us',
                          subtitle: 'Get in touch',
                          color: Colors.blue,
                          onTap: () => _showContactDialog(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.bug_report_outlined,
                          title: 'Report Bug',
                          subtitle: 'Help us improve',
                          color: Colors.orange,
                          onTap: () => _showReportBugDialog(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.star_outline,
                          title: 'Feature Request',
                          subtitle: 'Suggest ideas',
                          color: Colors.purple,
                          onTap: () => _showFeatureRequestDialog(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.video_library_outlined,
                          title: 'Video Tutorials',
                          subtitle: 'Watch & learn',
                          color: Colors.green,
                          onTap: () => _showComingSoon('Video Tutorials'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Getting Started Section
            _buildSection(
              context,
              title: 'Getting Started',
              icon: Icons.rocket_launch,
              children: [
                _buildHelpItem(
                  context,
                  title: 'Creating Your Account',
                  description: 'Learn how to sign up and set up your profile',
                  icon: Icons.person_add,
                  onTap: () => _showHelpArticle(
                    'Creating Your Account',
                    _getAccountCreationContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'Understanding Roles',
                  description: 'Learn about user roles and permissions',
                  icon: Icons.people_outline,
                  onTap: () => _showHelpArticle(
                    'Understanding Roles',
                    _getRolesContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'Dashboard Overview',
                  description: 'Navigate the main dashboard and features',
                  icon: Icons.dashboard_outlined,
                  onTap: () => _showHelpArticle(
                    'Dashboard Overview',
                    _getDashboardContent(),
                  ),
                ),
              ],
            ),

            // Features Section
            _buildSection(
              context,
              title: 'Features Guide',
              icon: Icons.star,
              children: [
                _buildHelpItem(
                  context,
                  title: 'Managing Vehicles',
                  description: 'Add, edit, and track your fleet vehicles',
                  icon: Icons.directions_car,
                  onTap: () => _showHelpArticle(
                    'Managing Vehicles',
                    _getVehiclesContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'Managing Drivers',
                  description: 'Add drivers and assign them to vehicles',
                  icon: Icons.badge,
                  onTap: () => _showHelpArticle(
                    'Managing Drivers',
                    _getDriversContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'Organizations',
                  description: 'Create and manage your organization',
                  icon: Icons.business,
                  onTap: () => _showHelpArticle(
                    'Organizations',
                    _getOrganizationsContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'Reports & Analytics',
                  description: 'Generate reports and view insights',
                  icon: Icons.analytics,
                  onTap: () => _showHelpArticle(
                    'Reports & Analytics',
                    _getReportsContent(),
                  ),
                ),
              ],
            ),

            // Account & Settings Section
            _buildSection(
              context,
              title: 'Account & Settings',
              icon: Icons.settings,
              children: [
                _buildHelpItem(
                  context,
                  title: 'Profile Settings',
                  description: 'Update your profile information',
                  icon: Icons.person,
                  onTap: () => _showHelpArticle(
                    'Profile Settings',
                    _getProfileContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'Changing Your Role',
                  description: 'Learn how to switch between roles',
                  icon: Icons.swap_horiz,
                  onTap: () => _showHelpArticle(
                    'Changing Your Role',
                    _getRoleChangeContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'App Settings',
                  description: 'Customize notifications, GPS, and more',
                  icon: Icons.tune,
                  onTap: () => _showHelpArticle(
                    'App Settings',
                    _getSettingsContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'Privacy & Security',
                  description: 'Manage your privacy and security settings',
                  icon: Icons.security,
                  onTap: () => _showHelpArticle(
                    'Privacy & Security',
                    _getSecurityContent(),
                  ),
                ),
              ],
            ),

            // FAQs Section
            _buildSection(
              context,
              title: 'Frequently Asked Questions',
              icon: Icons.quiz,
              children: [
                _buildFAQItem(
                  context,
                  question: 'How do I reset my password?',
                  answer:
                      'You can reset your password from the login screen by clicking "Forgot Password". Follow the instructions sent to your email or answer your security questions to reset your password.',
                ),
                _buildFAQItem(
                  context,
                  question: 'Can I change my username?',
                  answer:
                      'No, usernames are permanent and cannot be changed. This ensures consistency across the system. However, you can update your full name and other profile information from the Profile Settings page.',
                ),
                _buildFAQItem(
                  context,
                  question: 'How do I add a vehicle?',
                  answer:
                      'Navigate to the Vehicles tab from the bottom navigation bar. Click the "+" button to add a new vehicle. Fill in the required details like registration number, model, and capacity.',
                ),
                _buildFAQItem(
                  context,
                  question: 'What is an Independent User?',
                  answer:
                      'An Independent User is someone who uses the app without being part of an organization. You can later join an organization, create your own, or become a driver.',
                ),
                _buildFAQItem(
                  context,
                  question: 'How do I join an organization?',
                  answer:
                      'Go to your Profile page and click "Join Organization" in the role change section. Search for the organization you want to join and send a request. The organization admin will review and approve your request.',
                ),
                _buildFAQItem(
                  context,
                  question: 'What happens when I enable GPS tracking?',
                  answer:
                      'When GPS tracking is enabled, the app will track your location in real-time. This helps with route optimization and vehicle tracking. You can control tracking frequency and background tracking from Settings.',
                ),
              ],
            ),

            // Troubleshooting Section
            _buildSection(
              context,
              title: 'Troubleshooting',
              icon: Icons.build,
              children: [
                _buildHelpItem(
                  context,
                  title: 'Login Issues',
                  description: 'Cannot log in or forgot credentials',
                  icon: Icons.lock_open,
                  onTap: () => _showHelpArticle(
                    'Login Issues',
                    _getLoginIssuesContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'App Not Loading',
                  description: 'App crashes or does not load properly',
                  icon: Icons.error_outline,
                  onTap: () => _showHelpArticle(
                    'App Not Loading',
                    _getAppIssuesContent(),
                  ),
                ),
                _buildHelpItem(
                  context,
                  title: 'GPS Not Working',
                  description: 'Location tracking issues',
                  icon: Icons.location_off,
                  onTap: () => _showHelpArticle(
                    'GPS Not Working',
                    _getGPSIssuesContent(),
                  ),
                ),
              ],
            ),

            // Contact Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.support_agent,
                        size: 60,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Still need help?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Our support team is here to help you',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showContactDialog(),
                          icon: const Icon(Icons.email),
                          label: const Text('Contact Support'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'support@fleetmanagement.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),  // closes SingleChildScrollView
      ),  // closes PageEntrance
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      leading: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showHelpArticle(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Message sent! We\'ll get back to you soon.'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Bug Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bug_report),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What happened? Steps to reproduce...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Bug report submitted. Thank you!'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Feature Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lightbulb),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the feature you\'d like...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Feature request submitted. Thank you!'),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Content for help articles
  String _getAccountCreationContent() {
    return '''
Creating Your Account

Welcome to Fleet Management System! Here's how to get started:

1. Sign Up
   - Open the app and tap "Sign Up"
   - Enter your username, email, full name, and phone number
   - Create a strong password (min 8 characters with uppercase, lowercase, and digits)

2. Choose Authentication Method
   - Email Verification: We'll send a verification link to your email
   - Security Questions: Answer 3 security questions for account recovery

3. Complete Your Profile
   - Select your role:
     • Independent User: Use basic features without an organization
     • Driver: Register as a driver with license information
     • Join Company: Request to join an existing organization
     • Create Company: Start your own organization

4. Start Using the App
   - Once verified, log in with your credentials
   - Explore the dashboard and features

Tips:
• Keep your credentials secure
• Use a valid email address for important notifications
• Remember your security questions answers (if chosen)
''';
  }

  String _getRolesContent() {
    return '''
Understanding Roles

Fleet Management System has different user roles with specific permissions:

1. Independent User
   - Use basic features without organization affiliation
   - Can later join/create organizations or become a driver
   - Limited access to organization features

2. Driver
   - Registered with driver license information
   - Can be hired by organizations
   - Track assigned vehicles and trips

3. Owner
   - Full control of the organization
   - Can manage members, vehicles, and settings
   - Assign roles to other users

4. Admin
   - Manage organization members and settings
   - Approve/reject join requests
   - Generate reports

5. Dispatcher
   - Manage trips and assignments
   - Track vehicles and drivers
   - View real-time locations

6. User
   - Standard access to organization features
   - View vehicles, drivers, and trips
   - Limited management capabilities

7. Viewer
   - Read-only access
   - Can view information but cannot make changes
   - Good for stakeholders and auditors

8. Pending User
   - Temporary status when requesting to join organization
   - Awaiting approval from organization admin
   - Limited access until approved
''';
  }

  String _getDashboardContent() {
    return '''
Dashboard Overview

The dashboard is your central hub for managing your fleet:

Main Components:

1. Header
   - Welcome message with your name
   - Role badge showing your current role
   - Organization name (if applicable)

2. Statistics Cards
   - Total Vehicles: Number of vehicles in your fleet
   - Active Drivers: Currently active drivers
   - Today's Trips: Trips scheduled for today
   - Pending Tasks: Items requiring attention

3. Quick Actions
   - Add Vehicle: Register a new vehicle
   - Add Driver: Onboard a new driver
   - Schedule Trip: Create a new trip
   - View Reports: Access analytics

4. Recent Activity
   - Latest vehicle updates
   - New driver assignments
   - Recent trip completions

5. Bottom Navigation
   - Dashboard: Main overview
   - Vehicles: Manage your fleet
   - Drivers: Manage drivers
   - Trips: View and schedule trips
   - Reports: Analytics and insights

Top App Bar:
   - Notifications: Important alerts
   - Profile Menu: Access settings and account options
''';
  }

  String _getVehiclesContent() {
    return '''
Managing Vehicles

Add, edit, and track your fleet vehicles:

Adding a Vehicle:
1. Tap the Vehicles tab
2. Click the "+" button
3. Fill in vehicle details:
   - Registration Number (required)
   - Model and Make
   - Year of Manufacture
   - Vehicle Type (Truck, Van, Car, etc.)
   - Capacity (passengers/cargo)
   - Fuel Type
   - Current Status

4. Tap "Save" to add the vehicle

Editing a Vehicle:
1. Find the vehicle in the list
2. Tap on the vehicle card
3. Click the edit icon
4. Update information
5. Save changes

Vehicle Status:
- Available: Ready for assignment
- In Use: Currently on a trip
- Maintenance: Under repair
- Inactive: Not in service

Tracking:
- View real-time location (if GPS enabled)
- See maintenance history
- Track fuel consumption
- View trip history
''';
  }

  String _getDriversContent() {
    return '''
Managing Drivers

Add and manage drivers in your organization:

Adding a Driver:
1. Navigate to Drivers tab
2. Click the "+" button
3. Enter driver details:
   - Full Name
   - Phone Number
   - Email Address
   - License Number (required)
   - License Expiry Date
   - Employment Type
   - Emergency Contact

4. Save to add driver

Driver Status:
- Available: Ready for assignments
- On Trip: Currently driving
- Off Duty: Not available
- On Leave: Scheduled time off

Assigning Drivers:
1. Go to Trips section
2. Create or edit a trip
3. Select driver from available list
4. Assign vehicle
5. Confirm assignment

Monitoring:
- Track driver location (if enabled)
- View trip history
- Monitor performance metrics
- Check license expiry dates
''';
  }

  String _getOrganizationsContent() {
    return '''
Organizations

Create and manage your organization:

Creating an Organization:
1. Go to Profile page
2. Click "Create Organization"
3. Fill in company details:
   - Company Name
   - Business Type
   - Contact Information
   - Address
4. Submit to create

You'll become the Owner with full control.

Managing Members:
1. Access Organization Management
2. View all members
3. Approve/reject join requests
4. Assign roles to members
5. Remove members if needed

Member Roles:
- Owner: Full control
- Admin: Management capabilities
- Dispatcher: Trip management
- User: Standard access
- Viewer: Read-only

Joining an Organization:
1. Profile → Join Organization
2. Search for company name
3. Send join request
4. Wait for admin approval
5. Once approved, access features

Organization Settings:
- Update company information
- Configure preferences
- Manage custom roles
- View organization reports
''';
  }

  String _getReportsContent() {
    return '''
Reports & Analytics

Generate insightful reports:

Available Reports:

1. Organization Summary
   - Overview of all metrics
   - Vehicle utilization
   - Driver performance
   - Trip statistics

2. Driver List Report
   - All drivers with details
   - License information
   - Contact details
   - Export to PDF/Excel

3. License Expiry Report
   - Upcoming license expirations
   - Filter by date range
   - Send renewal reminders

4. Vehicle Report
   - Fleet overview
   - Maintenance schedules
   - Fuel consumption

5. Trip Report
   - Completed trips
   - Revenue analysis
   - Route efficiency

Generating Reports:
1. Navigate to Reports tab
2. Select report type
3. Choose date range (if applicable)
4. Apply filters
5. Click "Generate Report"
6. View or export

Export Options:
- PDF: Printable format
- Excel: Editable spreadsheet
- CSV: Data import/export

Scheduling:
- Set up automatic reports
- Receive via email
- Daily, weekly, or monthly frequency
''';
  }

  String _getProfileContent() {
    return '''
Profile Settings

Manage your personal information:

Viewing Your Profile:
1. Click profile icon in app bar
2. Select "My Profile"
3. View your information

Editing Profile:
1. Click the edit icon (pencil)
2. Edit mode activates
3. Update your information:
   - Full Name
   - Email Address
   - Phone Number
4. Click the check icon to save
5. Click X to cancel without saving

Note: Username cannot be changed after creation.

Profile Photo:
1. Enter edit mode
2. Click camera icon on profile picture
3. Select photo from gallery
4. Crop if needed
5. Save changes

Profile Information Displayed:
- Personal Information
  • Full Name
  • Username
  • Email
  • Phone

- Role & Organization
  • Current Role
  • Company Name
  • Profile Status

- Account Status
  • Authentication Method
  • Account Status

Security:
- All changes are logged
- Email changes may require verification
- Keep your contact information up to date
''';
  }

  String _getRoleChangeContent() {
    return '''
Changing Your Role

Independent Users can change their role:

Who Can Change Roles?
- Only Independent Users
- Users not affiliated with organizations
- After profile completion

Available Options:

1. Become a Driver
   - Provide driver license number
   - Enter license expiry date
   - Submit for approval
   - Remain independent but registered as driver

2. Join Organization
   - Browse available organizations
   - Send join request
   - Wait for admin approval
   - Become Pending User until approved

3. Create Organization
   - Fill in company details
   - Submit to create
   - Become Owner immediately
   - Full organization control

How to Change Role:
1. Go to Profile page
2. Find "Role & Organization" section
3. Click "Change Role" button
4. Select your desired option
5. Complete required information
6. Submit and wait for processing

Important Notes:
- Organization members cannot self-change roles
- Role changes are logged for security
- Some changes require approval
- Original role information is preserved
''';
  }

  String _getSettingsContent() {
    return '''
App Settings

Customize your experience:

Notifications:
- Enable/disable push notifications
- Trip updates
- Driver updates
- Vehicle alerts

Location & Tracking:
- Enable GPS tracking
- Background tracking
- Update frequency:
  • 5 seconds (high accuracy)
  • 15 seconds (balanced)
  • 30 seconds (battery saver)
  • 60 seconds (low frequency)

Display:
- Theme: Light, Dark, or System
- Compact view for more items

Data & Storage:
- Auto-sync data
- Offline mode
- Clear cache

Privacy & Security:
- Biometric lock (fingerprint/face)
- Share anonymous analytics

Accessing Settings:
1. Click profile icon
2. Select "Settings"
3. Choose category
4. Toggle settings
5. Changes save automatically

Recommended Settings:
- Enable notifications for important updates
- GPS tracking for real-time location
- Auto-sync for latest data
- Biometric lock for security
''';
  }

  String _getSecurityContent() {
    return '''
Privacy & Security

Keep your account secure:

Password Security:
- Use strong, unique passwords
- Minimum 8 characters
- Include uppercase, lowercase, and digits
- Avoid common words

Changing Password:
1. Go to Settings → Security
2. Select "Change Password"
3. Enter current password
4. Enter new password
5. Confirm new password
6. Save changes

Two-Factor Authentication:
- Enable biometric lock
- Use fingerprint or face recognition
- Adds extra layer of security

Account Recovery:
If using Security Questions:
1. Go to login screen
2. Click "Forgot Password"
3. Answer security questions
4. Reset password

If using Email:
1. Click "Forgot Password"
2. Check your email
3. Click reset link
4. Create new password

Privacy Settings:
- Control who sees your information
- Manage data sharing
- Review permissions

Best Practices:
- Never share your password
- Log out on shared devices
- Keep email updated
- Review account activity regularly
- Enable all security features
''';
  }

  String _getLoginIssuesContent() {
    return '''
Login Issues

Troubleshooting login problems:

Common Issues:

1. Forgot Password
   Solution:
   - Click "Forgot Password" on login screen
   - Follow email instructions or answer security questions
   - Create new password

2. Forgot Username
   Solution:
   - Click "Forgot Username"
   - Enter your email or phone
   - We'll send your username

3. Account Locked
   Reason: Too many failed attempts
   Solution:
   - Wait 30 minutes
   - Try again
   - Contact support if persists

4. Invalid Credentials
   - Double-check username and password
   - Ensure caps lock is off
   - Try password reset

5. Email Not Verified
   - Check your email inbox (and spam)
   - Click verification link
   - Request new verification email if needed

Still Can't Login?
- Clear app cache
- Update to latest version
- Check internet connection
- Contact support with your username (not password)
''';
  }

  String _getAppIssuesContent() {
    return '''
App Not Loading

Troubleshooting app issues:

Quick Fixes:

1. Force Close and Restart
   - Close the app completely
   - Wait 10 seconds
   - Open the app again

2. Clear Cache
   - Go to Settings → Data & Storage
   - Click "Clear Cache"
   - Restart the app

3. Check Internet Connection
   - Ensure you have stable internet
   - Try switching between WiFi and mobile data
   - Test other apps

4. Update the App
   - Check app store for updates
   - Install latest version
   - New versions fix known issues

5. Restart Device
   - Power off your device
   - Wait 30 seconds
   - Power on and try again

6. Reinstall App
   - Uninstall the app
   - Restart device
   - Reinstall from app store
   - Log in again

Persistent Issues?
- Check storage space (need 100MB+)
- Ensure OS is up to date
- Disable VPN temporarily
- Contact support with error details
''';
  }

  String _getGPSIssuesContent() {
    return '''
GPS Not Working

Fix location tracking issues:

Enable Location Permissions:

Android:
1. Go to Settings
2. Apps → Fleet Management
3. Permissions → Location
4. Select "Allow all the time" or "While using app"

iOS:
1. Go to Settings
2. Privacy → Location Services
3. Find Fleet Management
4. Select "Always" or "While Using"

In-App Settings:
1. Open Fleet Management
2. Profile → Settings
3. Location & Tracking
4. Enable GPS Tracking
5. Enable Background Tracking (if needed)

Troubleshooting:

1. GPS Not Accurate
   - Go outside for better signal
   - Wait a few minutes for GPS lock
   - Increase update frequency in settings

2. Background Tracking Not Working
   - Enable "Allow all the time" permission
   - Disable battery optimization for this app
   - Keep app running in background

3. Draining Battery
   - Reduce update frequency
   - Disable background tracking when not needed
   - Use "While using app" permission

4. No Location Data
   - Check device GPS is on
   - Restart the app
   - Toggle GPS off and on
   - Check for app updates

Still Not Working?
- Restart your device
- Check with other GPS apps
- Contact support if issue persists
''';
  }
}
