import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class SearchFiltersSheet extends StatefulWidget {
  final String? selectedCity;
  final double? minRating;
  final double? maxPrice;
  final List<String> selectedAmenities;
  final Function(String? city, double? rating, double? price, List<String> amenities) onApply;

  const SearchFiltersSheet({
    super.key,
    this.selectedCity,
    this.minRating,
    this.maxPrice,
    this.selectedAmenities = const [],
    required this.onApply,
  });

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late TextEditingController _cityController;
  late double? _minRating;
  late double _maxPrice;
  late List<String> _selectedAmenities;

  // Valeurs pour les sliders
  static const double _maxPriceLimit = 200.0;
  static const double _minPriceLimit = 0.0;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.selectedCity ?? '');
    _minRating = widget.minRating;
    _maxPrice = widget.maxPrice ?? _maxPriceLimit;
    _selectedAmenities = List.from(widget.selectedAmenities);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _cityController.clear();
      _minRating = null;
      _maxPrice = _maxPriceLimit;
      _selectedAmenities.clear();
    });
  }

  void _applyFilters() {
    widget.onApply(
      _cityController.text.isNotEmpty ? _cityController.text : null,
      _minRating,
      _maxPrice < _maxPriceLimit ? _maxPrice : null,
      _selectedAmenities,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Réinitialiser'),
                    ),
                    Text(
                      'Filtres',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Filters content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Ville
                    _buildSectionTitle('Localisation'),
                    const SizedBox(height: 12),
                    _buildCityInput(),
                    const SizedBox(height: 24),

                    // Note minimum
                    _buildSectionTitle('Note minimum'),
                    const SizedBox(height: 12),
                    _buildRatingFilter(),
                    const SizedBox(height: 24),

                    // Prix maximum
                    _buildSectionTitle('Prix maximum par heure'),
                    const SizedBox(height: 12),
                    _buildPriceFilter(),
                    const SizedBox(height: 24),

                    // Équipements
                    _buildSectionTitle('Équipements'),
                    const SizedBox(height: 12),
                    _buildAmenitiesFilter(),
                    const SizedBox(height: 24),

                    // Type d'espace (optionnel)
                    _buildSectionTitle('Type d\'espace'),
                    const SizedBox(height: 12),
                    _buildFacilityTypeFilter(),
                    const SizedBox(height: 100), // Space for button
                  ],
                ),
              ),

              // Apply button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text('Appliquer les filtres'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCityInput() {
    return TextField(
      controller: _cityController,
      decoration: InputDecoration(
        hintText: 'Entrez une ville...',
        prefixIcon: const Icon(Icons.location_on_outlined),
        suffixIcon: _cityController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _cityController.clear();
            });
          },
        )
            : null,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _minRating != null ? '${_minRating!.toStringAsFixed(1)}+' : 'Toutes les notes',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_minRating != null)
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _minRating!.floor() ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                    size: 20,
                  );
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRatingChip(null, 'Tous'),
            _buildRatingChip(3.0, '3+'),
            _buildRatingChip(3.5, '3.5+'),
            _buildRatingChip(4.0, '4+'),
            _buildRatingChip(4.5, '4.5+'),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingChip(double? value, String label) {
    final isSelected = _minRating == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _minRating = value;
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _maxPrice >= _maxPriceLimit ? 'Pas de limite' : '${_maxPrice.toInt()}€/h max',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_minPriceLimit.toInt()}€ - ${_maxPriceLimit.toInt()}€',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: _maxPrice,
            min: _minPriceLimit,
            max: _maxPriceLimit,
            divisions: 20,
            onChanged: (value) {
              setState(() {
                _maxPrice = value;
              });
            },
          ),
        ),
        // Prix rapides
        Row(
          children: [
            _buildPriceChip(30, '30€'),
            _buildPriceChip(50, '50€'),
            _buildPriceChip(80, '80€'),
            _buildPriceChip(100, '100€'),
            _buildPriceChip(_maxPriceLimit.toInt(), 'Tous'),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceChip(int value, String label) {
    final isSelected = _maxPrice == value.toDouble();

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _maxPrice = value.toDouble();
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmenitiesFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Amenities.all.map((amenity) {
        final id = amenity['id'] as String;
        final name = amenity['name'] as String;
        final icon = amenity['icon'] as IconData? ?? Icons.check;
        final isSelected = _selectedAmenities.contains(id);

        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(name),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedAmenities.add(id);
              } else {
                _selectedAmenities.remove(id);
              }
            });
          },
          selectedColor: AppColors.primary,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: AppColors.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFacilityTypeFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FacilityTypes.all.map((type) {
        final id = type['id'] as String;
        final name = type['name'] as String;
        // Pour l'instant, on ne gère pas le type de facility dans les filtres
        // mais le widget est prêt
        return FilterChip(
          label: Text(name),
          selected: false,
          onSelected: (selected) {
            // TODO: Implémenter la sélection du type
          },
          backgroundColor: AppColors.surfaceVariant,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }
}
