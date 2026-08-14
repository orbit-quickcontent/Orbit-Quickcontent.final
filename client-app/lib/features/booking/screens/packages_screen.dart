import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/api_client.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  List<Map<String, dynamic>> _packages = [];
  bool _isLoading = true;
  String? _selectedPackageId;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final res = await apiClient.get('/packages');
      setState(() {
        _packages = List<Map<String, dynamic>>.from(res.data);
        if (_packages.isNotEmpty) {
          _selectedPackageId = _packages.firstWhere((p) => p['popular'] == true, orElse: () => _packages[0])['id'];
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrbitClientTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text('Choose Package', style: OrbitClientTheme.textTheme.headlineMedium),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: OrbitClientTheme.primaryFixed))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _packages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => _PackageCard(
                      package: _packages[i],
                      isSelected: _packages[i]['id'] == _selectedPackageId,
                      onSelect: () => setState(() => _selectedPackageId = _packages[i]['id']),
                    ).animate(delay: (i * 100).ms).fadeIn().slideY(begin: 0.15),
                  ),
                ),
                // Bottom CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: OrbitGradientButton(
                    label: 'Select Location',
                    onPressed: _selectedPackageId == null ? null : () {
                      context.push('/location', extra: _selectedPackageId);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PackageCard({required this.package, required this.isSelected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isPopular = package['popular'] == true;
    final features = (package['features'] as List?)?.cast<String>() ?? [];
    final priceDisplay = package['priceDisplay'] ?? 0;

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: OrbitClientTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? OrbitClientTheme.primaryFixed : OrbitClientTheme.outlineVariant,
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: OrbitClientTheme.primaryFixed.withOpacity(0.15), blurRadius: 20)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPopular)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: OrbitClientTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('MOST POPULAR', style: OrbitClientTheme.textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 9, letterSpacing: 1.5)),
                        ),
                      Text(package['name'] ?? '', style: OrbitClientTheme.textTheme.headlineMedium),
                      const SizedBox(height: 2),
                      Text(package['focus'] ?? '', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹$priceDisplay',
                      style: OrbitClientTheme.textTheme.headlineLarge?.copyWith(
                        foreground: Paint()..shader = OrbitClientTheme.primaryGradient.createShader(const Rect.fromLTWH(0, 0, 120, 40)),
                      ),
                    ),
                    Text('per shoot', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.outline)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: OrbitClientTheme.outlineVariant),
            const SizedBox(height: 12),

            // Features
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected ? OrbitClientTheme.primaryGradient : null,
                      color: isSelected ? null : OrbitClientTheme.surfaceHigh,
                    ),
                    child: Icon(Icons.check, size: 11, color: isSelected ? Colors.white : OrbitClientTheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f, style: OrbitClientTheme.textTheme.bodySmall)),
                ],
              ),
            )),

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 13, color: OrbitClientTheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Delivery: ${package['deliveryTime']}', style: OrbitClientTheme.textTheme.bodySmall?.copyWith(color: OrbitClientTheme.onSurfaceVariant)),
              ],
            ),

            // Selected indicator
            if (isSelected) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: OrbitClientTheme.primaryFixed),
                  const SizedBox(width: 6),
                  Text('Selected', style: OrbitClientTheme.textTheme.labelMedium?.copyWith(color: OrbitClientTheme.primaryFixed)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
