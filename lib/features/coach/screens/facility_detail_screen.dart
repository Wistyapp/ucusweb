import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/providers/facility_provider.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class FacilityDetailScreen extends StatefulWidget {
  final String facilityId;

  const FacilityDetailScreen({
    super.key,
    required this.facilityId,
  });

  @override
  State<FacilityDetailScreen> createState() => _FacilityDetailScreenState();
}

class _FacilityDetailScreenState extends State<FacilityDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<FacilityProvider>().loadFacility(widget.facilityId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FacilityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final facility = provider.selectedFacility;
        if (facility == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Installation non trouvée')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Image carousel
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageCarousel(facility.images),
                ),
                leading: _buildBackButton(),
                actions: [
                  _buildActionButton(
                    icon: Icons.favorite_border,
                    onPressed: () {
                      // TODO: Add to favorites
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    onPressed: () {
                      // TODO: Share facility
                    },
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  facility.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        facility.address.shortFormatted,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Rating badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  facility.rating.toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      if (facility.isVerified || facility.isFeatured)
                        Wrap(
                          spacing: 8,
                          children: [
                            if (facility.isVerified)
                              _buildTag('Vérifié', AppColors.success),
                            if (facility.isFeatured)
                              _buildTag('Recommandé', AppColors.accent),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Price info
                      _buildPriceSection(facility.hourlyRate),
                      const SizedBox(height: 24),

                      // Description
                      _buildSection(
                        title: 'Description',
                        child: Text(
                          facility.description.isNotEmpty
                              ? facility.description
                              : 'Aucune description disponible.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Amenities
                      _buildSection(
                        title: 'Équipements',
                        child: _buildAmenities(facility.amenityList),
                      ),
                      const SizedBox(height: 24),

                      // Spaces
                      if (provider.selectedFacilitySpaces.isNotEmpty) ...[
                        _buildSection(
                          title: 'Espaces disponibles',
                          child: Column(
                            children: provider.selectedFacilitySpaces
                                .map((space) => _buildSpaceCard(space))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Reviews
                      _buildSection(
                        title: 'Avis (${facility.reviewsCount})',
                        action: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.reviews,
                              arguments: widget.facilityId,
                            );
                          },
                          child: const Text('Voir tout'),
                        ),
                        child: _buildReviewsPreview(),
                      ),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(facility.hourlyRate),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.3),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.3),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: images.length,
          itemBuilder: (context, index, _) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image),
              ),
            );
          },
          options: CarouselOptions(
            viewportFraction: 1,
            height: 300,
            onPageChanged: (index, _) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentImageIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(double hourlyRate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'À partir de',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${hourlyRate.toInt()}€',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    TextSpan(
                      text: ' / heure',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Commission plateforme: ${(AppConstants.platformCommissionRate * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    Widget? action,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildAmenities(List<String> amenities) {
    if (amenities.isEmpty) {
      return Text(
        'Aucun équipement listé',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((id) {
        final amenity = Amenities.all.firstWhere(
          (a) => a['id'] == id,
          orElse: () => {'name': id, 'icon': 'check'},
        );
        return Chip(
          avatar: Icon(
            _getAmenityIcon(amenity['icon'] as String),
            size: 18,
          ),
          label: Text(amenity['name'] as String),
        );
      }).toList(),
    );
  }

  IconData _getAmenityIcon(String name) {
    final icons = {
      'wifi': Icons.wifi,
      'local_parking': Icons.local_parking,
      'shower': Icons.shower,
      'lock': Icons.lock,
      'ac_unit': Icons.ac_unit,
      'whatshot': Icons.whatshot,
      'crop_square': Icons.crop_square,
      'speaker': Icons.speaker,
      'water_drop': Icons.water_drop,
      'accessible': Icons.accessible,
      'checkroom': Icons.checkroom,
      'dry': Icons.dry,
    };
    return icons[name] ?? Icons.check;
  }

  Widget _buildSpaceCard(dynamic space) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.meeting_room,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    '${space.capacity} personnes · ${space.hourlyRate.toInt()}€/h',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.booking,
                  arguments: {
                    'facilityId': widget.facilityId,
                    'spaceId': space.id,
                  },
                );
              },
              child: const Text('Réserver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Text('JD'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jean Dupont',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    RatingBar.builder(
                      initialRating: 5,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 16,
                      ignoreGestures: true,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: AppColors.accent,
                      ),
                      onRatingUpdate: (_) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Excellent espace, très bien équipé et propre. Le propriétaire est très réactif.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double hourlyRate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hourlyRate.toInt()}€ / heure',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Commission incluse',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final spaces =
                      context.read<FacilityProvider>().selectedFacilitySpaces;
                  if (spaces.isNotEmpty) {
                    Navigator.pushNamed(
                      context,
                      AppRouter.booking,
                      arguments: {
                        'facilityId': widget.facilityId,
                        'spaceId': spaces.first.id,
                      },
                    );
                  }
                },
                child: const Text('Réserver maintenant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
