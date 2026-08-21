import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../services/clinic_repository.dart';
import '../theme/app_theme.dart';
import '../theme/glass_card.dart';

class BillGenerationView extends StatefulWidget {
  final Patient? preselectedPatient;

  const BillGenerationView({super.key, this.preselectedPatient});

  @override
  State<BillGenerationView> createState() => _BillGenerationViewState();
}

class _BillGenerationViewState extends State<BillGenerationView> {
  final _repository = ClinicRepository();

  Patient? _selectedPatient;
  final List<BillItem> _items = [];
  double _discount = 0.0;
  double _tax = 0.0;
  String _paymentStatus = 'Paid';
  String _paymentMethod = 'UPI';

  // Temporary line item inputs
  final _descController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '500');

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatient != null) {
      _selectedPatient = widget.preselectedPatient;
    }
    // Default initial item
    _items.add(
      BillItem(
        id: '1',
        description: 'Doctor Consultation Fee',
        quantity: 1,
        unitPrice: 500.0,
      ),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    final desc = _descController.text.trim();
    final qty = int.tryParse(_qtyController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (desc.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid item description and price.')),
      );
      return;
    }

    setState(() {
      _items.add(BillItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: desc,
        quantity: qty,
        unitPrice: price,
      ));
      _descController.clear();
      _qtyController.text = '1';
      _priceController.text = '200';
    });
  }

  void _addQuickPreset(String name, double price) {
    setState(() {
      _items.add(BillItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: name,
        quantity: 1,
        unitPrice: price,
      ));
    });
  }

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get total => (subtotal - _discount) + _tax > 0 ? (subtotal - _discount) + _tax : 0.0;

  Future<void> _generateAndShowBill() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient first.')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one bill item.')),
      );
      return;
    }

    final bill = await _repository.generateBill(
      patientId: _selectedPatient!.id,
      patientName: _selectedPatient!.name,
      patientPhone: _selectedPatient!.phone,
      items: _items,
      discount: _discount,
      tax: _tax,
      paymentStatus: _paymentStatus,
      paymentMethod: _paymentMethod,
    );

    if (mounted) {
      _showInvoicePreviewDialog(bill);
    }
  }

  void _showInvoicePreviewDialog(Bill bill) {
    final size = MediaQuery.of(context).size;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: size.width * 0.9,
          height: size.height * 0.85,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice #${bill.billNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: PdfPreview(
                  build: (format) => _generatePdfDocument(format, bill),
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdfDocument(PdfPageFormat format, Bill bill) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('HEALTHCARE CLINIC & CARE',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal800,
                            )),
                        pw.Text('123 Medical Enclave, Main Road'),
                        pw.Text('Phone: +91 98765 43210 | Email: care@clinic.com'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('TAX INVOICE',
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Invoice #: ${bill.billNumber}'),
                        pw.Text('Date: ${dateFormat.format(bill.date)}'),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1, height: 24),

                // Patient Info
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Billed To: ${bill.patientName}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('Phone: ${bill.patientPhone}'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('Payment Status: ${bill.paymentStatus}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('Payment Method: ${bill.paymentMethod}'),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Table
                pw.TableHelper.fromTextArray(
                  headers: ['#', 'Description', 'Qty', 'Unit Price', 'Total'],
                  data: List<List<String>>.generate(
                    bill.items.length,
                    (index) {
                      final item = bill.items[index];
                      return [
                        (index + 1).toString(),
                        item.description,
                        item.quantity.toString(),
                        'INR ${item.unitPrice.toStringAsFixed(2)}',
                        'INR ${item.totalPrice.toStringAsFixed(2)}',
                      ];
                    },
                  ),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                pw.SizedBox(height: 20),

                // Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      width: 250,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Subtotal:'),
                              pw.Text('INR ${bill.subtotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          if (bill.discount > 0)
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Discount:'),
                                pw.Text('- INR ${bill.discount.toStringAsFixed(2)}'),
                              ],
                            ),
                          if (bill.tax > 0)
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Tax / GST:'),
                                pw.Text('+ INR ${bill.tax.toStringAsFixed(2)}'),
                              ],
                            ),
                          pw.Divider(),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Grand Total:',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('INR ${bill.totalAmount.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    'Thank you for visiting! Wishing you speedy health and wellness.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return AnimatedBuilder(
      animation: _repository,
      builder: (context, _) {
        final patients = _repository.patients;

        final itemBuilderCard = GlassCard(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate Bill / Invoice',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(height: 12),

              // Patient Picker
              const Text(
                'Select Patient *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<Patient>(
                initialValue: _selectedPatient,
                hint: const Text('Choose existing patient...'),
                items: patients.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text('${p.name} (${p.phone})', style: TextStyle(fontSize: isMobile ? 13 : 14)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPatient = val),
              ),
              const SizedBox(height: 16),

              // Quick Presets
              const Text(
                'Quick Add Services:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Consultation (₹500)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _addQuickPreset('General Doctor Consultation', 500),
                  ),
                  ActionChip(
                    label: const Text('ECG (₹400)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _addQuickPreset('ECG Screening', 400),
                  ),
                  ActionChip(
                    label: const Text('Blood Sugar (₹200)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _addQuickPreset('Blood Sugar Test', 200),
                  ),
                  ActionChip(
                    label: const Text('Dressing (₹300)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _addQuickPreset('Wound Care & Dressing', 300),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Custom Item Adder
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Line Item',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        hintText: 'Item Description (e.g. Medicine name)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'Qty'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: 'Price (₹)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addItem,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Items List
              const Text(
                'Invoice Items',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              _items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No items added yet.'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (ctx, idx) => const Divider(height: 8),
                      itemBuilder: (ctx, idx) {
                        final item = _items[idx];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('₹${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                onPressed: () => setState(() => _items.removeAt(idx)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        );

        final summaryCard = GlassCard(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Billing Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Expanded(child: Text('Discount (₹):')),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0'),
                      onChanged: (val) => setState(() => _discount = double.tryParse(val) ?? 0.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Expanded(child: Text('Tax / GST (₹):')),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0'),
                      onChanged: (val) => setState(() => _tax = double.tryParse(val) ?? 0.0),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _paymentStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['Paid', 'Pending'].map((st) => DropdownMenuItem(value: st, child: Text(st))).toList(),
                onChanged: (val) => setState(() => _paymentStatus = val!),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: ['UPI', 'Cash', 'Card', 'NetBanking'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _generateAndShowBill,
                  icon: const Icon(Icons.print),
                  label: const Text('Generate & Preview Invoice'),
                ),
              ),
            ],
          ),
        );

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          child: isMobile
              ? Column(
                  children: [
                    itemBuilderCard,
                    const SizedBox(height: 12),
                    summaryCard,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: itemBuilderCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: summaryCard),
                  ],
                ),
        );
      },
    );
  }
}
