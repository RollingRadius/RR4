import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/invoice_provider.dart';
import 'package:fleet_management/data/models/invoice_model.dart';
import 'package:intl/intl.dart';

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(invoiceProvider.notifier).loadInvoices());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshInvoices() async {
    await ref.read(invoiceProvider.notifier).loadInvoices(
          status: _selectedStatus,
        );
  }

  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    ref.read(invoiceProvider.notifier).loadInvoices(status: status);
  }

  void _showDeleteConfirmation(BuildContext context, InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
          'Are you sure you want to delete invoice ${invoice.invoiceNumber}?',
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
                  .read(invoiceProvider.notifier)
                  .deleteInvoice(invoice.id);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Invoice ${invoice.invoiceNumber} deleted successfully')),
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
    final invoiceState = ref.watch(invoiceProvider);

    // Calculate statistics
    final totalInvoices = invoiceState.total;
    final totalDue = invoiceState.invoices
        .fold<double>(0, (sum, inv) => sum + inv.amountDue);
    final overdueCount =
        invoiceState.invoices.where((inv) => inv.isOverdue).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.warning),
            onPressed: () {
              ref
                  .read(invoiceProvider.notifier)
                  .loadInvoices(overdueOnly: true);
            },
            tooltip: 'Show Overdue',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshInvoices,
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
                    label: const Text('Sent'),
                    selected: _selectedStatus == 'sent',
                    onSelected: (_) => _filterByStatus('sent'),
                    avatar: const Icon(Icons.send, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Partially Paid'),
                    selected: _selectedStatus == 'partially_paid',
                    onSelected: (_) => _filterByStatus('partially_paid'),
                    avatar: const Icon(Icons.payments, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Paid'),
                    selected: _selectedStatus == 'paid',
                    onSelected: (_) => _filterByStatus('paid'),
                    avatar: const Icon(Icons.check_circle, size: 18),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Overdue'),
                    selected: _selectedStatus == 'overdue',
                    onSelected: (_) => _filterByStatus('overdue'),
                    avatar: const Icon(Icons.warning, size: 18),
                  ),
                ],
              ),
            ),
          ),

          // Statistics Bar
          if (invoiceState.invoices.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatisticCard(
                    label: 'Total',
                    value: totalInvoices.toString(),
                    icon: Icons.description,
                    color: Colors.blue,
                  ),
                  _StatisticCard(
                    label: 'Total Due',
                    value: '₹${totalDue.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet,
                    color: Colors.orange,
                  ),
                  _StatisticCard(
                    label: 'Overdue',
                    value: overdueCount.toString(),
                    icon: Icons.warning,
                    color: Colors.red,
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Invoices List
          Expanded(
            child: invoiceState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : invoiceState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Error: ${invoiceState.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshInvoices,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : invoiceState.invoices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No invoices found',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your first invoice',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      context.push('/invoices/add'),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Invoice'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshInvoices,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: invoiceState.invoices.length,
                              itemBuilder: (context, index) {
                                final invoice = invoiceState.invoices[index];
                                return _InvoiceCard(
                                  invoice: invoice,
                                  onTap: () {
                                    context.push('/invoices/${invoice.id}');
                                  },
                                  onDelete: () =>
                                      _showDeleteConfirmation(context, invoice),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/invoices/add'),
        icon: const Icon(Icons.add),
        label: const Text('Create Invoice'),
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

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
    required this.onDelete,
  });

  Color _getStatusColor() {
    switch (invoice.status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'partially_paid':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
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
                  // Invoice Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      invoice.statusIcon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Invoice Number and Customer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          invoice.customerName,
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
                    child: Text(
                      invoice.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Amount Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:'),
                        Text(
                          invoice.formattedTotal,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    if (!invoice.isFullyPaid) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount Due:'),
                          Text(
                            invoice.formattedAmountDue,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Dates
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Invoice: ${dateFormat.format(invoice.invoiceDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(Icons.event, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${dateFormat.format(invoice.dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: invoice.isOverdue ? Colors.red : null,
                        ),
                  ),
                ],
              ),
              // Overdue Warning
              if (invoice.isOverdue)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'Overdue by ${-invoice.daysUntilDue} days',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Actions
              if (invoice.canEdit || invoice.canSend)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      if (invoice.canEdit)
                        TextButton.icon(
                          onPressed: () {
                            context.push('/invoices/${invoice.id}/edit');
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      if (invoice.canSend)
                        TextButton.icon(
                          onPressed: () async {
                            final success = await ref
                                .read(invoiceProvider.notifier)
                                .sendInvoice(invoice.id);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invoice sent')),
                              );
                            }
                          },
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('Send'),
                        ),
                      if (invoice.canEdit) const Spacer(),
                      if (invoice.canEdit)
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
