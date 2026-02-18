import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/expense_provider.dart';
import 'package:fleet_management/data/models/expense_model.dart';
import 'package:intl/intl.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class ExpenseDetailsScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseDetailsScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseDetailsScreen> createState() =>
      _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends ConsumerState<ExpenseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ExpenseModel? _expense;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExpense();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadExpense() async {
    setState(() => _isLoading = true);
    final expense =
        await ref.read(expenseProvider.notifier).getExpenseById(widget.expenseId);
    if (mounted) {
      setState(() {
        _expense = expense;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitExpense() async {
    final success =
        await ref.read(expenseProvider.notifier).submitExpense(widget.expenseId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense submitted for approval')),
      );
      _loadExpense();
    }
  }

  Future<void> _approveExpense(bool approved, {String? reason}) async {
    final success = await ref.read(expenseProvider.notifier).approveExpense(
          widget.expenseId,
          approved: approved,
          rejectionReason: reason,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(approved ? 'Expense approved' : 'Expense rejected')),
      );
      _loadExpense();
    }
  }

  Future<void> _markAsPaid() async {
    final success =
        await ref.read(expenseProvider.notifier).markExpensePaid(widget.expenseId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense marked as paid')),
      );
      _loadExpense();
    }
  }

  void _showApprovalDialog() {
    showDialog(
      context: context,
      builder: (context) => _ApprovalDialog(
        onApprove: () => _approveExpense(true),
        onReject: (reason) => _approveExpense(false, reason: reason),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete expense ${_expense?.expenseNumber}?',
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
                  .deleteExpense(widget.expenseId);
              if (success && mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_expense == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Details')),
        body: const Center(child: Text('Expense not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_expense!.expenseNumber),
        elevation: 2,
        actions: [
          if (_expense!.canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/expenses/${widget.expenseId}/edit');
              },
              tooltip: 'Edit',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpense,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              if (_expense!.canEdit)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Overview'),
            Tab(icon: Icon(Icons.attach_file), text: 'Attachments'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PageEntrance(child: _OverviewTab(expense: _expense!)),
          PageEntrance(child: _AttachmentsTab(expense: _expense!)),
          PageEntrance(child: _HistoryTab(expense: _expense!)),
        ],
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget? _buildActionBar() {
    if (_expense == null) return null;

    final actions = <Widget>[];

    if (_expense!.canSubmit) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _submitExpense,
            icon: const Icon(Icons.send),
            label: const Text('Submit'),
          ),
        ),
      );
    }

    if (_expense!.canApprove) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showApprovalDialog,
            icon: const Icon(Icons.check_circle),
            label: const Text('Approve/Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ),
      );
    }

    if (_expense!.canMarkPaid) {
      actions.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _markAsPaid,
            icon: const Icon(Icons.paid),
            label: const Text('Mark Paid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
          ),
        ),
      );
    }

    if (actions.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: actions
            .expand((widget) => [widget, const SizedBox(width: 8)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final ExpenseModel expense;

  const _OverviewTab({required this.expense});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final dateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          expense.categoryIcon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.expenseNumber,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              expense.category.toUpperCase(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      _StatusBadge(expense: expense),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Amount'),
                          Text(
                            '₹${expense.amount.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Tax'),
                          Text(
                            '₹${expense.taxAmount.toStringAsFixed(2)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('Total'),
                          Text(
                            expense.formattedAmount,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.description,
                    label: 'Description',
                    value: expense.description,
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Expense Date',
                    value: dateFormat.format(expense.expenseDate),
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.person,
                    label: 'Created By',
                    value: expense.createdBy ?? 'Unknown',
                  ),
                  const Divider(),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Created At',
                    value: dateTimeFormat.format(expense.createdAt),
                  ),
                  if (expense.notes != null) ...[
                    const Divider(),
                    _DetailRow(
                      icon: Icons.note,
                      label: 'Notes',
                      value: expense.notes!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Workflow Info Card
          if (expense.submittedAt != null ||
              expense.approvedAt != null ||
              expense.paidAt != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workflow Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    if (expense.submittedAt != null) ...[
                      _DetailRow(
                        icon: Icons.send,
                        label: 'Submitted At',
                        value: dateTimeFormat.format(expense.submittedAt!),
                      ),
                      const Divider(),
                    ],
                    if (expense.approvedAt != null) ...[
                      _DetailRow(
                        icon: expense.isApproved
                            ? Icons.check_circle
                            : Icons.cancel,
                        label: expense.isApproved ? 'Approved At' : 'Rejected At',
                        value: dateTimeFormat.format(expense.approvedAt!),
                      ),
                      if (expense.rejectionReason != null) ...[
                        const Divider(),
                        _DetailRow(
                          icon: Icons.info,
                          label: 'Rejection Reason',
                          value: expense.rejectionReason!,
                        ),
                      ],
                      const Divider(),
                    ],
                    if (expense.paidAt != null)
                      _DetailRow(
                        icon: Icons.paid,
                        label: 'Paid At',
                        value: dateTimeFormat.format(expense.paidAt!),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentsTab extends StatelessWidget {
  final ExpenseModel expense;

  const _AttachmentsTab({required this.expense});

  @override
  Widget build(BuildContext context) {
    if (expense.attachments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_file_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No attachments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload receipts or documents',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('File upload feature coming soon')),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Attachment'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expense.attachments.length,
      itemBuilder: (context, index) {
        final attachment = expense.attachments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(attachment.fileName),
            subtitle: Text(attachment.formattedSize),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () {
                    // TODO: View attachment
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    // TODO: Download attachment
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // TODO: Delete attachment
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final ExpenseModel expense;

  const _HistoryTab({required this.expense});

  @override
  Widget build(BuildContext context) {
    final timeline = _buildTimeline();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final event = timeline[index];
        return _TimelineItem(
          icon: event['icon'] as IconData,
          title: event['title'] as String,
          subtitle: event['subtitle'] as String,
          timestamp: event['timestamp'] as DateTime,
          isLast: index == timeline.length - 1,
          color: event['color'] as Color,
        );
      },
    );
  }

  List<Map<String, dynamic>> _buildTimeline() {
    final timeline = <Map<String, dynamic>>[];

    timeline.add({
      'icon': Icons.create,
      'title': 'Expense Created',
      'subtitle': 'Expense was created in draft status',
      'timestamp': expense.createdAt,
      'color': Colors.blue,
    });

    if (expense.submittedAt != null) {
      timeline.add({
        'icon': Icons.send,
        'title': 'Submitted for Approval',
        'subtitle': 'Expense submitted for review',
        'timestamp': expense.submittedAt!,
        'color': Colors.blue,
      });
    }

    if (expense.approvedAt != null) {
      timeline.add({
        'icon': expense.isApproved ? Icons.check_circle : Icons.cancel,
        'title': expense.isApproved ? 'Approved' : 'Rejected',
        'subtitle': expense.isApproved
            ? 'Expense was approved'
            : 'Expense was rejected${expense.rejectionReason != null ? ': ${expense.rejectionReason}' : ''}',
        'timestamp': expense.approvedAt!,
        'color': expense.isApproved ? Colors.green : Colors.red,
      });
    }

    if (expense.paidAt != null) {
      timeline.add({
        'icon': Icons.paid,
        'title': 'Marked as Paid',
        'subtitle': 'Payment completed',
        'timestamp': expense.paidAt!,
        'color': Colors.teal,
      });
    }

    return timeline.reversed.toList();
  }
}

class _StatusBadge extends StatelessWidget {
  final ExpenseModel expense;

  const _StatusBadge({required this.expense});

  Color _getColor() {
    switch (expense.status.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        expense.status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final bool isLast;
  final Color color;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isLast,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy hh:mm a').format(timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalDialog extends StatefulWidget {
  final VoidCallback onApprove;
  final Function(String) onReject;

  const _ApprovalDialog({
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _reasonController = TextEditingController();
  bool _isApproving = true;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isApproving ? 'Approve Expense' : 'Reject Expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Approve'),
                icon: Icon(Icons.check_circle),
              ),
              ButtonSegment(
                value: false,
                label: Text('Reject'),
                icon: Icon(Icons.cancel),
              ),
            ],
            selected: {_isApproving},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _isApproving = newSelection.first;
              });
            },
          ),
          if (!_isApproving) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'Enter reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_isApproving) {
              Navigator.pop(context);
              widget.onApprove();
            } else {
              if (_reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please provide a rejection reason')),
                );
                return;
              }
              Navigator.pop(context);
              widget.onReject(_reasonController.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isApproving ? Colors.green : Colors.red,
          ),
          child: Text(_isApproving ? 'Approve' : 'Reject'),
        ),
      ],
    );
  }
}
