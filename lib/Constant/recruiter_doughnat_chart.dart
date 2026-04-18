import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ApplicationStatusChart extends StatefulWidget {
  final Map<String, dynamic> data;

  const ApplicationStatusChart({super.key, required this.data});

  @override
  State<ApplicationStatusChart> createState() => _ApplicationStatusChartState();
}

class _ApplicationStatusChartState extends State<ApplicationStatusChart>
    with SingleTickerProviderStateMixin {
  int _touchedIndex = -1;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Color> _pendingGradient = [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];
  final List<Color> _acceptedGradient = [const Color(0xFF10B981), const Color(0xFF059669)];
  final List<Color> _shortlistedGradient = [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
  final List<Color> _rejectedGradient = [const Color(0xFFEF4444), const Color(0xFFDC2626)];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = (widget.data['pending'] ?? 0) as int;
    final accepted = (widget.data['accepted'] ?? 0) as int;
    final shortlisted = (widget.data['shortlisted'] ?? 0) as int;
    final rejected = (widget.data['rejected'] ?? 0) as int;

    final total = pending + accepted + rejected + shortlisted;
    final values = [pending, accepted, shortlisted, rejected];
    final labels = ['Pending', 'Accepted', 'Shortlisted', 'Rejected'];
    final icons = [Icons.schedule_rounded, Icons.check_circle_rounded, Icons.star_rounded, Icons.cancel_rounded];
    final gradients = [_pendingGradient, _acceptedGradient, _shortlistedGradient, _rejectedGradient];

    if (total == 0) {
      return _buildEmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Compact Header
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colors.deepPurple, size: 28),
              const SizedBox(width: 10),
              Text(
                "Applications",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Two Column Layout: Donut + Legend
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Donut Chart
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2,
                              centerSpaceRadius: 50,
                              startDegreeOffset: 270,
                              sections: List.generate(4, (i) {
                                final isTouched = i == _touchedIndex;
                                final double radius = isTouched ? 32.0 : 28.0;
                                final double opacity = (_touchedIndex == -1 || isTouched) ? 1.0 : 0.35;
                                final value = values[i].toDouble() * _animation.value;

                                return PieChartSectionData(
                                  gradient: LinearGradient(
                                    colors: gradients[i].map((c) => c.withValues(alpha: opacity)).toList(),
                                  ),
                                  value: value > 0 ? value : 0.001,
                                  title: values[i] > 0 ? '${(values[i] / total * 100).toStringAsFixed(0)}%' : '',
                                  radius: radius,
                                  titleStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                );
                              }),
                            ),
                            swapAnimationDuration: const Duration(milliseconds: 350),
                            swapAnimationCurve: Curves.easeOutCubic,
                          );
                        },
                      ),
                      // Center Content
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey<int>(_touchedIndex),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: _touchedIndex == -1
                                    ? [Colors.blue[700]!, Colors.blue[900]!]
                                    : gradients[_touchedIndex],
                              ).createShader(bounds),
                              child: Text(
                                _touchedIndex == -1 ? '$total' : '${values[_touchedIndex]}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              _touchedIndex == -1 ? 'Total' : labels[_touchedIndex],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: Colors.blueGrey[500],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Right Column: Compact Legend
              Expanded(
                flex: 5,
                child: Column(
                  children: List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildCompactLegendItem(
                        gradient: gradients[index],
                        label: labels[index],
                        value: values[index],
                        total: total,
                        icon: icons[index],
                        isFocused: _touchedIndex == index || _touchedIndex == -1,
                        index: index,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLegendItem({
    required List<Color> gradient,
    required String label,
    required int value,
    required int total,
    required IconData icon,
    required bool isFocused,
    required int index,
  }) {
    final percentage = total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - animValue), 0),
          child: Opacity(
            opacity: animValue * (isFocused ? 1.0 : 0.4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _touchedIndex = _touchedIndex == index ? -1 : index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradient[0].withValues(alpha: 0.08),
                      gradient[1].withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: gradient[0].withValues(alpha: isFocused ? 0.25 : 0.12),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(icon, color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$value',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: gradient[1],
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pie_chart_outline_rounded, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(height: 14),
          Text(
            "No Applications",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Start applying to track progress",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}