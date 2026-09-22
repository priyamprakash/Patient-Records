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

enum DiscountType { flat, percentage }

enum BillingCategory { consultation, diagnostic }

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

  // Discount configuration (% or ₹)
  DiscountType _discountType = DiscountType.flat;
  double _discountInput = 0.0;

  double _tax = 0.0;
  String _paymentStatus = 'Paid';
  String _paymentMethod = 'UPI';

  // Preset & Custom item category
  BillingCategory _selectedCategory = BillingCategory.consultation;
  BillingCategory _newItemCategory = BillingCategory.consultation;

  // Temporary line item inputs
  final _descController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '500');
  final _discountController = TextEditingController();

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
    _discountController.dispose();
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

    final categoryPrefix = _newItemCategory == BillingCategory.diagnostic ? '[Diagnostic] ' : '';

    setState(() {
      _items.add(BillItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: '$categoryPrefix$desc',
        quantity: qty,
        unitPrice: price,
      ));
      _descController.clear();
      _qtyController.text = '1';
      _priceController.text = '200';
    });
  }

  void _addQuickPreset(String name, double price, {bool isDiagnostic = false}) {
    final prefix = isDiagnostic ? '[Diagnostic] ' : '';
    setState(() {
      _items.add(BillItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: '$prefix$name',
        quantity: 1,
        unitPrice: price,
      ));
    });
  }

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get computedDiscount {
    if (_discountType == DiscountType.percentage) {
      final calculated = (subtotal * _discountInput) / 100.0;
      return calculated > subtotal ? subtotal : calculated;
    } else {
      return _discountInput > subtotal ? subtotal : _discountInput;
    }
  }

  double get total => (subtotal - computedDiscount) + _tax > 0 ? (subtotal - computedDiscount) + _tax : 0.0;

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
      discount: computedDiscount,
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

              const SizedBox(height: 16),

              // Quick Presets Category Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick Add Services:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Consultation', style: TextStyle(fontSize: 11)),
                        selected: _selectedCategory == BillingCategory.consultation,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = BillingCategory.consultation);
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.science_outlined, size: 14),
                            SizedBox(width: 4),
                            Text('Diagnostic Billing', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                        selected: _selectedCategory == BillingCategory.diagnostic,
                        selectedColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = BillingCategory.diagnostic);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Presets Chips based on Category
              if (_selectedCategory == BillingCategory.consultation)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('General Consultation (₹500)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('General Consultation', 500),
                    ),
                    ActionChip(
                      label: const Text('Follow-up Consultation (₹300)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Follow-up Consultation', 300),
                    ),
                    ActionChip(
                      label: const Text('Emergency Consultation (₹800)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Emergency Consultation', 800),
                    ),
                    ActionChip(
                      label: const Text('ECG Screening (₹400)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('ECG Screening', 400),
                    ),
                    ActionChip(
                      label: const Text('Wound Care & Dressing (₹300)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Wound Care & Dressing', 300),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.bloodtype, size: 14, color: Colors.redAccent),
                      label: const Text('Blood Sugar Test (₹150)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Fasting Blood Sugar Test', 150, isDiagnostic: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.science, size: 14, color: AppTheme.primaryTeal),
                      label: const Text('CBC Blood Count (₹250)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Complete Blood Count (CBC)', 250, isDiagnostic: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.science, size: 14, color: AppTheme.primaryTeal),
                      label: const Text('Lipid Profile (₹800)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Lipid Profile Panel', 800, isDiagnostic: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.science, size: 14, color: AppTheme.primaryTeal),
                      label: const Text('Thyroid Profile (₹500)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Thyroid Profile (T3, T4, TSH)', 500, isDiagnostic: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.science, size: 14, color: AppTheme.primaryTeal),
                      label: const Text('Liver Test LFT (₹750)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Liver Function Test (LFT)', 750, isDiagnostic: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.science, size: 14, color: AppTheme.primaryTeal),
                      label: const Text('Kidney Test KFT (₹700)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Kidney Function Test (KFT)', 700, isDiagnostic: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.biotech, size: 14, color: Colors.purple),
                      label: const Text('HbA1c Sugar (₹550)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('HbA1c Glycated Sugar Test', 550, isDiagnostic: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.science, size: 14, color: AppTheme.primaryTeal),
                      label: const Text('Urine Analysis (₹200)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Urine Routine Analysis', 200, isDiagnostic: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.camera_alt, size: 14, color: Colors.blueGrey),
                      label: const Text('Chest X-Ray (₹500)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Chest X-Ray PA View', 500, isDiagnostic: true),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.monitor_heart, size: 14, color: Colors.blue),
                      label: const Text('Ultrasound Abdomen (₹1000)', style: TextStyle(fontSize: 11)),
                      onPressed: () => _addQuickPreset('Ultrasound Abdomen & Pelvis', 1000, isDiagnostic: true),
                    ),
                  ],
                ),
              const SizedBox(height: 16),

              // Custom Item Adder
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Custom Item',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        SegmentedButton<BillingCategory>(
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 10)),
                          ),
                          segments: const [
                            ButtonSegment(
                              value: BillingCategory.consultation,
                              label: Text('General'),
                            ),
                            ButtonSegment(
                              value: BillingCategory.diagnostic,
                              label: Text('Diagnostic'),
                            ),
                          ],
                          selected: {_newItemCategory},
                          onSelectionChanged: (set) {
                            setState(() => _newItemCategory = set.first);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(
                        hintText: _newItemCategory == BillingCategory.diagnostic
                            ? 'Diagnostic Test Name (e.g. Vitamin D3)'
                            : 'Item Description (e.g. Injection)',
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
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
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
                        final isDiag = item.description.startsWith('[Diagnostic]');
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              if (isDiag) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'LAB',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  isDiag ? item.description.replaceFirst('[Diagnostic] ', '') : item.description,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
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
              const SizedBox(height: 12),

              // Discount Section (Supports % and ₹)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount:', style: TextStyle(fontWeight: FontWeight.w500)),
                      SegmentedButton<DiscountType>(
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: DiscountType.flat,
                            label: Text('Flat (₹)'),
                          ),
                          ButtonSegment(
                            value: DiscountType.percentage,
                            label: Text('Percent (%)'),
                          ),
                        ],
                        selected: {_discountType},
                        onSelectionChanged: (set) {
                          setState(() {
                            _discountType = set.first;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: _discountType == DiscountType.percentage ? 'Enter % (e.g. 10)' : 'Enter amount in ₹',
                            suffixText: _discountType == DiscountType.percentage ? '%' : '₹',
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _discountInput = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_discountInput > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      _discountType == DiscountType.percentage
                          ? '${_discountInput.toStringAsFixed(1)}% discount = -₹${computedDiscount.toStringAsFixed(2)}'
                          : '₹${computedDiscount.toStringAsFixed(2)} discount (${subtotal > 0 ? ((computedDiscount / subtotal) * 100).toStringAsFixed(1) : 0}%)',
                      style: const TextStyle(fontSize: 11, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  const Expanded(child: Text('Tax / GST (₹):')),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '0', isDense: true),
                      onChanged: (val) => setState(() => _tax = double.tryParse(val) ?? 0.0),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

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
