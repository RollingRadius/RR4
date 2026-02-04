import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/expense_provider.dart';
import 'package:fleet_management/data/models/expense_model.dart';
import 'package:intl/intl.dart';

class ExpensesListScreen extends ConsumerStatefulWidget {
  const ExpensesListScreen({super.key});

  @override
  ConsumerState<ExpensesListScreen> createState() => _ExpensesListScreenState();
}

class _ExpensesListScreenState extends ConsumerState<ExpensesListScreen> {
  String? _selectedStatus;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(expenseProvider.notifier).loadExpenses());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshExpenses() async {
    await ref.read(expenseProvider.notifier).loadExpenses(
          status: _selectedStatus,
          category: _selectedCategory,
        );
  }

  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    ref.read(expenseProvider.notifier).loadExpenses(
          status: status,
          category: _selectedCategory,
        );
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
    });
    ref.read(expenseProvider.notifier).loadExpenses(
          status: _selectedStatus,
          category: category,
        );
  }

  void _showDeleteConfirmation(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete expense ${expense.expenseNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(expenseProvider.notifier)
                  .deleteExpense(expense.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Expense ${expense.expenseNumber} deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'paid':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.edit;
      case 'submitted':
        return Icons.send;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'paid':
        return Icons.paid;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);

    // Calculate statistics
    final totalExpenses = expenseState.total;
    final pendingApproval =
        expenseState.expenses.where((e) => e.isSubmitted).length;
    final totalPaid = expenseState.expenses
        .where((e) => e.isPaid)
        .fold<double>(0, (sum, e) => sum + e.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              // TODO: Navigate to expense summary screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary screen coming soon')),
              );
            },
            tooltip: 'View Summary',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshExpenses,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedStatus == null,
                    onSelected: (_) => _filterByStatus(null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Draft'),
                    selected: _selectedStatus == 'draft',
                    onSelected: (_) => _filterByStatus('draft'),
                    avatar: const Icon(Icons.edit, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Submitted'),
                    selected: _selectedStatus == 'submitted',
                    onSelected: (_) => _filterByStatus('submitted'),
                    avatar: const Icon(Icons.send, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Approved'),
                    selected: _selectedStatus == 'approved',
                    onSelected: (_) => _filterByStatus('approved'),
                    avatar: const Icon(Icons.check_circle, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Rejected'),
                    selected: _selectedStatus == 'rejected',
                    onSelected: (_) => _filterByStatus('rejected'),
                    avatar: const Icon(Icons.cancel, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Paid'),
                    selected: _selectedStatus == 'paid',
                    onSelected: (_) => _filterByStatus('paid'),
                    avatar: const Icon(Icons.paid, size: 18),
                  ),
                ],
              ),
            ),
          ),

          // Category Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Category: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => _filterByCategory(null),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('⛽ Fuel'),
                    selected: _selectedCategory == 'fuel',
                    onSelected: (_) => _filterByCategory('fuel'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('🔧 Maintenance'),
                    selected: _selectedCategory == 'maintenance',
                    onSelected: (_) => _filterByCategory('maintenance'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('🛣️ Toll'),
                    selected: _selectedCategory == 'toll',
                    onSelected: (_) => _filterByCategory('toll'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('🅿️ Parking'),
                    selected: _selectedCategory == 'parking',
                    onSelected: (_) => _filterByCategory('parking'),
                  ),
                ],
              ),
            ),
          ),

          // Statistics Bar
          if (expenseState.expenses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatisticCard(
                    label: 'Total',
                    value: totalExpenses.toString(),
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                  _StatisticCard(
                    label: 'Pending',
                    value: pendingApproval.toString(),
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  _StatisticCard(
                    label: 'Paid',
                    value: '₹${totalPaid.toStringAsFixed(0)}',
                    icon: Icons.payments,
                    color: Colors.green,
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Expenses List
          Expanded(
            child: expenseState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : expenseState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${expenseState.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshExpenses,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : expenseState.expenses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No expenses found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add your first expense to get started',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      context.push('/expenses/add'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Expense'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshExpenses,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: expenseState.expenses.length,
                              itemBuilder: (context, index) {
                                final expense = expenseState.expenses[index];
                                return _ExpenseCard(
                                  expense: expense,
                                  onTap: () {
                                    // TODO: Navigate to expense details
                                    context.push('/expenses/${expense.id}');
                                  },
                                  onDelete: () =>
                                      _showDeleteConfirmation(context, expense),
                                  getStatusColor: _getStatusColor,
                                  getStatusIcon: _getStatusIcon,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatisticCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;

  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    required this.onDelete,
    required this.getStatusColor,
    required this.getStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(expense.status);
    final statusIcon = getStatusIcon(expense.status);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      expense.categoryIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Expense Number and Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.expenseNumber,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          expense.category.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          expense.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                expense.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Amount and Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(expense.expenseDate),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    expense.formattedAmount,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                  ),
                ],
              ),
              // Actions
              if (expense.canEdit || expense.canSubmit)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      if (expense.canEdit)
                        TextButton.icon(
                          onPressed: () {
                            context.push('/expenses/${expense.id}/edit');
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      if (expense.canSubmit)
                        TextButton.icon(
                          onPressed: () async {
                            final success = await ref
                                .read(expenseProvider.notifier)
                                .submitExpense(expense.id);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Expense submitted')),
                              );
                            }
                          },
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Submit'),
                        ),
                      if (expense.canEdit) const Spacer(),
                      if (expense.canEdit)
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
