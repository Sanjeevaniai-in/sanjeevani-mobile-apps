import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<_SearchResult> _allResults = [
    _SearchResult(
      type: _ResultType.pharmacy,
      title: 'MedPlus Pharmacy',
      subtitle: 'Kalyani Nagar, Pune • 0.3 km',
      tag: 'Open Now',
      tagColor: Color(0xFF10B981),
      rating: 4.8,
    ),
    _SearchResult(
      type: _ResultType.pharmacy,
      title: 'Apollo Pharmacy',
      subtitle: 'Baner Road, Pune • 0.7 km',
      tag: 'Open Now',
      tagColor: Color(0xFF10B981),
      rating: 4.6,
    ),
    _SearchResult(
      type: _ResultType.medicine,
      title: 'Paracetamol 500mg',
      subtitle: 'Available at 3 nearby stores',
      tag: 'Medicine',
      tagColor: Color(0xFF0066FF),
      rating: null,
    ),
    _SearchResult(
      type: _ResultType.medicine,
      title: 'Crocin Advance',
      subtitle: 'Available at MedPlus & Apollo',
      tag: 'Medicine',
      tagColor: Color(0xFF0066FF),
      rating: null,
    ),
    _SearchResult(
      type: _ResultType.pharmacy,
      title: 'Jan Arogya Medical Store',
      subtitle: 'Wakad, Pune • 1.1 km',
      tag: 'Closed',
      tagColor: Color(0xFFEF4444),
      rating: 4.4,
    ),
    _SearchResult(
      type: _ResultType.pharmacy,
      title: 'Wellness Medicals',
      subtitle: 'Hinjewadi, Pune • 1.5 km',
      tag: 'Open Now',
      tagColor: Color(0xFF10B981),
      rating: 4.7,
    ),
    _SearchResult(
      type: _ResultType.medicine,
      title: 'Dolo 650',
      subtitle: 'Available at 5 nearby stores',
      tag: 'Medicine',
      tagColor: Color(0xFF0066FF),
      rating: null,
    ),
    _SearchResult(
      type: _ResultType.medicine,
      title: 'Azithromycin 500mg',
      subtitle: 'Prescription required • 2 stores',
      tag: 'Medicine',
      tagColor: Color(0xFF0066FF),
      rating: null,
    ),
  ];

  List<_SearchResult> get _filtered {
    if (_query.isEmpty) return [];
    return _allResults
        .where(
          (r) =>
              r.title.toLowerCase().contains(_query.toLowerCase()) ||
              r.subtitle.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(context),
              Expanded(
                child: _query.isEmpty
                    ? _buildInitialState()
                    : _filtered.isEmpty
                        ? _buildNoResults()
                        : _buildResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 17, color: Color(0xFF1F2937)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 15,
                ),
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search pharmacy, medicine...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF9CA3AF), size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () => setState(() {
                            _query = '';
                            _controller.clear();
                          }),
                          child: const Icon(Icons.close,
                              color: Color(0xFF9CA3AF), size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    final recentSearches = [
      'Paracetamol',
      'Apollo Pharmacy',
      'MedPlus Kalyani Nagar',
    ];
    final trending = [
      '💊 Crocin',
      '🏥 Nearby Pharmacy',
      '💉 Insulin',
      '🌡️ Thermometer',
      '🩹 Bandage',
      '💊 Dolo 650',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Recent Searches'),
          const SizedBox(height: 10),
          ...recentSearches.map(
            (s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history,
                    color: Color(0xFF6B7280), size: 18),
              ),
              title: Text(s,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF1F2937))),
              trailing: const Icon(Icons.north_west,
                  size: 16, color: Color(0xFF9CA3AF)),
              onTap: () => setState(() {
                _query = s;
                _controller.text = s;
              }),
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Trending Now'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: trending.map((t) {
              return GestureDetector(
                onTap: () {
                  final clean = t.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                  setState(() {
                    _query = clean;
                    _controller.text = clean;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(t,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF374151))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Browse by Category'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: _buildCategories(),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  List<Widget> _buildCategories() {
    final cats = [
      ('Pharmacy', Icons.local_pharmacy_outlined, [const Color(0xFF0066FF), const Color(0xFF4338CA)]),
      ('Medicine', Icons.medication_outlined, [const Color(0xFF10B981), const Color(0xFF059669)]),
      ('Emergency', Icons.emergency_outlined, [const Color(0xFFEF4444), const Color(0xFFDC2626)]),
      ('Vitamins', Icons.spa_outlined, [const Color(0xFF8B5CF6), const Color(0xFFEC4899)]),
      ('Lab Tests', Icons.science_outlined, [const Color(0xFFFF8A00), const Color(0xFFFBBF24)]),
      ('Devices', Icons.devices_outlined, [const Color(0xFF0EA5E9), const Color(0xFF0066FF)]),
    ];
    return cats.map((c) {
      return GestureDetector(
        onTap: () => setState(() {
          _query = c.$1;
          _controller.text = c.$1;
        }),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: c.$3),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(c.$2, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(c.$1,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151))),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildResults() {
    final pharmacies = _filtered.where((r) => r.type == _ResultType.pharmacy).toList();
    final medicines = _filtered.where((r) => r.type == _ResultType.medicine).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      children: [
        Text(
          '${_filtered.length} results for "$_query"',
          style: GoogleFonts.inter(
            color: const Color(0xFF9CA3AF),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        if (pharmacies.isNotEmpty) ...[
          _sectionTitle('Pharmacies (${pharmacies.length})'),
          const SizedBox(height: 8),
          ...pharmacies.map((r) => _buildResultCard(r)),
          const SizedBox(height: 16),
        ],
        if (medicines.isNotEmpty) ...[
          _sectionTitle('Medicines (${medicines.length})'),
          const SizedBox(height: 8),
          ...medicines.map((r) => _buildResultCard(r)),
        ],
      ],
    );
  }

  Widget _buildResultCard(_SearchResult r) {
    final isPharmacy = r.type == _ResultType.pharmacy;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPharmacy
                  ? [const Color(0xFF0066FF), const Color(0xFF4338CA)]
                  : [const Color(0xFF10B981), const Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isPharmacy ? Icons.local_pharmacy : Icons.medication,
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                r.title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            if (r.rating != null)
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFBBF24), size: 14),
                  const SizedBox(width: 2),
                  Text(r.rating.toString(),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937))),
                ],
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(r.subtitle,
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF6B7280))),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: r.tagColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(r.tag,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: r.tagColor)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right,
            color: Color(0xFFD1D5DB), size: 20),
        onTap: () {},
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No results for "$_query"',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text('Try a different keyword',
              style: GoogleFonts.inter(color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

enum _ResultType { pharmacy, medicine }

class _SearchResult {
  final _ResultType type;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final double? rating;

  _SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    this.rating,
  });
}
