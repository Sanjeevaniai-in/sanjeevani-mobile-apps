import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';

enum ScanUnitType { unit, strip, box }

class ScanProductScreen extends StatefulWidget {
  const ScanProductScreen({super.key});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  final ProductService _productService = ProductService();
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  File? _imageFile;
  bool _processing = false;
  String? _error;
  Map<String, String> _extracted = {};
  bool _saving = false;

  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _expiryController = TextEditingController();
  final _mrpController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _manufacturerController = TextEditingController();
  ScanUnitType _selectedUnitType = ScanUnitType.strip;

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _expiryController.dispose();
    _mrpController.dispose();
    _stockController.dispose();
    _manufacturerController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _processing = true;
        _error = null;
        _extracted = {};
      });

      final inputImage = InputImage.fromFilePath(picked.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final text = recognizedText.text;
      if (text.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'No text found in image. Try a clearer photo.';
        });
        return;
      }

      final parsed = _parseProductText(text);
      _extracted = parsed;

      _nameController.text = parsed['name'] ?? '';
      _batchController.text = parsed['batch'] ?? '';
      _expiryController.text = parsed['expiry'] ?? '';
      _mrpController.text = parsed['mrp'] ?? '';
      _manufacturerController.text = parsed['manufacturer'] ?? '';

      setState(() => _processing = false);
    } catch (e) {
      setState(() {
        _processing = false;
        _error = 'Failed to process image: $e';
      });
    }
  }

  Map<String, String> _parseProductText(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final result = <String, String>{
      'name': '',
      'batch': '',
      'expiry': '',
      'mrp': '',
      'manufacturer': ''
    };

    for (final line in lines) {
      final lower = line.toLowerCase();

      if (result['batch']!.isEmpty &&
          (lower.contains('batch') ||
              RegExp(r'batch\s*no', caseSensitive: false).hasMatch(line))) {
        final match = RegExp(r'([A-Z]{1,3}\d{4,})', caseSensitive: false)
            .firstMatch(line);
        if (match != null) result['batch'] = match.group(1)!;
      }

      if (result['expiry']!.isEmpty &&
          (lower.contains('exp') ||
              RegExp(r'\d{2}[/\-\.]\d{2}[/\-\.]\d{2,4}').hasMatch(line))) {
        final match =
            RegExp(r'(\d{2}[/\-\.]\d{2}[/\-\.]\d{2,4})').firstMatch(line);
        if (match != null) {
          result['expiry'] = match.group(1)!.replaceAll('.', '-');
        }
      }

      if (result['mrp']!.isEmpty &&
          (lower.contains('mrp') || line.contains('₹'))) {
        final match = RegExp(r'₹?\s*([\d,]+\.?\d*)').firstMatch(line);
        if (match != null) result['mrp'] = match.group(1)!.replaceAll(',', '');
      }

      if (result['manufacturer']!.isEmpty &&
          (lower.contains('pvt') ||
              lower.contains('ltd') ||
              lower.contains('pharma') ||
              lower.contains('labs') ||
              lower.contains('ind') ||
              lower.contains('co'))) {
        result['manufacturer'] = line
            .replaceAll(
                RegExp(r'(batch|mrp|exp|₹|\d)', caseSensitive: false), '')
            .trim();
      }

      if (result['name']!.isEmpty &&
          line.length > 3 &&
          !lower.contains('batch') &&
          !lower.contains('mrp') &&
          !lower.contains('exp') &&
          !lower.contains('take') &&
          !RegExp(r'^\d+$').hasMatch(line)) {
        result['name'] = line;
      }
    }

    if (result['name']!.isEmpty && lines.isNotEmpty) {
      result['name'] = lines.first;
    }

    return result;
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter medicine name')),
      );
      return;
    }

    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid stock quantity')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      int finalStock = stock;
      switch (_selectedUnitType) {
        case ScanUnitType.unit:
          finalStock = stock;
          break;
        case ScanUnitType.strip:
          finalStock = stock;
          break;
        case ScanUnitType.box:
          finalStock = stock * 10;
          break;
      }

      final expiry = _expiryController.text.trim();
      final expiryDate = expiry.isNotEmpty ? _parseExpiry(expiry) : null;

      await _productService.addProductRaw({
        'medicine_name': name,
        'stock': finalStock,
        'category': 'General',
        'generic_name': _manufacturerController.text.trim().isEmpty
            ? null
            : _manufacturerController.text.trim(),
        'batch_no': _batchController.text.trim().isEmpty
            ? null
            : _batchController.text.trim(),
        'expiry_date': expiryDate,
        'mrp': double.tryParse(_mrpController.text.trim()) ?? 0,
        'selling_price': double.tryParse(_mrpController.text.trim()) ?? 0,
        'base_uom': _selectedUnitType.name,
        'packaging': {
          'base_uom': _selectedUnitType.name,
          'levels': [
            {'level': 'unit', 'label': 'Unit', 'to_base_units': 1},
            {'level': 'strip', 'label': 'Strip', 'to_base_units': 10},
            {'level': 'box', 'label': 'Box', 'to_base_units': 100},
          ],
        },
      });

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _parseExpiry(String input) {
    final match =
        RegExp(r'(\d{2})[/\-\.](\d{2})[/\-\.](\d{2,4})').firstMatch(input);
    if (match == null) return input;
    final month = match.group(1)!;
    final year = match.group(3)!;
    final fullYear = year.length == 2 ? '20$year' : year;
    return '$fullYear-$month-01';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGray,
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile == null) ...[
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        size: 64,
                        color: AppTheme.darkGreen.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'Take a photo of the product',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Capture the box, strip, or label to extract details automatically',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _imageFile = null),
                icon: const Icon(Icons.refresh),
                label: const Text('Retake Photo'),
              ),
              const SizedBox(height: 16),
            ],
            if (_processing)
              Container(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Processing image...',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            if (_extracted.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.darkGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Details extracted! Please verify and edit if needed.',
                        style: GoogleFonts.inter(
                          color: AppTheme.darkGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit Type',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _unitChip('Unit', ScanUnitType.unit),
                        const SizedBox(width: 8),
                        _unitChip('Strip', ScanUnitType.strip),
                        const SizedBox(width: 8),
                        _unitChip('Box', ScanUnitType.box),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildField(_nameController, 'Medicine Name *', required: true),
              _buildField(_manufacturerController, 'Manufacturer / Generic'),
              _buildField(_batchController, 'Batch Number'),
              _buildField(_expiryController, 'Expiry Date (MM/YY or MM/YYYY)'),
              Row(
                children: [
                  Expanded(
                      child: _buildField(_stockController, 'Quantity *',
                          required: true, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildField(_mrpController, 'MRP',
                          keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveProduct,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _unitChip(String label, ScanUnitType type) {
    final selected = _selectedUnitType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedUnitType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.darkGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.darkGreen : AppTheme.cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint,
      {bool required = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          labelText: required ? '$hint *' : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
      ),
    );
  }
}
