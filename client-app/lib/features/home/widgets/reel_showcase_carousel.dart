import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/orbit_theme.dart';

class SampleReelItem {
  final String id;
  final String title;
  final String category;
  final String duration;
  final String views;
  final double rating;
  final String creatorName;
  final List<Color> gradient;
  final IconData categoryIcon;

  const SampleReelItem({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.views,
    required this.rating,
    required this.creatorName,
    required this.gradient,
    required this.categoryIcon,
  });
}

const List<SampleReelItem> defaultSampleReels = [
  SampleReelItem(
    id: 'reel_1',
    title: 'Summer Fashion & Streetwear',
    category: 'Fashion & Style',
    duration: '0:30',
    views: '18.4K',
    rating: 4.9,
    creatorName: 'Arjun K. (Pro Creator)',
    gradient: [Color(0xFF2E0854), Color(0xFF1E1035), Color(0xFF120E1E)],
    categoryIcon: Icons.checkroom_rounded,
  ),
  SampleReelItem(
    id: 'reel_2',
    title: 'Artisan Cafe & Gourmet Brew',
    category: 'Food & Dining',
    duration: '0:45',
    views: '24.1K',
    rating: 5.0,
    creatorName: 'Neha S. (Food Cinematographer)',
    gradient: [Color(0xFF4A1E00), Color(0xFF2B1405), Color(0xFF140D07)],
    categoryIcon: Icons.restaurant_rounded,
  ),
  SampleReelItem(
    id: 'reel_3',
    title: 'High-Energy HIIT & Gym Promo',
    category: 'Fitness & Sports',
    duration: '0:35',
    views: '31.2K',
    rating: 4.9,
    creatorName: 'Vikram R. (Action Filmmaker)',
    gradient: [Color(0xFF0F382E), Color(0xFF0B211C), Color(0xFF071411)],
    categoryIcon: Icons.fitness_center_rounded,
  ),
  SampleReelItem(
    id: 'reel_4',
    title: 'Luxury Property & Architecture',
    category: 'Real Estate',
    duration: '0:60',
    views: '15.8K',
    rating: 4.8,
    creatorName: 'Rohan D. (Drone & Arch)',
    gradient: [Color(0xFF1C2B47), Color(0xFF10192A), Color(0xFF0A0F1A)],
    categoryIcon: Icons.apartment_rounded,
  ),
  SampleReelItem(
    id: 'reel_5',
    title: 'Minimalist Tech Unboxing 4K',
    category: 'Tech & Products',
    duration: '0:40',
    views: '42.0K',
    rating: 5.0,
    creatorName: 'Priya M. (Product Specialist)',
    gradient: [Color(0xFF38153A), Color(0xFF210E23), Color(0xFF0E070F)],
    categoryIcon: Icons.devices_rounded,
  ),
];

class OrbitReelShowcaseCarousel extends StatefulWidget {
  final List<SampleReelItem> reels;
  final VoidCallback? onBookNow;

  const OrbitReelShowcaseCarousel({
    super.key,
    this.reels = defaultSampleReels,
    this.onBookNow,
  });

  @override
  State<OrbitReelShowcaseCarousel> createState() => _OrbitReelShowcaseCarouselState();
}

class _OrbitReelShowcaseCarouselState extends State<OrbitReelShowcaseCarousel> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_isUserInteracting && _scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;
        final nextScroll = currentScroll + 1.2;

        if (nextScroll >= maxScroll) {
          _scrollController.jumpTo(0);
        } else {
          _scrollController.jumpTo(nextScroll);
        }
      }
    });
  }

  void _pauseAutoScroll() {
    setState(() => _isUserInteracting = true);
  }

  void _resumeAutoScrollAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isUserInteracting = false);
    });
  }

  void _openReelModal(BuildContext context, SampleReelItem reel) {
    _pauseAutoScroll();
    OrbitMotion.lightTap();

    showModalBottomSheet(
      context: context,
      backgroundColor: OrbitColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: OrbitColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Video Mockup Container
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: reel.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: OrbitColors.borderMedium),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, size: 36, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(reel.views, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(reel.categoryIcon, size: 14, color: OrbitColors.secondary),
                          const SizedBox(width: 4),
                          Text(reel.category, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(reel.title, style: OrbitTypography.headingMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${reel.rating} • Shot by ${reel.creatorName}',
                  style: OrbitTypography.bodySmall.copyWith(color: OrbitColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onBookNow?.call();
                },
                icon: const Icon(Icons.bolt_rounded, color: Colors.black),
                label: const Text(
                  'BOOK A SHOOT IN THIS STYLE',
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: OrbitColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(_resumeAutoScrollAfterDelay);
  }

  @override
  Widget build(BuildContext context) {
    final displayList = [...widget.reels, ...widget.reels, ...widget.reels, ...widget.reels];

    return Listener(
      onPointerDown: (_) => _pauseAutoScroll(),
      onPointerUp: (_) => _resumeAutoScrollAfterDelay(),
      child: SizedBox(
        height: 225,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final reel = displayList[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _openReelModal(context, reel),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: reel.gradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(
                      color: OrbitColors.borderMedium,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Top Badges
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reel.duration,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${reel.rating}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center Glowing Play Button
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.45),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),

                      // Bottom Info
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              reel.category.toUpperCase(),
                              style: TextStyle(
                                color: OrbitColors.secondary.withValues(alpha: 0.9),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reel.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
