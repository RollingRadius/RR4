import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fleet_management/providers/invoice_provider.dart';
import 'package:fleet_management/data/models/invoice_model.dart';
import 'package:fleet_management/core/animations/app_animations.dart';

class SendInvoiceDialog extends ConsumerStatefulWidget {
  final InvoiceModel invoice;

  const SendInvoiceDialog({
    super.key,
    required this.invoice,
  });

  @override
  ConsumerState<SendInvoiceDialog> createState() => _SendInvoiceDialogState();
}

class _SendInvoiceDialogState extends ConsumerState<SendInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _recipientController;
  late TextEditingController _messageController;
  final List<String> _ccEmails = [];
  final TextEditingController _ccController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(
      text: widget.invoice.customerEmail ?? '',
    );
    _messageController = TextEditingController(
      text: _getDefaultMessage(),
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    _ccController.dispose();
    super.dispose();
  }

  String _getDefaultMessage() {
    return '''Dear ${widget.invoice.customerName},

Please find attached the invoice ${widget.invoice.invoiceNumber} for your review.

Invoice Details:
- Invoice Number: ${widget.invoice.invoiceNumber}
- Total Amount: ${widget.invoice.formattedTotal}
- Due Date: ${widget.invoice.dueDate.toString().split(' ')[0]}

Please process the payment at your earliest convenience.

Thank you for your business!

Best regards''';
  }

  void _addCcEmail() {
    final email = _ccController.text.trim();
    if (email.isNotEmpty && _isValidEmail(email)) {
      if (!_ccEmails.contains(email)) {
        setState(() {
          _ccEmails.add(email);
          _ccController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email already added')),
        );
      }
    }
  }

  void _removeCcEmail(String email) {
    setState(() {
      _ccEmails.remove(email);
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _sendInvoice() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSending = true);

      try {
        final success = await ref.read(invoiceProvider.notifier).sendInvoice(
              widget.invoice.id,
              recipientEmail: _recipientController.text.trim(),
              ccEmails: _ccEmails.isNotEmpty ? _ccEmails : null,
              customMessage:
                  _messageController.text.trim().isNotEmpty
                      ? _messageController.text.trim()
                      : null,
            );

        if (success && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invoice sent to ${_recipientController.text.trim()}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send invoice'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ScaleFade(
        delay: 0,
        duration: 400,
        child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.send, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Invoice',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.invoice.invoiceNumber,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipient Email
                      TextFormField(
                        controller: _recipientController,
                        decoration: const InputDecoration(
                          labelText: 'Recipient Email *',
                          hintText: 'customer@example.com',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter recipient email';
                          }
                          if (!_isValidEmail(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // CC Emails
                      const Text(
                        'CC Emails (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ccController,
                              decoration: const InputDecoration(
                                hintText: 'cc@example.com',
                                prefixIcon: Icon(Icons.person_add),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              onFieldSubmitted: (_) => _addCcEmail(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _addCcEmail,
                            icon: const Icon(Icons.add),
                            tooltip: 'Add CC',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // CC Email Chips
                      if (_ccEmails.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _ccEmails
                              .map(
                                (email) => Chip(
                                  label: Text(email),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () => _removeCcEmail(email),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 16),

                      // Custom Message
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Message',
                          hintText: 'Enter a custom message...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 12,
                        minLines: 8,
                      ),
                      const SizedBox(height: 16),

                      // Preview Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 20, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Invoice Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(
                              label: 'Customer',
                              value: widget.invoice.customerName,
                            ),
                            _DetailRow(
                              label: 'Amount',
                              value: widget.invoice.formattedTotal,
                            ),
                            _DetailRow(
                              label: 'Due Date',
                              value: widget.invoice.dueDate
                                  .toString()
                                  .split(' ')[0],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendInvoice,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Sending...' : 'Send Invoice'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),  // closes Container
      ),  // closes ScaleFade
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
