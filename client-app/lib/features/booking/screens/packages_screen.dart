import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme/orbit_theme.dart';
import '../../../shared/widgets/orbit_button.dart';
import '../../../shared/widgets/orbit_card.dart';
import '../../../shared/widgets/orbit_loading.dart';
import '../../../shared/widgets/orbit_empty_state.dart';
import '../../../analytics/analytics_service.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  List<Map<String, dynamic>> _packages = [];
  String? _selectedPackageId = 'pkg_standard';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    analytics.trackScreenView('packages_screen');
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final res = await apiClient.get('/packages');
      final pkgs = List<Map<String, dynamic>>.from(res.data ?? []);
      if (mounted) {
        setState(() {
          _packages = pkgs;
          _selectedPackageId = pkgs.isNotEmpty ? pkgs.first['id'] : null;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback default packages if offline or empty
      if (mounted) {
        setState(() {
          _packages = [
            {
              'id': 'pkg_quick',
              'name': 'Quick Reel',
              'tier': 'QUICK',
              'priceDisplay': 999,
              'focus': '1 High-Impact 9:16 Reel',
              'deliveryTime': '60 min delivery',
              'features': ['30-second reel', 'Color grading', 'Trending audio sync', 'Fast delivery'],
              'popular': false,
            },
            {
              'id': 'pkg_standard',
              'name': 'Creator Standard',
              'tier': 'STANDARD',
              'priceDisplay': 1999,
              'focus': '3 Polished Reels + B-Roll',
              'deliveryTime': '120 min delivery',
              'features': ['3 Short-form Reels', 'Pro Color Grading', 'Motion Captions', '4K Export'],
              'popular': true,
            },
            {
              'id': 'pkg_premium',
              'name': 'Brand Premium',
              'tier': 'PREMIUM',
              'priceDisplay': 4999,
              'focus': '6 Cinematic Reels + Brand Kit',
              'deliveryTime': 'Same Day delivery',
              'features': ['6 Master Reels', 'Sound Design & VO', 'Custom Brand Kit', 'Raw Footage Access'],
              'popular': false,
            },
          ];
          _selectedPackageId = 'pkg_standard';
          _isLoading = false;
        });
      }
    }
  }

  void _onContinue() {
    final pkgId = _selectedPackageId ?? 'pkg_standard';
    final selectedPkg = _packages.cast<Map<String, dynamic>?>().firstWhere(
          (p) => p != null && p['id'] == pkgId,
          orElse: () => {'id': pkgId, 'tier': 'STANDARD'},
        );
    OrbitMotion.lightTap();
    analytics.trackBookingStarted(packageId: pkgId, tier: selectedPkg?['tier']?.toString());
    context.push('/location-picker', extra: pkgId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('Select Package', style: OrbitTypography.titleLarge),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Step Indicator Header ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space20, vertical: OrbitSpacing.space8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        gradient: OrbitColors.primaryGradient,
                        borderRadius: OrbitRadius.roundedFull,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        color: OrbitColors.surfaceHighlight,
                        borderRadius: OrbitRadius.roundedFull,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: const BoxDecoration(
                        color: OrbitColors.surfaceHighlight,
                        borderRadius: OrbitRadius.roundedFull,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: OrbitSpacing.space12),

            // ── Packages List ─────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(OrbitSpacing.space20),
                      child: Column(
                        children: [
                          OrbitLoadingCard(height: 140),
                          OrbitLoadingCard(height: 140),
                          OrbitLoadingCard(height: 140),
                        ],
                      ),
                    )
                  : _packages.isEmpty
                      ? OrbitEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No packages available',
                          description: 'Please check your connection and try again.',
                          ctaLabel: 'Retry',
                          onCtaPressed: _loadPackages,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: OrbitSpacing.space20, vertical: OrbitSpacing.space12),
                          itemCount: _packages.length,
                          separatorBuilder: (_, __) => const SizedBox(height: OrbitSpacing.space16),
                          itemBuilder: (context, index) {
                            final pkg = _packages[index];
                            final isSelected = pkg['id'] == _selectedPackageId;
                            final isPopular = pkg['popular'] == true;

                            return OrbitCard(
                              onTap: () {
                                OrbitMotion.selectionChanged();
                                setState(() => _selectedPackageId = pkg['id']);
                              },
                              backgroundColor: isSelected ? OrbitColors.surfaceElevated : OrbitColors.surface,
                              border: Border.all(
                                color: isSelected ? OrbitColors.secondary : OrbitColors.borderSubtle,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                            color: isSelected ? OrbitColors.secondary : OrbitColors.textDisabled,
                                            size: 22,
                                          ),
                                          const SizedBox(width: OrbitSpacing.space12),
                                          Text(pkg['name'] ?? '', style: OrbitTypography.titleMedium),
                                        ],
                                      ),
                                      if (isPopular)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: const BoxDecoration(
                                            gradient: OrbitColors.primaryGradient,
                                            borderRadius: OrbitRadius.roundedFull,
                                          ),
                                          child: Text(
                                            'RECOMMENDED',
                                            style: OrbitTypography.labelSmall.copyWith(fontSize: 9, color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: OrbitSpacing.space12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '₹${pkg['priceDisplay'] ?? 999}',
                                        style: OrbitTypography.displayLarge.copyWith(fontSize: 28),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('• ${pkg['deliveryTime'] ?? 'Same Day'}', style: OrbitTypography.bodySmall),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(pkg['focus'] ?? '', style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textPrimary)),
                                  if (pkg['features'] is List) ...[
                                    const Divider(color: OrbitColors.borderSubtle, height: OrbitSpacing.space20),
                                    ...((pkg['features'] as List).take(3).map((f) => Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check, size: 14, color: OrbitColors.success),
                                              const SizedBox(width: 6),
                                              Expanded(child: Text(f.toString(), style: OrbitTypography.bodySmall)),
                                            ],
                                          ),
                                        ))),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // ── Single Dominant CTA (Thumb Zone) ──────────────────────
            Padding(
              padding: const EdgeInsets.all(OrbitSpacing.space20),
              child: OrbitPrimaryButton(
                label: 'CONTINUE TO LOCATION',
                icon: Icons.arrow_forward_rounded,
                onPressed: _onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
