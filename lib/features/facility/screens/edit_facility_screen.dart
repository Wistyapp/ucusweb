import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/app_facility_provider.dart';
import '../../../core/models/facility_model.dart';
import '../../../core/models/address_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/loading_indicator.dart';

class EditFacilityScreen extends StatefulWidget {
  final String facilityId;

  const EditFacilityScreen({super.key, required this.facilityId});

  @override
  State<EditFacilityScreen> createState() => _EditFacilityScreenState();
}

class _EditFacilityScreenState extends State<EditFacilityScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _peakHourRateController;
  late TextEditingController _capacityController;

  // State
  FacilityModel? _facility;
  bool _isLoading = true;
  bool _isSaving = false;
  List<String> _images = [];
  Map<String, bool> _selectedAmenities = {}; // ✅ Corrigé: Map au lieu de List

  // All available amenities
  final List<Map<String, dynamic>> _allAmenities = [
    {'id': 'wifi', 'name': 'Wi-Fi', 'icon': Icons.wifi},
    {'id': 'parking', 'name': 'Parking', 'icon': Icons.local_parking},
    {'id': 'showers', 'name': 'Douches', 'icon': Icons.shower},
    {'id': 'lockers', 'name': 'Casiers', 'icon': Icons.lock},
    {'id': 'air_conditioning', 'name': 'Climatisation', 'icon': Icons.ac_unit},
    {'id': 'heating', 'name': 'Chauffage', 'icon': Icons.thermostat},
    {'id': 'mirrors', 'name': 'Miroirs', 'icon': Icons.crop_square},
    {'id': 'sound_system', 'name': 'Sono', 'icon': Icons.speaker},
    {'id': 'waiting_area', 'name': 'Salle d\'attente', 'icon': Icons.weekend},
    {'id': 'accessibility', 'name': 'Accès PMR', 'icon': Icons.accessible},
    {'id': 'water_fountain', 'name': 'Fontaine à eau', 'icon': Icons.water_drop},
    {'id': 'coffee_machine', 'name': 'Machine à café', 'icon': Icons.coffee},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadFacility();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _postalCodeController = TextEditingController();
    _hourlyRateController = TextEditingController();
    _peakHourRateController = TextEditingController();
    _capacityController = TextEditingController();
  }

  Future<void> _loadFacility() async {
    try {
      final facilityProvider = Provider.of<AppFacilityProvider>(context, listen: false);

      // ✅ Corrigé: Utiliser getFacilityById ou loadFacility + selectedFacility
      final facility = await facilityProvider.getFacilityById(widget.facilityId);

      if (facility != null) {
        setState(() {
          _facility = facility;
          _nameController.text = facility.name;
          _descriptionController.text = facility.description;
          _streetController.text = facility.address.street;
          _cityController.text = facility.address.city;
          _postalCodeController.text = facility.address.postalCode;
          _hourlyRateController.text = facility.hourlyRate.toString();
          _peakHourRateController.text = (facility.peakHourRate ?? facility.hourlyRate).toString();
          _capacityController.text = facility.capacity.toString();
          _images = List.from(facility.images);
          // ✅ Corrigé: amenities est déjà un Map<String, bool>
          _selectedAmenities = Map<String, bool>.from(facility.amenities);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salle non trouvée')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _hourlyRateController.dispose();
    _peakHourRateController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la salle'),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveFacility,
              child: const Text('Enregistrer'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Chargement...');
    }

    if (_facility == null) {
      return const Center(child: Text('Salle non trouvée'));
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Images Section
          _buildSectionTitle('Photos'),
          _buildImagesSection(),
          const SizedBox(height: 24),

          // Basic Info Section
          _buildSectionTitle('Informations générales'),
          CustomTextField(
            controller: _nameController,
            label: 'Nom de la salle',
            hint: 'Ex: Studio Fitness Paris',
            prefixIcon: Icons.business,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le nom est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Décrivez votre salle...',
            prefixIcon: Icons.description,
            maxLines: 5,
            validator: (value) {
              if (value == null || value.length < 50) {
                return 'La description doit faire au moins 50 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Address Section
          _buildSectionTitle('Adresse'),
          CustomTextField(
            controller: _streetController,
            label: 'Adresse',
            hint: 'Numéro et nom de rue',
            prefixIcon: Icons.location_on,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'L\'adresse est requise';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cityController,
                  label: 'Ville',
                  hint: 'Ex: Paris',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La ville est requise';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _postalCodeController,
                  label: 'Code postal',
                  hint: '75000',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.length != 5) {
                      return 'Code postal invalide';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pricing Section
          _buildSectionTitle('Tarification'),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _hourlyRateController,
                  label: 'Tarif horaire (€)',
                  hint: '30',
                  prefixIcon: Icons.euro,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || double.tryParse(value) == null) {
                      return 'Tarif invalide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _peakHourRateController,
                  label: 'Tarif heures de pointe (€)',
                  hint: '45',
                  prefixIcon: Icons.euro,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Capacity Section
          _buildSectionTitle('Capacité'),
          CustomTextField(
            controller: _capacityController,
            label: 'Capacité maximale (personnes)',
            hint: '10',
            prefixIcon: Icons.people,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || int.tryParse(value) == null) {
                return 'Capacité invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Amenities Section
          _buildSectionTitle('Équipements'),
          _buildAmenitiesSection(),
          const SizedBox(height: 32),

          // Save Button
          CustomButton(
            text: 'Enregistrer les modifications',
            onPressed: _saveFacility,
            isLoading: _isSaving,
            icon: Icons.save,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              GestureDetector(
                onTap: _addImage,
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Ajouter', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              // Existing images
              ..._images.asMap().entries.map((entry) {
                final index = entry.key;
                final imageUrl = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_images.length}/10 photos (minimum 3 recommandées)',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allAmenities.map((amenity) {
        final amenityId = amenity['id'] as String;
        // ✅ Corrigé: vérifie si la clé existe et vaut true
        final isSelected = _selectedAmenities[amenityId] == true;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                amenity['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(amenity['name'] as String),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              // ✅ Corrigé: met à jour le Map
              _selectedAmenities[amenityId] = selected;
            });
          },
          selectedColor: AppTheme.lightTheme.primaryColor,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // TODO: Upload l'image vers Firebase Storage et récupérer l'URL
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fonctionnalité d\'upload à implémenter')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveFacility() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final facilityProvider = Provider.of<AppFacilityProvider>(context, listen: false);

      // ✅ Corrigé: Appel avec les paramètres nommés attendus par updateFacility
      final success = await facilityProvider.updateFacility(
        facilityId: widget.facilityId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        amenities: _selectedAmenities, // ✅ Map<String, bool>
        capacity: int.parse(_capacityController.text),
        hourlyRate: double.parse(_hourlyRateController.text),
        peakHourRate: double.tryParse(_peakHourRateController.text),
        address: AddressModel(
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: 'France',
        ),
        images: _images,
      );



      // ✅ Mise à jour de l'adresse séparément si nécessaire
      // Note: Tu peux ajouter une méthode updateFacilityAddress dans le provider
      // ou étendre updateFacility pour accepter l'adresse

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modifications enregistrées'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true indique que des changements ont été faits
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${facilityProvider.error ?? "Erreur inconnue"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
