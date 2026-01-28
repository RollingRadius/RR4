import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/template_provider.dart';
import 'package:fleet_management/providers/custom_role_provider.dart';

class CreateCustomRoleScreen extends ConsumerStatefulWidget {
  const CreateCustomRoleScreen({super.key});

  @override
  ConsumerState<CreateCustomRoleScreen> createState() => _CreateCustomRoleScreenState();
}

class _CreateCustomRoleScreenState extends ConsumerState<CreateCustomRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _currentStep = 0;
  String _creationType = 'template'; // 'template' or 'scratch'
  List<String> _selectedTemplates = [];
  String _mergeStrategy = 'union';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(templateProvider.notifier).loadPredefinedTemplates();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Custom Role'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        steps: [
          Step(
            title: const Text('Creation Method'),
            content: _buildCreationMethodStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Basic Information'),
            content: _buildBasicInfoStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          if (_creationType == 'template')
            Step(
              title: const Text('Select Templates'),
              content: _buildTemplateSelectionStep(),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
          Step(
            title: const Text('Review & Create'),
            content: _buildReviewStep(),
            isActive: _currentStep >= (_creationType == 'template' ? 3 : 2),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose how to create your custom role:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        RadioListTile<String>(
          title: const Text('Start from Template'),
          subtitle: const Text('Use predefined role templates as a starting point'),
          value: 'template',
          groupValue: _creationType,
          onChanged: (value) {
            setState(() {
              _creationType = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('Start from Scratch'),
          subtitle: const Text('Build a completely custom role'),
          value: 'scratch',
          groupValue: _creationType,
          onChanged: (value) {
            setState(() {
              _creationType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Role Name',
              border: OutlineInputBorder(),
              hintText: 'e.g., Regional Manager - West Coast',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a role name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
              hintText: 'Describe the purpose of this role',
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSelectionStep() {
    final templateState = ref.watch(templateProvider);

    if (templateState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (templateState.error != null) {
      return Center(child: Text('Error: ${templateState.error}'));
    }

    final templates = templateState.predefinedTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select one or more templates to combine:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${_selectedTemplates.length}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ...templates.map((template) {
          final roleKey = template['role_key'] as String;
          final roleName = template['role_name'] as String;
          final description = template['description'] as String? ?? '';
          final capCount = template['capability_count'] as int? ?? 0;

          return CheckboxListTile(
            title: Text(roleName),
            subtitle: Text('$description\n$capCount capabilities'),
            value: _selectedTemplates.contains(roleKey),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedTemplates.add(roleKey);
                } else {
                  _selectedTemplates.remove(roleKey);
                }
              });
            },
          );
        }).toList(),
        if (_selectedTemplates.length > 1) ...[
          const SizedBox(height: 16),
          const Text(
            'Merge Strategy:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          RadioListTile<String>(
            title: const Text('Union (Combine All)'),
            subtitle: const Text('Include all capabilities from selected templates'),
            value: 'union',
            groupValue: _mergeStrategy,
            onChanged: (value) {
              setState(() {
                _mergeStrategy = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Intersection (Only Common)'),
            subtitle: const Text('Include only capabilities common to all templates'),
            value: 'intersection',
            groupValue: _mergeStrategy,
            onChanged: (value) {
              setState(() {
                _mergeStrategy = value!;
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review your custom role:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _ReviewItem(label: 'Role Name', value: _nameController.text),
        if (_descriptionController.text.isNotEmpty)
          _ReviewItem(label: 'Description', value: _descriptionController.text),
        _ReviewItem(
          label: 'Creation Method',
          value: _creationType == 'template' ? 'From Template' : 'From Scratch',
        ),
        if (_creationType == 'template' && _selectedTemplates.isNotEmpty) ...[
          _ReviewItem(
            label: 'Selected Templates',
            value: _selectedTemplates.join(', '),
          ),
          if (_selectedTemplates.length > 1)
            _ReviewItem(
              label: 'Merge Strategy',
              value: _mergeStrategy == 'union' ? 'Union (Combine All)' : 'Intersection (Common Only)',
            ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _createRole,
            icon: const Icon(Icons.check),
            label: const Text('Create Role'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 2 && _creationType == 'template') {
      if (_selectedTemplates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one template'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() => _currentStep++);
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _createRole() async {
    final roleNotifier = ref.read(customRoleProvider.notifier);
    bool success = false;

    if (_creationType == 'template') {
      success = await roleNotifier.createFromTemplate(
        roleName: _nameController.text.trim(),
        templateKeys: _selectedTemplates,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        mergeStrategy: _mergeStrategy,
      );
    } else {
      success = await roleNotifier.createCustomRole(
        roleName: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        capabilities: {}, // Empty - will be configured in edit screen
      );
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom role created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create role: ${ref.read(customRoleProvider).error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ReviewItem extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
