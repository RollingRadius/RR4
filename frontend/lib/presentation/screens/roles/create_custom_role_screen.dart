import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/template_provider.dart';
import 'package:fleet_management/providers/custom_role_provider.dart';
import 'package:fleet_management/core/theme/app_theme.dart';
import 'package:fleet_management/l10n/app_localizations.dart';

class CreateCustomRoleScreen extends ConsumerStatefulWidget {
  const CreateCustomRoleScreen({super.key});

  @override
  ConsumerState<CreateCustomRoleScreen> createState() =>
      _CreateCustomRoleScreenState();
}

class _CreateCustomRoleScreenState
    extends ConsumerState<CreateCustomRoleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _currentStep = 0;
  String _creationType = 'template';
  List<String> _selectedTemplates = [];
  String _mergeStrategy = 'union';
  bool _initialized = false;

  // ─── Role icon/color maps (mirrors CustomRolesScreen) ───────────────────────
  static const _roleIcons = <String, IconData>{
    'super_admin': Icons.shield_rounded,
    'fleet_manager': Icons.directions_car_rounded,
    'dispatcher': Icons.assignment_turned_in_rounded,
    'driver': Icons.drive_eta_rounded,
    'accountant': Icons.account_balance_rounded,
    'maintenance_manager': Icons.build_rounded,
    'compliance_officer': Icons.gavel_rounded,
    'operations_manager': Icons.business_center_rounded,
    'maintenance_technician': Icons.construction_rounded,
    'customer_service': Icons.support_agent_rounded,
    'viewer_analyst': Icons.bar_chart_rounded,
  };

  static const _roleColors = <String, Color>{
    'super_admin': Color(0xFFEF4444),
    'fleet_manager': Color(0xFF3B82F6),
    'dispatcher': Color(0xFFF59E0B),
    'driver': Color(0xFF10B981),
    'accountant': Color(0xFF14B8A6),
    'maintenance_manager': Color(0xFF92400E),
    'compliance_officer': Color(0xFF7C3AED),
    'operations_manager': Color(0xFF4338CA),
    'maintenance_technician': Color(0xFFEA580C),
    'customer_service': Color(0xFFDB2777),
    'viewer_analyst': Color(0xFF0891B2),
  };

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(templateProvider.notifier).loadPredefinedTemplates();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (extra != null && extra['templateKey'] != null) {
        setState(() {
          _creationType = 'template';
          _selectedTemplates = [extra['templateKey'] as String];
          _currentStep = 1; // Jump to Basic Info, skip method selection
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ─── Computed helpers ────────────────────────────────────────────────────────

  List<String> _stepTitles(AppLocalizations l10n) => _creationType == 'template'
      ? [
          l10n.customRoleStepMethod,
          l10n.customRoleStepDetails,
          l10n.customRoleStepTemplates,
          l10n.customRoleStepReview
        ]
      : [
          l10n.customRoleStepMethod,
          l10n.customRoleStepDetails,
          l10n.customRoleStepReview
        ];

  bool get _isLastStep =>
      _currentStep == (_creationType == 'template' ? 3 : 2);

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Column(
        children: [
          _buildHeader(),
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildNavBar(),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    final stepTitles = _stepTitles(l10n);
    final stepLabel =
        stepTitles[_currentStep.clamp(0, stepTitles.length - 1)];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 14),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.bgPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E0E0)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.customRoleCreateTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        stepLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEC5B13), Color(0xFFD14A0A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step indicator ──────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    final steps = _stepTitles(AppLocalizations.of(context));
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFF1F0F0)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final isCompleted = _currentStep > i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? AppTheme.primaryBlue
                        : const Color(0xFFE2E0E0),
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              return _StepDot(
                index: stepIndex + 1,
                isCompleted: stepIndex < _currentStep,
                isActive: stepIndex == _currentStep,
                label: steps[stepIndex],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Step content dispatcher ─────────────────────────────────────────────────

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildMethodStep();
      case 1:
        return _buildBasicInfoStep();
      case 2:
        return _creationType == 'template'
            ? _buildTemplateSelectionStep()
            : _buildReviewStep();
      case 3:
        return _buildReviewStep();
      default:
        return const SizedBox();
    }
  }

  // ─── Step 0: Method ──────────────────────────────────────────────────────────

  Widget _buildMethodStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customRoleChooseMethod,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.customRoleChooseMethodHint,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        _MethodCard(
          icon: Icons.layers_rounded,
          title: l10n.customRoleFromTemplateTitle,
          subtitle: l10n.customRoleFromTemplateDesc,
          isSelected: _creationType == 'template',
          onTap: () => setState(() => _creationType = 'template'),
        ),
        const SizedBox(height: 12),
        _MethodCard(
          icon: Icons.draw_rounded,
          title: l10n.customRoleFromScratchTitle,
          subtitle: l10n.customRoleFromScratchDesc,
          isSelected: _creationType == 'scratch',
          onTap: () => setState(() {
            _creationType = 'scratch';
            _selectedTemplates = [];
          }),
        ),
      ],
    );
  }

  // ─── Step 1: Basic info ──────────────────────────────────────────────────────

  Widget _buildBasicInfoStep() {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.customRoleDetailsTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.customRoleDetailsHint,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.customRoleNameLabel,
              hintText: l10n.customRoleNameHint,
              prefixIcon: const Icon(Icons.badge_rounded, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.customRoleNameRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: l10n.customRoleDescriptionOptional,
              hintText: l10n.customRoleDescriptionHint,
              prefixIcon: const Icon(Icons.notes_rounded, size: 20),
            ),
            maxLines: 3,
          ),
          if (_creationType == 'template' && _selectedTemplates.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.primaryBlue.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppTheme.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.customRoleTemplatePreselected(_selectedTemplates.join(', ')),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Step 2: Template selection ──────────────────────────────────────────────

  Widget _buildTemplateSelectionStep() {
    final l10n = AppLocalizations.of(context);
    final templateState = ref.watch(templateProvider);

    if (templateState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    if (templateState.error != null) {
      return Center(
        child: Text(l10n.customRoleTemplateError('${templateState.error}'),
            style: const TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final templates = templateState.predefinedTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.customRoleSelectTemplates,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.customRoleSelectTemplatesHint,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.customRoleSelectedCount(_selectedTemplates.length),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...templates.map((template) {
          final roleKey = template['role_key'] as String;
          final roleName = template['role_name'] as String;
          final description = template['description'] as String? ?? '';
          final capCount = template['capability_count'] as int? ?? 0;
          final icon =
              _roleIcons[roleKey] ?? Icons.admin_panel_settings_rounded;
          final color = _roleColors[roleKey] ?? AppTheme.primaryBlue;
          final isSelected = _selectedTemplates.contains(roleKey);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TemplateCard(
              icon: icon,
              color: color,
              title: roleName,
              description: description,
              capCount: capCount,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTemplates.remove(roleKey);
                  } else {
                    _selectedTemplates.add(roleKey);
                  }
                });
              },
            ),
          );
        }).toList(),
        if (_selectedTemplates.length > 1) ...[
          const SizedBox(height: 20),
          Text(
            l10n.customRoleMergeStrategy,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _MethodCard(
            icon: Icons.merge_rounded,
            title: l10n.customRoleUnion,
            subtitle: l10n.customRoleUnionDesc,
            isSelected: _mergeStrategy == 'union',
            onTap: () => setState(() => _mergeStrategy = 'union'),
          ),
          const SizedBox(height: 8),
          _MethodCard(
            icon: Icons.join_inner_rounded,
            title: l10n.customRoleIntersection,
            subtitle: l10n.customRoleIntersectionDesc,
            isSelected: _mergeStrategy == 'intersection',
            onTap: () => setState(() => _mergeStrategy = 'intersection'),
          ),
        ],
      ],
    );
  }

  // ─── Step 3 (or 2 for scratch): Review ──────────────────────────────────────

  Widget _buildReviewStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customRoleReviewTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.customRoleReviewHint,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F0F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _ReviewRow(
                icon: Icons.badge_rounded,
                label: l10n.customRoleNameLabel,
                value: _nameController.text.isEmpty
                    ? l10n.customRoleNotSet
                    : _nameController.text,
                color: AppTheme.primaryBlue,
              ),
              const Divider(
                  height: 1, indent: 16, color: Color(0xFFF1F0F0)),
              _ReviewRow(
                icon: Icons.notes_rounded,
                label: l10n.customRoleDescription,
                value: _descriptionController.text.isEmpty
                    ? l10n.customRoleNoDescription
                    : _descriptionController.text,
                color: AppTheme.textSecondary,
              ),
              const Divider(
                  height: 1, indent: 16, color: Color(0xFFF1F0F0)),
              _ReviewRow(
                icon: _creationType == 'template'
                    ? Icons.layers_rounded
                    : Icons.draw_rounded,
                label: l10n.customRoleStepMethod,
                value: _creationType == 'template'
                    ? l10n.customRoleFromTemplate
                    : l10n.customRoleFromScratch,
                color: _creationType == 'template'
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF059669),
              ),
              if (_creationType == 'template' &&
                  _selectedTemplates.isNotEmpty) ...[
                const Divider(
                    height: 1, indent: 16, color: Color(0xFFF1F0F0)),
                _ReviewRow(
                  icon: Icons.library_books_rounded,
                  label: l10n.customRoleStepTemplates,
                  value: _selectedTemplates.join(', '),
                  color: AppTheme.primaryBlue,
                ),
                if (_selectedTemplates.length > 1) ...[
                  const Divider(
                      height: 1, indent: 16, color: Color(0xFFF1F0F0)),
                  _ReviewRow(
                    icon: Icons.merge_rounded,
                    label: l10n.customRoleMergeStrategy,
                    value: _mergeStrategy == 'union'
                        ? l10n.customRoleUnion
                        : l10n.customRoleIntersectionCommon,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ],
            ],
          ),
        ),
        if (_creationType == 'scratch') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.primaryBlue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.customRoleAfterCreateNote,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Navigation bar ──────────────────────────────────────────────────────────

  Widget _buildNavBar() {
    final l10n = AppLocalizations.of(context);
    final isLoading = ref.watch(customRoleProvider).isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F0F0))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: isLoading
                    ? null
                    : () => setState(() => _currentStep--),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E0E0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        l10n.commonBack,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 3,
            child: _isLastStep
                ? _buildCreateButton(isLoading)
                : _buildContinueButton(isLoading),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(bool isLoading) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: _onContinue,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEC5B13), Color(0xFFD14A0A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.commonContinue,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(bool isLoading) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: isLoading ? null : _createRole,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFEC5B13), Color(0xFFD14A0A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isLoading ? const Color(0xFFE2E0E0) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              isLoading ? l10n.customRoleCreating : l10n.customRoleCreateButton,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step navigation ─────────────────────────────────────────────────────────

  void _onContinue() {
    final l10n = AppLocalizations.of(context);
    if (_currentStep == 0) {
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 2 && _creationType == 'template') {
      if (_selectedTemplates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.customRoleSelectOneTemplate),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    }
  }

  // ─── Create role ─────────────────────────────────────────────────────────────

  Future<void> _createRole() async {
    final l10n = AppLocalizations.of(context);
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
        capabilities: {},
      );
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.customRoleCreated),
            backgroundColor: Colors.green,
          ),
        );
        if (_creationType == 'scratch') {
          final roleId = ref.read(customRoleProvider).lastCreatedRoleId;
          context.pop();
          if (roleId != null) {
            context.push('/roles/custom/$roleId/edit');
          }
        } else {
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.customRoleCreateFailed(
                ref.read(customRoleProvider).error ?? '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ─── Step dot indicator ────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final int index;
  final bool isCompleted;
  final bool isActive;
  final String label;

  const _StepDot({
    required this.index,
    required this.isCompleted,
    required this.isActive,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (isCompleted) {
      bg = AppTheme.statusActive;
      fg = Colors.white;
    } else if (isActive) {
      bg = AppTheme.primaryBlue;
      fg = Colors.white;
    } else {
      bg = const Color(0xFFE2E0E0);
      fg = AppTheme.textTertiary;
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: fg, size: 14)
                : Text(
                    '$index',
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.primaryBlue : AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ─── Method selection card ─────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primaryBlue.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : const Color(0xFFE2E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withOpacity(0.12)
                    : const Color(0xFFF8F6F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : const Color(0xFFE2E0E0),
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Template selection card ───────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final int capCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.capCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.verified_user_rounded,
                          size: 11, color: color.withOpacity(0.8)),
                      const SizedBox(width: 3),
                      Text(
                        l10n.customRoleCapabilityCount(capCount),
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE2E0E0),
                  width: 2,
                ),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review row ────────────────────────────────────────────────────────────────

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
