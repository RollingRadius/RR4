import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/expense_provider.dart';
import 'package:fleet_management/core/animations/app_animations.dart';
import 'package:intl/intl.dart';

class ExpenseSummaryScreen extends ConsumerStatefulWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  ConsumerState<ExpenseSummaryScreen> createState() =>
      _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends ConsumerState<ExpenseSummaryScreen> {
  String _groupBy = 'category';
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    await ref.read(expenseProvider.notifier).loadSummary(
          groupBy: _groupBy,
          fromDate: _fromDate != null
              ? DateFormat('yyyy-MM-dd').format(_fromDate!)
              : null,
          toDate:
              _toDate != null ? DateFormat('yyyy-MM-dd').format(_toDate!) : null,
        );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadSummary();
    }
  }

  void _clearDateRange() {
    setState(() {
      _fromDate = null;
      _toDate = null;
    });
    _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final summary = expenseState.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Summary'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group By
                const Text(
                  'Group By:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Category'),
                        selected: _groupBy == 'category',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _groupBy = 'category');
                            _loadSummary();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Vehicle'),
                        selected: _groupBy == 'vehicle',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _groupBy = 'vehicle');
                            _loadSummary();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Month'),
                        selected: _groupBy == 'month',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _groupBy = 'month');
                            _loadSummary();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(_fromDate != null && _toDate != null
                            ? '${DateFormat('MMM dd').format(_fromDate!)} - ${DateFormat('MMM dd, yyyy').format(_toDate!)}'
                            : 'Select Date Range'),
                      ),
                    ),
                    if (_fromDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _clearDateRange,
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Summary Content
          Expanded(
            child: expenseState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : summary == null
                    ? const Center(child: Text('No data available'))
                    : _buildSummaryContent(summary),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent(Map<String, dynamic> summary) {
    final grandTotal = summary['grand_total'] as num? ?? 0;
    final totalCount = summary['total_count'] as int? ?? 0;
    final summaryList = summary['summary'] as List? ?? [];

    return PageEntrance(
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long,
                            color: Colors.blue, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          totalCount.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text('Total Expenses'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: Colors.green.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.currency_rupee,
                            color: Colors.green, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          '₹${grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text('Total Amount'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary List
          Text(
            'Breakdown',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (summaryList.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No expenses found'),
              ),
            )
          else
            ...summaryList.map((item) => _buildSummaryItem(item, grandTotal)),
        ],
      ),
    ),  // closes PageEntrance
    );
  }

  Widget _buildSummaryItem(Map<String, dynamic> item, num grandTotal) {
    final amount = (item['total_amount'] as num? ?? 0).toDouble();
    final count = item['count'] as int? ?? 0;
    final percentage = grandTotal > 0 ? (amount / grandTotal * 100) : 0.0;

    String label;
    if (_groupBy == 'category') {
      label = (item['category'] as String? ?? 'Unknown').toUpperCase();
    } else if (_groupBy == 'vehicle') {
      label = item['vehicle_id'] as String? ?? 'No Vehicle';
    } else {
      label = item['month'] as String? ?? 'Unknown';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blue.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$count expense${count != 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
