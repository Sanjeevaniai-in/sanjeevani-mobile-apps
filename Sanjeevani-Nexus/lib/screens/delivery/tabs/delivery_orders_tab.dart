import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class DeliveryOrdersTab extends StatelessWidget {
  const DeliveryOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top stats container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  value: '3',
                  label: 'Pending Tasks',
                  color: AppTheme.darkGreen,
                  icon: Icons.pending_actions_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.cardBorder),
              Expanded(
                child: _buildHeaderStat(
                  value: '6',
                  label: 'Completed',
                  color: AppTheme.success,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route_rounded,
                        color: AppTheme.info, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Optimized Route',
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Delivery Card
              _DeliveryTaskCard(
                orderId: '#ORD-2024-001',
                patientName: 'Sarah Jennings',
                address: '124 Maple Street, Springfield, IL 62704',
                distance: '1.2 km',
                eta: '7 mins',
                isActive: true,
                items: 'Amoxicillin 250mg, Ibuprofen',
              ),

              const SizedBox(height: 32),
              Text(
                'Next Deliveries',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              _DeliveryTaskCard(
                orderId: '#ORD-2024-002',
                patientName: 'Michael Chang',
                address: '88 Oak Avenue, Apt 4B, Springfield, IL 62705',
                distance: '3.4 km',
                eta: '14 mins',
                isActive: false,
                items: 'Lisinopril 10mg',
              ),

              _DeliveryTaskCard(
                orderId: '#ORD-2024-003',
                patientName: 'Elena Suarez',
                address: '500 Pine Lane, Springfield, IL 62706',
                distance: '4.8 km',
                eta: '22 mins',
                isActive: false,
                items: 'Metformin 500mg',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeliveryTaskCard extends StatelessWidget {
  final String orderId;
  final String patientName;
  final String address;
  final String distance;
  final String eta;
  final bool isActive;
  final String items;

  const _DeliveryTaskCard({
    required this.orderId,
    required this.patientName,
    required this.address,
    required this.distance,
    required this.eta,
    required this.isActive,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isActive ? AppTheme.info.withOpacity(0.5) : AppTheme.cardBorder,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.info.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
            : AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppTheme.info.withOpacity(0.1),
                child: Center(
                  child: Text(
                    'CURRENT ACTIVE TASK',
                    style: GoogleFonts.inter(
                      color: AppTheme.info,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.info.withOpacity(0.1)
                              : AppTheme.bgGray,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color:
                              isActive ? AppTheme.info : AppTheme.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              orderId,
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            eta,
                            style: GoogleFonts.inter(
                              color: AppTheme.info,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            distance,
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgGray,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            address,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isActive ? AppTheme.info : AppTheme.darkGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isActive ? 'Start Navigation' : 'View Details',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.call_rounded,
                                color: AppTheme.success),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
