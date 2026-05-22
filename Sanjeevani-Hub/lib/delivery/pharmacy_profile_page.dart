import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/map_service.dart';

class PharmacyProfilePage extends StatelessWidget {
  final Pharmacy shop;
  final VoidCallback onConnect;

  const PharmacyProfilePage({
    super.key,
    required this.shop,
    required this.onConnect,
  });

  static const Color _dark = Color(0xFF1A1A1B);
  static const Color _textSub = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.8),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: _dark,
                    size: 16,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                'https://img.freepik.com/free-photo/pills-spilling-out-bottle-white-background_23-2148285748.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _dark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shop.address ?? 'Near your location',
                              style: GoogleFonts.inter(color: _textSub),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          shop.isOpen ? 'Open' : 'Closed',
                          style: GoogleFonts.inter(
                            color: shop.isOpen ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailStat(Icons.star_rounded, '4.8', 'Rating'),
                      _buildDetailStat(
                        Icons.directions_rounded,
                        shop.distance,
                        'Distance',
                      ),
                      _buildDetailStat(
                        Icons.verified_rounded,
                        'Verified',
                        'Tier 1',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Live Feedback',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildReviewItem(
                    'Sanjay K.',
                    'Fast delivery and very professional service.',
                    '5 mins ago',
                  ),
                  _buildReviewItem(
                    'Priya S.',
                    'Authentic medicines, well packaged.',
                    '20 mins ago',
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      onConnect();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: _dark.withOpacity(0.3),
                    ),
                    child: Text(
                      'Connect & Order',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(IconData icon, String val, String label) {
    return Column(
      children: [
        Icon(icon, color: _dark, size: 24),
        const SizedBox(height: 8),
        Text(
          val,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(label, style: GoogleFonts.inter(color: _textSub, fontSize: 12)),
      ],
    );
  }

  Widget _buildReviewItem(String name, String text, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.inter(color: _textSub, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: GoogleFonts.inter(color: _dark, fontSize: 14)),
        ],
      ),
    );
  }
}
