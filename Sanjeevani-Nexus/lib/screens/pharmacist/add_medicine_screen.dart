import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/product_service.dart';
import '../../theme/app_theme.dart';

class AddMedicineScreen extends StatefulWidget {
  final String? seedName;
  final int? seedStock;
  final String? seedCategory;

  const AddMedicineScreen({
    super.key,
    this.seedName,
    this.seedStock,
    this.seedCategory,
  });

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final ProductService _productService = ProductService();
  final List<_MedicineDraft> _drafts = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addDraft(
      name: widget.seedName,
      stock: widget.seedStock,
      category: widget.seedCategory,
    );
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _addDraft({String? name, int? stock, String? category}) {
    setState(() {
      _drafts.add(
        _MedicineDraft(
          name: name ?? '',
          stock: stock?.toString() ?? '10',
          category: category ?? 'General',
        ),
      );
    });
  }

  void _removeDraft(int index) {
    if (_drafts.length == 1) return;
    final item = _drafts.removeAt(index);
    item.dispose();
    setState(() {});
  }

  Future<void> _saveAll() async {
    final payload = <Map<String, dynamic>>[];
    for (final d in _drafts) {
      final name = d.name.text.trim();
      final stock = int.tryParse(d.stock.text.trim());
      if (name.isEmpty || stock == null || stock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill medicine name and valid stock for all rows.'),
          ),
        );
        return;
      }

      final mrp = double.tryParse(d.mrp.text.trim());
      final sellingPrice = double.tryParse(d.sellingPrice.text.trim());
      payload.add({
        'medicine_name': name,
        'stock': stock,
        'category': d.category.text.trim().isEmpty ? 'General' : d.category.text.trim(),
        'generic_name': d.genericName.text.trim().isEmpty ? null : d.genericName.text.trim(),
        'brand_name': d.brandName.text.trim().isEmpty ? null : d.brandName.text.trim(),
        'batch_no': d.batchNo.text.trim().isEmpty ? null : d.batchNo.text.trim(),
        'expiry_date': d.expiryDate.text.trim().isEmpty ? null : d.expiryDate.text.trim(),
        'mrp': mrp ?? 0.0,
        'selling_price': sellingPrice ?? mrp ?? 0.0,
        'schedule': d.schedule.text.trim().isEmpty ? 'OTC' : d.schedule.text.trim(),
        'prescription_required': d.prescriptionRequired,
      });
    }

    setState(() => _saving = true);
    try {
      await _productService.addProductsBulk(payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save medicines: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGray,
      appBar: AppBar(
        title: const Text('Add Inventory Items'),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Text(
              'Add all medicine details once. You can save multiple items together.',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              itemCount: _drafts.length + 1,
              itemBuilder: (context, index) {
                if (index == _drafts.length) {
                  return const SizedBox(height: 90);
                }
                final d = _drafts[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Medicine ${index + 1}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => _removeDraft(index),
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                          ),
                        ],
                      ),
                      _field(d.name, 'Medicine Name*'),
                      _field(d.stock, 'Stock*', keyboardType: TextInputType.number),
                      _field(d.category, 'Category'),
                      _field(d.genericName, 'Generic Name'),
                      _field(d.brandName, 'Brand Name'),
                      _field(d.batchNo, 'Batch Number'),
                      _field(d.expiryDate, 'Expiry Date (YYYY-MM-DD)'),
                      Row(
                        children: [
                          Expanded(child: _field(d.mrp, 'MRP', keyboardType: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              d.sellingPrice,
                              'Selling Price',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      _field(d.schedule, 'Schedule (OTC/Rx)'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Prescription Required'),
                        value: d.prescriptionRequired,
                        onChanged: (v) => setState(() => d.prescriptionRequired = v),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _addDraft(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveAll,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save All'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
      ),
    );
  }
}

class _MedicineDraft {
  final TextEditingController name;
  final TextEditingController stock;
  final TextEditingController category;
  final TextEditingController genericName;
  final TextEditingController brandName;
  final TextEditingController batchNo;
  final TextEditingController expiryDate;
  final TextEditingController mrp;
  final TextEditingController sellingPrice;
  final TextEditingController schedule;
  bool prescriptionRequired;

  _MedicineDraft({
    required String name,
    required String stock,
    required String category,
  })  : name = TextEditingController(text: name),
        stock = TextEditingController(text: stock),
        category = TextEditingController(text: category),
        genericName = TextEditingController(),
        brandName = TextEditingController(),
        batchNo = TextEditingController(),
        expiryDate = TextEditingController(),
        mrp = TextEditingController(),
        sellingPrice = TextEditingController(),
        schedule = TextEditingController(text: 'OTC'),
        prescriptionRequired = false;

  void dispose() {
    name.dispose();
    stock.dispose();
    category.dispose();
    genericName.dispose();
    brandName.dispose();
    batchNo.dispose();
    expiryDate.dispose();
    mrp.dispose();
    sellingPrice.dispose();
    schedule.dispose();
  }
}
