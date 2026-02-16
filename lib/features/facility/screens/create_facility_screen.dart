import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/models/address_model.dart';
import '../../../core/providers/app_auth_provider.dart';
import '../../../core/providers/app_facility_provider.dart';
import '../../../core/models/facility_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class CreateFacilityScreen extends StatefulWidget {
  const CreateFacilityScreen({super.key});

  @override
  State<CreateFacilityScreen> createState() => _CreateFacilityScreenState();
}

class _CreateFacilityScreenState extends State<CreateFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _peakHourRateController = TextEditingController();
  final _minBookingDurationController = TextEditingController(text: '1');

  // Selected values
  final List<XFile> _selectedImages = [];
  final Map<String, bool> _selectedAmenities = {};
  final Map<int, TimeRange> _operatingHours = {};
  final List<int> _peakHourDays = [];
  TimeOfDay _peakStartTime = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _peakEndTime = const TimeOfDay(hour: 21, minute: 0);

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize amenities
    for (final amenity in AppConstants.availableAmenities) {
      _selectedAmenities[amenity] = false;
    }
    // Initialize operating hours (default: 7:00-22:00)
    for (int i = 0; i < 7; i++) {
      _operatingHours[i] = TimeRange(
        openTime: const TimeOfDay(hour: 7, minute: 0),
        closeTime: const TimeOfDay(hour: 22, minute: 0),
        isOpen: i != 0, // Closed on Sunday by default
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _capacityController.dispose();
    _hourlyRateController.dispose();
    _peakHourRateController.dispose();
    _minBookingDurationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.take(10 - _selectedImages.length));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      /*
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une photo')),
      );
      return;

       */
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AppAuthProvider>();
      final facilityProvider = context.read<AppFacilityProvider>();

      // Create facility data
      final facilityData = {
        'ownerId': authProvider.user!.uid,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': {
          'street': _streetController.text.trim(),
          'city': _cityController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
          'country': 'France',
        },
        'capacity': int.parse(_capacityController.text),
        'hourlyRate': double.parse(_hourlyRateController.text),
        'peakHourRate': _peakHourRateController.text.isNotEmpty
            ? double.parse(_peakHourRateController.text)
            : double.parse(_hourlyRateController.text) * 1.5,
        'amenities': _selectedAmenities,
        'operatingHours': _operatingHours.map((day, range) => MapEntry(
          day.toString(),
          {
            'isOpen': range.isOpen,
            'openTime': '${range.openTime.hour.toString().padLeft(2, '0')}:${range.openTime.minute.toString().padLeft(2, '0')}',
            'closeTime': '${range.closeTime.hour.toString().padLeft(2, '0')}:${range.closeTime.minute.toString().padLeft(2, '0')}',
          },
        )),
        'peakHours': {
          'days': _peakHourDays,
          'startTime': '${_peakStartTime.hour.toString().padLeft(2, '0')}:${_peakStartTime.minute.toString().padLeft(2, '0')}',
          'endTime': '${_peakEndTime.hour.toString().padLeft(2, '0')}:${_peakEndTime.minute.toString().padLeft(2, '0')}',
        },
        'minimumBookingDuration': int.parse(_minBookingDurationController.text),
      };

      await facilityProvider.createFacility(
        ownerId: authProvider.user!.uid,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: AddressModel(
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: 'France',
        ),
        amenities: _selectedAmenities,
        capacity: int.parse(_capacityController.text),
        hourlyRate: double.parse(_hourlyRateController.text),
        peakHourRate: _peakHourRateController.text.isNotEmpty
            ? double.parse(_peakHourRateController.text)
            : null,
        images: _selectedImages,
      );


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salle créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une salle'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildStepIndicator(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildBasicInfoStep(),
            _buildAddressStep(),
            _buildPhotosStep(),
            _buildAmenitiesStep(),
            _buildPricingStep(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Infos', 'Adresse', 'Photos', 'Équipements', 'Tarifs'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? AppTheme.lightTheme.primaryColor
                        : isCompleted
                            ? Colors.green
                            : Colors.grey[300],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted ? Colors.green : Colors.grey[300],
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de base',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Décrivez votre salle pour attirer les coachs',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom de la salle *',
              hintText: 'Ex: Fitness Studio Paris 11',
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le nom est requis';
              }
              if (value.length < 3) {
                return 'Le nom doit contenir au moins 3 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Décrivez votre salle, ses atouts, son ambiance...',
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La description est requise';
              }
              if (value.length < 50) {
                return 'La description doit contenir au moins 50 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Capacité maximale *',
              hintText: 'Nombre de personnes',
              prefixIcon: Icon(Icons.people),
              suffixText: 'personnes',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La capacité est requise';
              }
              final capacity = int.tryParse(value);
              if (capacity == null || capacity < 1) {
                return 'Entrez un nombre valide';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adresse',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Où se situe votre salle ?',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _streetController,
            decoration: const InputDecoration(
              labelText: 'Adresse *',
              hintText: 'Numéro et nom de rue',
              prefixIcon: Icon(Icons.location_on),
            ),
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
                child: TextFormField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Code postal *',
                    hintText: '75011',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Requis';
                    }
                    if (value.length != 5) {
                      return 'Code postal invalide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville *',
                    hintText: 'Paris',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La ville est requise';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Aperçu de la carte',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(Google Maps sera affiché ici)',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des photos de qualité pour attirer les coachs (max 10)',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _selectedImages.length < 10 ? _pickImages : null,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.lightTheme.primaryColor,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: AppTheme.lightTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajouter des photos',
                    style: TextStyle(
                      color: AppTheme.lightTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedImages.length}/10 photos',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(_selectedImages[index].path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: index == 0
                            ? Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Principale',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
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
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Conseil: Utilisez des photos bien éclairées montrant l\'espace, les équipements et l\'ambiance de votre salle.',
                      style: TextStyle(color: Colors.blue[700], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Équipements',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez les équipements disponibles',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedAmenities.keys.map((amenity) {
              final isSelected = _selectedAmenities[amenity] ?? false;
              return FilterChip(
                label: Text(amenity),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedAmenities[amenity] = selected;
                  });
                },
                selectedColor: AppTheme.lightTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.lightTheme.primaryColor,
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Text(
            'Horaires d\'ouverture',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(7, (index) {
            final dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
            final range = _operatingHours[index]!;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        dayNames[index],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: range.isOpen,
                      onChanged: (value) {
                        setState(() {
                          _operatingHours[index] = TimeRange(
                            openTime: range.openTime,
                            closeTime: range.closeTime,
                            isOpen: value,
                          );
                        });
                      },
                    ),
                    if (range.isOpen) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _TimePickerButton(
                              time: range.openTime,
                              label: 'Ouv.',
                              onChanged: (time) {
                                setState(() {
                                  _operatingHours[index] = TimeRange(
                                    openTime: time,
                                    closeTime: range.closeTime,
                                    isOpen: range.isOpen,
                                  );
                                });
                              },
                            ),
                            const Text('-'),
                            _TimePickerButton(
                              time: range.closeTime,
                              label: 'Ferm.',
                              onChanged: (time) {
                                setState(() {
                                  _operatingHours[index] = TimeRange(
                                    openTime: range.openTime,
                                    closeTime: time,
                                    isOpen: range.isOpen,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ] else
                      const Expanded(
                        child: Text(
                          'Fermé',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPricingStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tarification',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Définissez vos tarifs horaires',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _hourlyRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Tarif horaire standard *',
              hintText: 'Ex: 50',
              prefixIcon: Icon(Icons.euro),
              suffixText: '€/h',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le tarif est requis';
              }
              final rate = double.tryParse(value);
              if (rate == null || rate < 15) {
                return 'Le tarif minimum est de 15€/h';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _peakHourRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Tarif heures pleines',
              hintText: 'Optionnel - Ex: 75',
              prefixIcon: const Icon(Icons.trending_up),
              suffixText: '€/h',
              helperText: 'Laissez vide pour +50% du tarif standard',
              helperStyle: TextStyle(color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Heures pleines',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez les jours et heures avec tarif majoré',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(7, (index) {
              final dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
              final isSelected = _peakHourDays.contains(index);
              
              return FilterChip(
                label: Text(dayNames[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _peakHourDays.add(index);
                    } else {
                      _peakHourDays.remove(index);
                    }
                  });
                },
                selectedColor: Colors.orange.withOpacity(0.2),
                checkmarkColor: Colors.orange,
              );
            }),
          ),
          if (_peakHourDays.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimePickerButton(
                    time: _peakStartTime,
                    label: 'Début',
                    onChanged: (time) {
                      setState(() {
                        _peakStartTime = time;
                      });
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('à'),
                ),
                Expanded(
                  child: _TimePickerButton(
                    time: _peakEndTime,
                    label: 'Fin',
                    onChanged: (time) {
                      setState(() {
                        _peakEndTime = time;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          TextFormField(
            controller: _minBookingDurationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Durée minimum de réservation',
              prefixIcon: Icon(Icons.timer),
              suffixText: 'heure(s)',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est requis';
              }
              final duration = int.tryParse(value);
              if (duration == null || duration < 1 || duration > 8) {
                return 'Entre 1 et 8 heures';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Commission plateforme',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UnCoachUneSalle prélève une commission de 15% sur chaque réservation. '
                    'Vous recevez 85% du montant de la réservation.',
                    style: TextStyle(color: Colors.green[700], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Précédent'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _currentStep < 4
                        ? _nextStep
                        : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_currentStep < 4 ? 'Suivant' : 'Créer la salle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeRange {
  final TimeOfDay openTime;
  final TimeOfDay closeTime;
  final bool isOpen;

  TimeRange({
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
  });
}

class _TimePickerButton extends StatelessWidget {
  final TimeOfDay time;
  final String label;
  final Function(TimeOfDay) onChanged;

  const _TimePickerButton({
    required this.time,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                alwaysUse24HourFormat: true,
              ),
              child: child!,
            );
          },
        );
        if (selectedTime != null) {
          onChanged(selectedTime);
        }
      },
      child: Text(
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      ),
    );
  }
}
