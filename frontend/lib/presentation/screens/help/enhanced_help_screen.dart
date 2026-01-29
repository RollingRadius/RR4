import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnhancedHelpScreen extends ConsumerStatefulWidget {
  const EnhancedHelpScreen({super.key});

  @override
  ConsumerState<EnhancedHelpScreen> createState() => _EnhancedHelpScreenState();
}

class _EnhancedHelpScreenState extends ConsumerState<EnhancedHelpScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fleet Management - Complete Guide'),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) => setState(() => _selectedTabIndex = index),
            tabs: const [
              Tab(icon: Icon(Icons.home_outlined), text: 'Overview'),
              Tab(icon: Icon(Icons.people_outline), text: 'Roles'),
              Tab(icon: Icon(Icons.star_outline), text: 'Features'),
              Tab(icon: Icon(Icons.grid_on_outlined), text: 'Permissions'),
              Tab(icon: Icon(Icons.help_outline), text: 'FAQ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildRolesTab(),
            _buildFeaturesTab(),
            _buildPermissionsTab(),
            _buildFAQTab(),
          ],
        ),
      ),
    );
  }

  // OVERVIEW TAB
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(
            'Fleet Management System',
            'A comprehensive platform for managing vehicles, drivers, and operations with advanced role-based access control.',
            Icons.local_shipping,
            Colors.blue,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Permission System', Icons.security),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Dual-Layer Permission Architecture',
            '''Our system combines two powerful approaches:

Layer 1: Capability-Based Permissions
• 100+ hardcoded capability identifiers
• Granular control at feature level
• Type-safe and consistent
• Examples: vehicle.create, driver.view.all

Layer 2: Template-Based Roles
• 12 predefined role templates
• Each template = curated capabilities
• Fully customizable by admins
• Mix capabilities from multiple templates
• Create unlimited custom roles''',
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Key Benefits',
            '''• For Administrators: Easy template system without coding
• For Users: Precise access control
• For Developers: Clean, maintainable code
• For Organizations: Maximum flexibility''',
            Colors.orange,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Quick Start', Icons.rocket_launch),
          const SizedBox(height: 12),
          _buildQuickStartSteps(),
        ],
      ),
    );
  }

  Widget _buildQuickStartSteps() {
    return Column(
      children: [
        _buildStepCard(1, 'Create Account', 'Sign up with your details', Icons.person_add),
        _buildStepCard(2, 'Join or Create Organization', 'Join existing or create new', Icons.business),
        _buildStepCard(3, 'Get Your Role', 'Assigned based on your position', Icons.badge),
        _buildStepCard(4, 'Start Managing', 'Access features per your role', Icons.dashboard),
      ],
    );
  }

  Widget _buildStepCard(int step, String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Icon(icon, color: Colors.blue),
      ),
    );
  }

  // ROLES TAB
  Widget _buildRolesTab() {
    final roles = _getAllRoles();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: roles.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildHeaderCard(
              '12 System Roles',
              'Each role has specific capabilities and access levels tailored to different job functions.',
              Icons.people,
              Colors.purple,
            ),
          );
        }
        final role = roles[index - 1];
        return _buildRoleExpansionTile(role);
      },
    );
  }

  Widget _buildRoleExpansionTile(Map<String, dynamic> role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: role['color'],
          child: Icon(role['icon'], color: Colors.white, size: 20),
        ),
        title: Text(
          role['name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(role['description'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Key Abilities:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                ...List<Widget>.from(
                  role['abilities'].map((ability) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ability,
                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAllRoles() {
    return [
      {
        'name': 'Super Admin',
        'description': 'Highest level with complete system control',
        'icon': Icons.admin_panel_settings,
        'color': Colors.red,
        'abilities': [
          'Full user management (create, edit, delete, assign roles)',
          'Complete vehicle management with full CRUD operations',
          'Real-time tracking of all vehicles with historical data',
          'System configuration and database management',
          'Organization management and subscription control',
        ]
      },
      {
        'name': 'Fleet Manager',
        'description': 'Manages day-to-day fleet operations',
        'icon': Icons.directions_car,
        'color': Colors.blue,
        'abilities': [
          'Add and edit vehicles, manage assignments',
          'Driver management and performance tracking',
          'Live tracking of all fleet vehicles',
          'Create and manage trips',
          'Generate fleet performance reports',
        ]
      },
      {
        'name': 'Dispatcher',
        'description': 'Coordinates vehicle assignments and schedules',
        'icon': Icons.location_on,
        'color': Colors.green,
        'abilities': [
          'Create and schedule trips',
          'Assign vehicles and drivers to trips',
          'Monitor real-time trip progress',
          'Send notifications to drivers',
          'View vehicle availability (read-only)',
        ]
      },
      {
        'name': 'Driver',
        'description': 'Operates vehicles and completes assigned trips',
        'icon': Icons.person,
        'color': Colors.teal,
        'abilities': [
          'View assigned trips and details',
          'Update trip status (start, complete)',
          'Share real-time GPS location',
          'Report vehicle issues',
          'View personal trip history',
        ]
      },
      {
        'name': 'Accountant/Finance Manager',
        'description': 'Manages financial aspects of fleet operations',
        'icon': Icons.account_balance,
        'color': Colors.amber,
        'abilities': [
          'Manage all expenses (fuel, maintenance, tolls)',
          'Process invoices and track payments',
          'Set and monitor budgets',
          'Approve/reject expense claims',
          'Generate financial reports',
        ]
      },
      {
        'name': 'Maintenance Manager',
        'description': 'Oversees vehicle maintenance and repairs',
        'icon': Icons.build,
        'color': Colors.orange,
        'abilities': [
          'Create maintenance schedules',
          'Monitor vehicle health and diagnostics',
          'Manage repair orders and track history',
          'Maintain vendor database',
          'Ensure compliance with safety standards',
        ]
      },
      {
        'name': 'Compliance Officer',
        'description': 'Ensures regulatory compliance and documentation',
        'icon': Icons.verified_user,
        'color': Colors.indigo,
        'abilities': [
          'Track driver licenses and expiration dates',
          'Monitor vehicle registration and permits',
          'Manage insurance policies',
          'Ensure regulatory compliance (DOT, HOS)',
          'Generate compliance reports for authorities',
        ]
      },
      {
        'name': 'Operations Manager',
        'description': 'Oversees overall fleet operations and strategy',
        'icon': Icons.insights,
        'color': Colors.purple,
        'abilities': [
          'View comprehensive operational dashboards',
          'Monitor all KPIs and performance metrics',
          'Approve vehicle and driver assignments',
          'Access all fleet data (mostly read-only)',
          'Override assignments in emergencies',
        ]
      },
      {
        'name': 'Maintenance Technician',
        'description': 'Performs vehicle maintenance and repairs',
        'icon': Icons.engineering,
        'color': Colors.brown,
        'abilities': [
          'View assigned maintenance tasks',
          'Update work order status',
          'Conduct vehicle inspections',
          'Log parts used and work performed',
          'Request spare parts from inventory',
        ]
      },
      {
        'name': 'Customer Service Representative',
        'description': 'Handles customer inquiries and support',
        'icon': Icons.support_agent,
        'color': Colors.pink,
        'abilities': [
          'View and update customer information',
          'Track shipment/delivery status',
          'Create and manage support tickets',
          'Send notifications to customers',
          'Generate customer service reports',
        ]
      },
      {
        'name': 'Viewer/Analyst',
        'description': 'Read-only access for monitoring and reporting',
        'icon': Icons.visibility,
        'color': Colors.grey,
        'abilities': [
          'View all vehicles and status (read-only)',
          'Access historical data and reports',
          'Monitor real-time tracking',
          'Generate custom reports',
          'Export data for analysis',
        ]
      },
      {
        'name': 'Custom Role',
        'description': 'Flexible role with customizable permissions',
        'icon': Icons.tune,
        'color': Colors.deepPurple,
        'abilities': [
          'Start with any predefined role template',
          'Mix permissions from multiple templates',
          'Build completely from scratch',
          'Granular control (None/View/Limited/Full)',
          'Save as reusable template',
        ]
      },
    ];
  }

  // FEATURES TAB
  Widget _buildFeaturesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(
          'Feature Categories',
          'Comprehensive features organized by business function.',
          Icons.featured_play_list,
          Colors.green,
        ),
        const SizedBox(height: 16),
        _buildFeatureCategory('Vehicle Management', Icons.directions_car, Colors.blue, [
          'Add, edit, and delete vehicles',
          'View complete vehicle details and history',
          'Schedule maintenance and inspections',
          'Archive/activate vehicles',
          'Assign vehicles to drivers',
          'Upload and manage vehicle documents',
          'Import/export vehicle data',
          'Track odometer readings',
        ]),
        _buildFeatureCategory('Driver Management', Icons.badge, Colors.teal, [
          'Add and manage driver profiles',
          'Track driver licenses and expiration',
          'View driver performance metrics',
          'Assign drivers to vehicles and trips',
          'Monitor driver schedules',
          'Manage driver certifications',
          'Track Hours of Service (HOS) compliance',
        ]),
        _buildFeatureCategory('Trip Management', Icons.route, Colors.purple, [
          'Create and schedule trips',
          'Assign vehicles and drivers',
          'Monitor trip progress in real-time',
          'Update trip status',
          'Add waypoints and stops',
          'Modify routes and schedules',
          'View trip history and reports',
          'Track delivery confirmations',
        ]),
        _buildFeatureCategory('Real-time Tracking', Icons.location_on, Colors.red, [
          'Live GPS tracking of all vehicles',
          'View historical tracking data',
          'Set up geofencing and alerts',
          'Monitor vehicle status and alerts',
          'Generate location reports',
          'Configure tracking parameters',
          'Route optimization',
        ]),
        _buildFeatureCategory('Financial Management', Icons.account_balance, Colors.amber, [
          'Track all expenses (fuel, tolls, maintenance)',
          'Create and send invoices',
          'Process payments and reimbursements',
          'Set and monitor budgets',
          'Approve/reject expense claims',
          'Manage vendor payments',
          'Generate financial forecasts',
          'Tax reporting',
        ]),
        _buildFeatureCategory('Maintenance Operations', Icons.build_circle, Colors.orange, [
          'Create preventive maintenance schedules',
          'Track vehicle health and diagnostics',
          'Manage repair orders',
          'Monitor parts inventory',
          'Assign tasks to technicians',
          'Track service provider performance',
          'Manage warranties',
          'Vehicle inspection records',
        ]),
        _buildFeatureCategory('Compliance & Safety', Icons.verified_user, Colors.indigo, [
          'Track licenses and permits',
          'Monitor insurance policies',
          'Manage compliance documents',
          'Schedule safety inspections',
          'Log incidents and accidents',
          'Hours of Service compliance',
          'DOT compliance tracking',
          'Generate compliance reports',
        ]),
        _buildFeatureCategory('Customer Management', Icons.people, Colors.pink, [
          'Manage customer database',
          'Track customer communication history',
          'Create support tickets',
          'Send notifications to customers',
          'Provide shipment tracking',
          'Resolve customer inquiries',
          'Customer satisfaction metrics',
        ]),
        _buildFeatureCategory('Reports & Analytics', Icons.analytics, Colors.deepPurple, [
          'Fleet performance reports',
          'Driver performance metrics',
          'Financial reports',
          'Fuel consumption analysis',
          'Maintenance reports',
          'Compliance reports',
          'Custom report builder',
          'Export to PDF/Excel/CSV',
          'Schedule automated reports',
        ]),
      ],
    );
  }

  Widget _buildFeatureCategory(String title, IconData icon, Color color, List<String> features) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 18, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // PERMISSIONS TAB
  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(
            'Permission Matrix',
            'Overview of what each role can access and modify.',
            Icons.grid_on,
            Colors.deepOrange,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Capability System',
            '''100+ Hardcoded Capabilities:
• vehicle.view, vehicle.create, vehicle.edit
• driver.view.all, driver.create, driver.assign
• trip.create, trip.assign, trip.status.update
• tracking.view.all, tracking.history.view
• finance.view, expense.approve
• And many more...

Access Levels:
• None: No access
• View: Read-only access
• Limited: Restricted modification
• Full: Complete control''',
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Permission Overview', Icons.list_alt),
          const SizedBox(height: 12),
          _buildPermissionTable(),
          const SizedBox(height: 24),
          _buildSectionTitle('Custom Role Creation', Icons.add_circle),
          const SizedBox(height: 12),
          _buildCustomRoleInfo(),
        ],
      ),
    );
  }

  Widget _buildPermissionTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
          columns: const [
            DataColumn(label: Text('Feature', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Manager', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Dispatcher', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Driver', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Custom', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: [
            _buildPermissionRow('Add/Edit Vehicles', '✓ Full', '✓ Full', '✗ None', '✗ None', '⚙ Config'),
            _buildPermissionRow('View Vehicles', '✓ Full', '✓ Full', '✓ Limited', '◐ Own Only', '⚙ Config'),
            _buildPermissionRow('Create Trips', '✓ Full', '✓ Full', '✓ Full', '✗ None', '⚙ Config'),
            _buildPermissionRow('Real-time Tracking', '✓ Full', '✓ Full', '◐ Active', '◐ Own Only', '⚙ Config'),
            _buildPermissionRow('Financial Data', '✓ Full', '◐ View', '✗ None', '✗ None', '⚙ Config'),
            _buildPermissionRow('Maintenance', '✓ Full', '✓ Full', '✗ None', '◐ Report', '⚙ Config'),
            _buildPermissionRow('User Management', '✓ Full', '◐ Limited', '✗ None', '✗ None', '⚙ Config'),
          ],
        ),
      ),
    );
  }

  DataRow _buildPermissionRow(String feature, String admin, String manager, String dispatcher, String driver, String custom) {
    return DataRow(
      cells: [
        DataCell(Text(feature, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(admin, style: TextStyle(color: admin.contains('✓') ? Colors.green : Colors.red))),
        DataCell(Text(manager, style: TextStyle(color: manager.contains('✓') ? Colors.green : manager.contains('✗') ? Colors.red : Colors.orange))),
        DataCell(Text(dispatcher, style: TextStyle(color: dispatcher.contains('✓') ? Colors.green : dispatcher.contains('✗') ? Colors.red : Colors.orange))),
        DataCell(Text(driver, style: TextStyle(color: driver.contains('✓') ? Colors.green : driver.contains('✗') ? Colors.red : Colors.orange))),
        DataCell(Text(custom, style: const TextStyle(color: Colors.blue))),
      ],
    );
  }

  Widget _buildCustomRoleInfo() {
    return Column(
      children: [
        _buildInfoCard(
          'Template-Based Creation',
          '''1. Select Template(s):
   • Choose from 12 predefined roles
   • Mix multiple templates together
   • Or start from scratch

2. Customize Permissions:
   • Add/remove specific capabilities
   • Set access levels per feature
   • Add custom constraints (region, time)

3. Save as Template:
   • Reuse for similar roles
   • Share across organization
   • Version control

Example: Regional Manager
• Start with: Fleet Manager template
• Add: Financial view from Accountant
• Restrict: West Coast region only
• Result: Perfect fit for regional operations''',
          Colors.purple,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact admin to create custom roles')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Request Custom Role'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  // FAQ TAB
  Widget _buildFAQTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(
          'Frequently Asked Questions',
          'Common questions about the system.',
          Icons.quiz,
          Colors.teal,
        ),
        const SizedBox(height: 16),
        _buildFAQItem(
          'How do I get started?',
          'Sign up for an account, then either join an existing organization or create your own. You\'ll be assigned a role based on your position.',
        ),
        _buildFAQItem(
          'What are the 12 roles?',
          'Super Admin, Fleet Manager, Dispatcher, Driver, Accountant, Maintenance Manager, Compliance Officer, Operations Manager, Maintenance Technician, Customer Service, Viewer/Analyst, and Custom Role.',
        ),
        _buildFAQItem(
          'Can I have multiple roles?',
          'Yes, you can be assigned multiple roles depending on your responsibilities. Your effective permissions will be a combination of all assigned roles.',
        ),
        _buildFAQItem(
          'What is a custom role?',
          'A custom role is a flexible role where admins can select specific permissions from predefined templates or build from scratch. It allows precise access control tailored to your organization\'s needs.',
        ),
        _buildFAQItem(
          'How does the permission system work?',
          'The system uses a capability-based permission model with 100+ capabilities. Each role has specific capabilities assigned. Custom roles can mix capabilities from multiple templates.',
        ),
        _buildFAQItem(
          'Can I track vehicles in real-time?',
          'Yes, if you have tracking permissions for your role. Fleet Managers and Operations Managers can track all vehicles, while Drivers can share their own location.',
        ),
        _buildFAQItem(
          'How do I request a custom role?',
          'Contact your organization\'s Super Admin or Operations Manager. They can create custom roles by selecting permissions from predefined templates.',
        ),
        _buildFAQItem(
          'What happens if I need more permissions?',
          'Request a role change from your admin. They can either assign you a different predefined role or create a custom role with the specific permissions you need.',
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline, color: Colors.teal),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // REUSABLE WIDGETS
  Widget _buildHeaderCard(String title, String description, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
