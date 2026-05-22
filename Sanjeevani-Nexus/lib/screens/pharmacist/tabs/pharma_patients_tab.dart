import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/patient_service.dart';
import '../../../theme/app_theme.dart';

class PharmaPatientsTab extends StatefulWidget {
  const PharmaPatientsTab({super.key});

  @override
  State<PharmaPatientsTab> createState() => _PharmaPatientsTabState();
}

class _PharmaPatientsTabState extends State<PharmaPatientsTab> {
  final PatientService _patientService = PatientService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  List<Map<String, dynamic>> _patients = const [];
  Map<String, dynamic> _summary = const {};

  @override
  void initState() {
    super.initState();
    _loadPatients(showLoader: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients({bool showLoader = true}) async {
    if (mounted) {
      setState(() {
        _error = null;
        if (showLoader && _patients.isEmpty) {
          _loading = true;
        } else {
          _refreshing = true;
        }
      });
    }

    try {
      final data = await _patientService.getLivePatients();
      if (!mounted) return;
      final patientsRaw = data['patients'];
      final summaryRaw = data['summary'];
      setState(() {
        _patients = patientsRaw is List
            ? patientsRaw.whereType<Map<String, dynamic>>().toList()
            : const [];
        _summary = summaryRaw is Map<String, dynamic> ? summaryRaw : const {};
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _refreshing = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPatients {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _patients;
    return _patients.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final id = (p['patient_id'] ?? '').toString().toLowerCase();
      final medicine = (p['latest_medicine'] ?? '').toString().toLowerCase();
      return name.contains(query) || id.contains(query) || medicine.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 54, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Unable to load patient list',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadPatients,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final patients = _filteredPatients;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by patient name, ID, or medicine',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppTheme.bgGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _PatientStat(
                    value: '${_summary['total_patients'] ?? _patients.length}',
                    label: 'Total Patients',
                    color: AppTheme.darkGreen,
                  ),
                  const SizedBox(width: 12),
                  _PatientStat(
                    value: '${_summary['repeat_patients'] ?? 0}',
                    label: 'Repeat Patients',
                    color: AppTheme.purple,
                  ),
                  const SizedBox(width: 12),
                  _PatientStat(
                    value: '${_summary['high_activity_patients'] ?? 0}',
                    label: 'High Activity',
                    color: AppTheme.red,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.darkGreen,
            onRefresh: () => _loadPatients(showLoader: false),
            child: patients.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Text(
                            'No patient records found yet',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                    itemCount: patients.length,
                    itemBuilder: (ctx, i) => _PatientCard(patient: patients[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PatientStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _PatientStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final name = (patient['name'] ?? 'Customer').toString();
    final patientId = (patient['patient_id'] ?? '-').toString();
    final ordersCount = (patient['orders_count'] ?? 0).toString();
    final latestMedicine = (patient['latest_medicine'] ?? 'N/A').toString();
    final lastChannel = (patient['last_channel'] ?? 'N/A').toString();
    final lastOrderId = (patient['last_order_id'] ?? '-').toString();
    final contactNumber = (patient['contact_number'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.darkGreen.withOpacity(0.1),
                child: Text(
                  _initials(name),
                  style: GoogleFonts.inter(
                    color: AppTheme.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      patientId,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.bgGray,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$ordersCount orders',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow('Last medicine', latestMedicine),
          _infoRow('Last order', lastOrderId),
          _infoRow('Channel', lastChannel),
          if (contactNumber.trim().isNotEmpty) _infoRow('Contact', contactNumber),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
