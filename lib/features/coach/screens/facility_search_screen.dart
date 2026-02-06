import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/facility_provider.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/facility_card.dart';
import '../widgets/search_filters_sheet.dart';

class FacilitySearchScreen extends StatefulWidget {
  const FacilitySearchScreen({super.key});

  @override
  State<FacilitySearchScreen> createState() => _FacilitySearchScreenState();
}

class _FacilitySearchScreenState extends State<FacilitySearchScreen> {
  final _searchController = TextEditingController();
  String? _selectedCity;
  double? _minRating;
  double? _maxPrice;
  List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    await context.read<FacilityProvider>().searchFacilities(
          city: _selectedCity,
          minRating: _minRating,
          maxPrice: _maxPrice,
          amenities: _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
        );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFiltersSheet(
        selectedCity: _selectedCity,
        minRating: _minRating,
        maxPrice: _maxPrice,
        selectedAmenities: _selectedAmenities,
        onApply: (city, rating, price, amenities) {
          setState(() {
            _selectedCity = city;
            _minRating = rating;
            _maxPrice = price;
            _selectedAmenities = amenities;
          });
          _performSearch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher'),
        actions: [
          IconButton(
            onPressed: () {
              // Toggle map view
            },
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Ville, type d\'espace...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _selectedCity = null;
                                });
                                _performSearch();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        _selectedCity = value.isNotEmpty ? value : null;
                      });
                      _performSearch();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterButton(),
              ],
            ),
          ),

          // Active filters
          if (_hasActiveFilters()) _buildActiveFilters(),

          // Results
          Expanded(
            child: Consumer<FacilityProvider>(
              builder: (context, provider, _) {
                if (provider.isSearching) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return _buildError(provider.error!);
                }

                if (provider.searchResults.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildResults(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasFilters = _hasActiveFilters();
    
    return GestureDetector(
      onTap: _showFilters,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFilters ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Badge(
          isLabelVisible: hasFilters,
          label: Text(_activeFilterCount().toString()),
          child: Icon(
            Icons.tune,
            color: hasFilters ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (_selectedCity != null)
            _buildFilterChip('Ville: $_selectedCity', () {
              setState(() => _selectedCity = null);
              _performSearch();
            }),
          if (_minRating != null)
            _buildFilterChip('Note: ${_minRating!.toStringAsFixed(1)}+', () {
              setState(() => _minRating = null);
              _performSearch();
            }),
          if (_maxPrice != null)
            _buildFilterChip('Max: ${_maxPrice!.toInt()}€/h', () {
              setState(() => _maxPrice = null);
              _performSearch();
            }),
          ..._selectedAmenities.map((amenity) => _buildFilterChip(
                _getAmenityName(amenity),
                () {
                  setState(() => _selectedAmenities.remove(amenity));
                  _performSearch();
                },
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onRemove,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
        deleteIconColor: AppColors.primary,
      ),
    );
  }

  Widget _buildResults(FacilityProvider provider) {
    return RefreshIndicator(
      onRefresh: _performSearch,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.searchResults.length,
        itemBuilder: (context, index) {
          final facility = provider.searchResults[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FacilityCard(
              facility: facility,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRouter.facilityDetail,
                  arguments: facility.id,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedCity = null;
                  _minRating = null;
                  _maxPrice = null;
                  _selectedAmenities = [];
                  _searchController.clear();
                });
                _performSearch();
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCity != null ||
        _minRating != null ||
        _maxPrice != null ||
        _selectedAmenities.isNotEmpty;
  }

  int _activeFilterCount() {
    int count = 0;
    if (_selectedCity != null) count++;
    if (_minRating != null) count++;
    if (_maxPrice != null) count++;
    count += _selectedAmenities.length;
    return count;
  }

  String _getAmenityName(String id) {
    final amenity = Amenities.all.firstWhere(
      (a) => a['id'] == id,
      orElse: () => {'name': id},
    );
    return amenity['name'] as String;
  }
}
