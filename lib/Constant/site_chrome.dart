import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'brand.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// Global page chrome shared across every marketing screen so the header,
/// stats band and footer are identical everywhere.
/// ═══════════════════════════════════════════════════════════════════════════

// ─── STATS BAND (the "Trusted by Industry Leaders" card) ────────────────────
class SiteStatsBand extends StatelessWidget {
  const SiteStatsBand({super.key});

  static const _metrics = [
    (15.0, 'K+', 'Successfully Hired', Icons.people_rounded, Brand.tealBright),
    (98.0, '%', 'Success Rate', Icons.trending_up_rounded, Brand.amber),
    (24.0, 'h', 'Avg. Response', Icons.schedule_rounded, Brand.coral),
    (500.0, '+', 'Active Recruiters', Icons.business_rounded,
        Color(0xFF7DBBE8)),
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;
    final hPad = isMobile ? 18.0 : (w < 1080 ? 40.0 : 80.0);

    return Container(
      color: Brand.bgSoft,
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 48 : 96, hPad, isMobile ? 48 : 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 48, vertical: isMobile ? 34 : 56),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Brand.heroDeep, Brand.heroMid, Brand.navy],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Brand.navy.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 20)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Brand.teal.withValues(alpha: 0.4)),
                  ),
                  child: Text('⚡ PROVEN SUCCESS',
                      style: Brand.font(11, FontWeight.w700, Brand.tealBright,
                          spacing: 1.5)),
                ),
                SizedBox(height: isMobile ? 14 : 18),
                Text('Trusted by Industry Leaders',
                    textAlign: TextAlign.center,
                    style: Brand.font(
                        isMobile ? 24 : 38, FontWeight.w800, Colors.white)),
                const SizedBox(height: 8),
                Text('Real numbers, real impact — see how we transform hiring',
                    textAlign: TextAlign.center,
                    style: Brand.font(isMobile ? 13 : 16, FontWeight.w500,
                        Colors.white.withValues(alpha: 0.72))),
                SizedBox(height: isMobile ? 26 : 44),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: isMobile ? 12 : 24,
                  runSpacing: 16,
                  children: [
                    for (final m in _metrics)
                      Container(
                        width: isMobile ? 152 : 210,
                        padding: EdgeInsets.all(isMobile ? 16 : 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: m.$5.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(m.$4,
                                  color: m.$5, size: isMobile ? 18 : 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BrandCountUp(
                                    end: m.$1,
                                    suffix: m.$2,
                                    style: Brand.font(isMobile ? 20 : 26,
                                        FontWeight.w800, Colors.white),
                                    accent: m.$5,
                                  ),
                                  Text(m.$3,
                                      style: Brand.font(isMobile ? 10.5 : 12,
                                          FontWeight.w600,
                                          Colors.white.withValues(alpha: 0.68))),
                                ],
                              ),
                            ),
                          ],
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
  }
}

// ─── FOOTER ─────────────────────────────────────────────────────────────────
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 700;
    final hPad = isMobile ? 18.0 : (w < 1080 ? 40.0 : 80.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Brand.heroMid, Brand.heroDeep],
        ),
      ),
      padding: EdgeInsets.fromLTRB(hPad, isMobile ? 36 : 60, hPad, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: Image.asset('images/logo_new.jpeg',
                                    fit: BoxFit.cover,
                                    cacheWidth: 132,
                                    cacheHeight: 132),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('MAHA',
                                    style: Brand.font(
                                        20, FontWeight.w800, Colors.white,
                                        spacing: 3)),
                                Text('HR SERVICES',
                                    style: Brand.font(10, FontWeight.w700,
                                        Brand.tealBright,
                                        spacing: 3.5)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Text(
                              'Revolutionizing recruitment through an intelligent 4-stage hiring ecosystem. Connecting talent with opportunity seamlessly.',
                              style: Brand.font(13.5, FontWeight.w500,
                                  Colors.white.withValues(alpha: 0.6),
                                  height: 1.8)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 0 : 40, height: isMobile ? 28 : 0),
                  _links(context, 'Product', const [
                    ('Find Jobs', '/login'),
                    ('For Recruiters', '/register?role=recruiter'),
                    ('Pricing', '/pricing'),
                  ]),
                  SizedBox(width: isMobile ? 0 : 40, height: isMobile ? 20 : 0),
                  _links(context, 'Account', const [
                    ('Login', '/login'),
                    ('Get Started', '/register'),
                    ('Admin', '/admin'),
                  ]),
                ],
              ),
              SizedBox(height: isMobile ? 24 : 40),
              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
              SizedBox(height: isMobile ? 14 : 20),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('© 2026 Maha HR Services. All rights reserved.',
                      style: Brand.font(isMobile ? 11 : 13, FontWeight.w500,
                          Colors.white.withValues(alpha: 0.4))),
                  SizedBox(height: isMobile ? 10 : 0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Brand.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Brand.teal.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology_rounded,
                            color: Brand.tealBright, size: 15),
                        const SizedBox(width: 5),
                        Text('Developed By mahaservices.org',
                            style: Brand.font(isMobile ? 10 : 12,
                                FontWeight.w600, Brand.tealBright)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _links(
      BuildContext context, String heading, List<(String, String)> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading.toUpperCase(),
            style: Brand.font(
                11, FontWeight.w700, Colors.white.withValues(alpha: 0.4),
                spacing: 1)),
        const SizedBox(height: 12),
        for (final l in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go(l.$2),
                child: Text(l.$1,
                    style: Brand.font(13.5, FontWeight.w500,
                        Colors.white.withValues(alpha: 0.65))),
              ),
            ),
          ),
      ],
    );
  }
}
