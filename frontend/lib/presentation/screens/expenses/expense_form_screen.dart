import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fleet_management/providers/expense_provider.dart';
import 'package:fleet_management/data/models/expense_model.dart';
import 'package:intl/intl.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? expenseId;

  const ExpenseFormScreen({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _taxAmountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
  DateTime? _selectedDate;
  String? _selectedVehicleId;
  String? _selectedDriverId;
  String? _selectedVendorId;

  bool _isLoading = false;
  ExpenseModel? _editingExpense;

  final List<String> _categories = [
    'fuel',
    'maintenance',
    'toll',
    'parking',
    'insurance',
    'salary',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    if (widget.expenseId != null) {
      _loadExpense();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _taxAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadExpense() async {
    setState(() => _isLoading = true);
    final expense = await ref
        .read(expenseProvider.notifier)
        .getExpenseById(widget.expenseId!);

    if (expense != null && mounted) {
      setState(() {
        _editingExpense = expense;
        _descriptionController.text = expense.description;
        _amountController.text = expense.amount.toString();
        _taxAmountController.text = expense.taxAmount.toString();
        _notesController.text = expense.notes ?? '';
        _selectedCategory = expense.category;
        _selectedDate = expense.expenseDate;
        _selectedVehicleId = expense.vehicleId;
        _selectedDriverId = expense.driverId;
        _selectedVendorId = expense.vendorId;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Expense Date',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double get _totalAmount {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final tax = double.tryParse(_taxAmountController.text) ?? 0;
    return amount + tax;
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'category': _selectedCategory!,
      'description': _descriptionController.text.trim(),
      'amount': double.parse(_amountController.text),
      'tax_amount': double.tryParse(_taxAmountController.text) ?? 0,
      'expense_date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      if (_selectedVehicleId != null) 'vehicle_id': _selectedVehicleId,
      if (_selectedDriverId != null) 'driver_id': _selectedDriverId,
      if (_selectedVendorId != null) 'vendor_id': _selectedVendorId,
      if (_notesController.text.isNotEmpty) 'notes': _notesController.text.trim(),
    };

    bool success;
    if (widget.expenseId != null) {
      success = await ref
          .read(expenseProvider.notifier)
          .updateExpense(widget.expenseId!, data);
    } else {
      success = await ref.read(expenseProvider.notifier).createExpense(data);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.expenseId != null
              ? 'Expense updated successfully'
              : 'Expense created successfully'),
        ),
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(expenseProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to save expense')),
      );
    }
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return '⛽';
      case 'maintenance':
        return '🔧';
      case 'toll':
        return '🛣️';
      case 'parking':
        return '🅿️';
      case 'insurance':
        return '🛡️';
      case 'salary':
        return '💰';
      default:
        return '📝';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseId != null ? 'Edit Expense' : 'Add Expense'),
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic Information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),

                            // Category Selection
                            const Text(
                              'Category *',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categories.map((category) {
                                final isSelected = _selectedCategory == category;
                                return ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_getCategoryIcon(category)),
                                      const SizedBox(width: 4),
                                      Text(category.toUpperCase()),
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected ? category : null;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description *',
                                hintText: 'Enter expense description',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Description is required';
                                }
                                if (value.trim().length < 3) {
                                  return 'Description must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Expense Date
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Expense Date *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat('MMM dd, yyyy').format(_selectedDate!),
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount Details',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),

                            // Amount
                            TextFormField(
                              controller: _amountController,
                              decoration: const InputDecoration(
                                labelText: 'Amount (₹) *',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Amount is required';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Tax Amount
                            TextFormField(
                              controller: _taxAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Tax Amount (₹)',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.account_balance),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final tax = double.tryParse(value);
                                  if (tax == null || tax < 0) {
                                    return 'Please enter a valid tax amount';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Total Amount Display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${_totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // References Card (Optional)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'References (Optional)',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Link this expense to a vehicle, driver, or vendor',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // TODO: Add vehicle, driver, and vendor dropdowns
                            // These would require loading the respective data
                            const ListTile(
                              leading: Icon(Icons.directions_car),
                              title: Text('Vehicle'),
                              subtitle: Text('Select vehicle (coming soon)'),
                            ),
                            const Divider(),
                            const ListTile(
                              leading: Icon(Icons.person),
                              title: Text('Driver'),
                              subtitle: Text('Select driver (coming soon)'),
                            ),
                            const Divider(),
                            const ListTile(
                              leading: Icon(Icons.store),
                              title: Text('Vendor'),
                              subtitle: Text('Select vendor (coming soon)'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Additional Notes',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes (Optional)',
                                hintText: 'Add any additional notes here',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                              ),
                              maxLines: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveExpense,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(widget.expenseId != null
                                    ? 'Update Expense'
                                    : 'Create Expense'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
