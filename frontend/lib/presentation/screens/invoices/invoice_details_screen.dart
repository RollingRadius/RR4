import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/invoice_provider.dart';
import 'package:fleet_management/data/models/invoice_model.dart';
import 'package:intl/intl.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class InvoiceDetailsScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailsScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  ConsumerState<InvoiceDetailsScreen> createState() =>
      _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends ConsumerState<InvoiceDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() =>
        ref.read(invoiceProvider.notifier).loadInvoice(widget.invoiceId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshInvoice() async {
    await ref.read(invoiceProvider.notifier).loadInvoice(widget.invoiceId);
  }

  void _showSendDialog() {
    // This will be implemented with send_invoice_dialog.dart
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Send dialog coming soon')),
    );
  }

  void _showRecordPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => _RecordPaymentDialog(
        invoice: ref.read(invoiceProvider).selectedInvoice!,
        onConfirm: (amount, date, method, reference, notes) async {
          final success = await ref.read(invoiceProvider.notifier).recordPayment(
                widget.invoiceId,
                amount: amount,
                date: date,
                method: method,
                reference: reference,
                notes: notes,
              );
          if (success && mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment recorded successfully')),
            );
          }
        },
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice'),
        content: const Text(
            'Are you sure you want to cancel this invoice? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(invoiceProvider.notifier)
                  .cancelInvoice(widget.invoiceId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice cancelled')),
                );
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text(
            'Are you sure you want to delete this invoice? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(invoiceProvider.notifier)
                  .deleteInvoice(widget.invoiceId);
              if (success && mounted) {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice deleted')),
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
    final invoice = invoiceState.selectedInvoice;

    if (invoiceState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Invoice not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        elevation: 2,
        actions: [
          if (invoice.canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/invoices/${widget.invoiceId}/edit');
              },
              tooltip: 'Edit',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshInvoice,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'send':
                  _showSendDialog();
                  break;
                case 'record_payment':
                  _showRecordPaymentDialog();
                  break;
                case 'download_pdf':
                  context.push('/invoices/${widget.invoiceId}/pdf');
                  break;
                case 'cancel':
                  _showCancelDialog();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (invoice.canSend)
                const PopupMenuItem(
                  value: 'send',
                  child: Row(
                    children: [
                      Icon(Icons.send, size: 20),
                      SizedBox(width: 8),
                      Text('Send Invoice'),
                    ],
                  ),
                ),
              if (!invoice.isFullyPaid)
                const PopupMenuItem(
                  value: 'record_payment',
                  child: Row(
                    children: [
                      Icon(Icons.payments, size: 20),
                      SizedBox(width: 8),
                      Text('Record Payment'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'download_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('Download PDF'),
                  ],
                ),
              ),
              if (invoice.canEdit)
                const PopupMenuItem(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 20, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Cancel Invoice'),
                    ],
                  ),
                ),
              if (invoice.canEdit)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Invoice'),
                    ],
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
            Tab(icon: Icon(Icons.payment), text: 'Payments'),
            Tab(icon: Icon(Icons.history), text: 'Activity'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshInvoice,
        child: TabBarView(
          controller: _tabController,
          children: [
            PageEntrance(child: _OverviewTab(invoice: invoice)),
            PageEntrance(child: _PaymentsTab(invoice: invoice)),
            PageEntrance(child: _ActivityTab(invoice: invoice)),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final InvoiceModel invoice;

  const _OverviewTab({required this.invoice});

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.invoiceNumber,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invoice Date: ${dateFormat.format(invoice.invoiceDate)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            'Due Date: ${dateFormat.format(invoice.dueDate)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: invoice.isOverdue ? Colors.red : null,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          invoice.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (invoice.isOverdue) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'OVERDUE by ${-invoice.daysUntilDue} days',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customer Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(),
                  _InfoRow(label: 'Name', value: invoice.customerName),
                  if (invoice.customerEmail != null)
                    _InfoRow(label: 'Email', value: invoice.customerEmail!),
                  if (invoice.customerPhone != null)
                    _InfoRow(label: 'Phone', value: invoice.customerPhone!),
                  if (invoice.customerAddress != null)
                    _InfoRow(label: 'Address', value: invoice.customerAddress!),
                  if (invoice.customerGstin != null)
                    _InfoRow(label: 'GSTIN', value: invoice.customerGstin!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Line Items
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Line Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Description')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Unit Price')),
                        DataColumn(label: Text('Amount')),
                      ],
                      rows: invoice.lineItems
                          .map(
                            (item) => DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      item.description,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(item.quantity.toString())),
                                DataCell(Text('₹${item.unitPrice.toStringAsFixed(2)}')),
                                DataCell(Text(
                                  '₹${item.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                )),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Amount Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _AmountRow(
                    label: 'Subtotal',
                    value: invoice.subtotal,
                    isSubtotal: true,
                  ),
                  _AmountRow(
                    label: 'Tax Amount',
                    value: invoice.taxAmount,
                    isSubtotal: true,
                  ),
                  const Divider(),
                  _AmountRow(
                    label: 'Total',
                    value: invoice.total,
                    isTotal: true,
                  ),
                  if (invoice.amountPaid > 0) ...[
                    _AmountRow(
                      label: 'Amount Paid',
                      value: invoice.amountPaid,
                      isSubtotal: true,
                      valueColor: Colors.green,
                    ),
                    const Divider(),
                    _AmountRow(
                      label: 'Amount Due',
                      value: invoice.amountDue,
                      isTotal: true,
                      valueColor: Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Additional Information
          if (invoice.notes != null || invoice.terms != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (invoice.notes != null) ...[
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(invoice.notes!),
                      if (invoice.terms != null) const SizedBox(height: 12),
                    ],
                    if (invoice.terms != null) ...[
                      Text(
                        'Terms',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(invoice.terms!),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final InvoiceModel invoice;

  const _PaymentsTab({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Summary
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        invoice.formattedTotal,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount Paid',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '₹${invoice.amountPaid.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount Due',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        invoice.formattedAmountDue,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Payment History
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '${invoice.payments?.length ?? 0} payment${(invoice.payments?.length ?? 0) != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (invoice.payments == null || invoice.payments!.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No payments recorded yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            )
          else
            ...invoice.payments!.map(
              (payment) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                  title: Text(
                    '₹${payment['amount'].toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${dateFormat.format(DateTime.parse(payment['payment_date']))}'),
                      Text('Method: ${payment['payment_method']}'),
                      if (payment['reference_number'] != null)
                        Text('Ref: ${payment['reference_number']}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      // Navigate to payment details
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment details coming soon')),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final InvoiceModel invoice;

  const _ActivityTab({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    // Build activity timeline from invoice data
    final activities = <Map<String, dynamic>>[];

    activities.add({
      'title': 'Invoice Created',
      'timestamp': invoice.createdAt,
      'icon': Icons.add_circle,
      'color': Colors.blue,
    });

    if (invoice.sentAt != null) {
      activities.add({
        'title': 'Invoice Sent',
        'timestamp': invoice.sentAt,
        'icon': Icons.send,
        'color': Colors.green,
      });
    }

    if (invoice.payments != null) {
      for (var payment in invoice.payments!) {
        activities.add({
          'title': 'Payment Received',
          'subtitle': '₹${payment['amount'].toStringAsFixed(2)} via ${payment['payment_method']}',
          'timestamp': DateTime.parse(payment['payment_date']),
          'icon': Icons.payment,
          'color': Colors.green,
        });
      }
    }

    if (invoice.status.toLowerCase() == 'cancelled') {
      activities.add({
        'title': 'Invoice Cancelled',
        'timestamp': invoice.updatedAt,
        'icon': Icons.cancel,
        'color': Colors.red,
      });
    }

    activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isLast = index == activities.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activity['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: activity['color'], width: 2),
                  ),
                  child: Icon(
                    activity['icon'],
                    color: activity['color'],
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (activity['subtitle'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      activity['subtitle'],
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(activity['timestamp']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
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

class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;
  final bool isSubtotal;
  final Color? valueColor;

  const _AmountRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isSubtotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordPaymentDialog extends StatefulWidget {
  final InvoiceModel invoice;
  final Function(double, DateTime, String, String?, String?) onConfirm;

  const _RecordPaymentDialog({
    required this.invoice,
    required this.onConfirm,
  });

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _referenceController;
  late TextEditingController _notesController;
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.invoice.amountDue.toStringAsFixed(2),
    );
    _referenceController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Payment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }
                  if (amount > widget.invoice.amountDue) {
                    return 'Amount cannot exceed due amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Payment Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_paymentDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _paymentDate = date);
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                  DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference Number (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onConfirm(
                double.parse(_amountController.text),
                _paymentDate,
                _paymentMethod,
                _referenceController.text.isEmpty
                    ? null
                    : _referenceController.text,
                _notesController.text.isEmpty ? null : _notesController.text,
              );
            }
          },
          child: const Text('Record Payment'),
        ),
      ],
    );
  }
}
