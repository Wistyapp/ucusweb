import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/providers/app_facility_provider.dart';
import '../../../core/providers/app_auth_provider.dart';
import '../../../core/models/facility_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';

class MyFacilitiesScreen extends StatefulWidget {
  const MyFacilitiesScreen({super.key});

  @override
  State<MyFacilitiesScreen> createState() => _MyFacilitiesScreenState();
}

class _MyFacilitiesScreenState extends State<MyFacilitiesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  Future<void> _loadFacilities() async {
    final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
    final facilityProvider = Provider.of<AppFacilityProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await facilityProvider.loadOwnerFacilities(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Salles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, AppRouter.createFacility),
            tooltip: 'Ajouter une salle',
          ),
        ],
      ),
      body: Consumer<AppFacilityProvider>(
        builder: (context, facilityProvider, _) {
          if (facilityProvider.isLoading) {
            return const LoadingIndicator(message: 'Chargement de vos salles...');
          }

          if (facilityProvider.ownerFacilities.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.business_outlined,
              title: 'Aucune salle',
              description: 'Vous n\'avez pas encore ajouté de salle.\nCommencez dès maintenant !',
              buttonText: 'Ajouter une salle',
              onButtonPressed: () => Navigator.pushNamed(context, AppRouter.createFacility),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFacilities,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: facilityProvider.ownerFacilities.length,
              itemBuilder: (context, index) {
                final facility = facilityProvider.ownerFacilities[index];
                return _FacilityCard(
                  facility: facility,
                  onTap: () => _showFacilityOptions(context, facility),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRouter.createFacility),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Salle'),
      ),
    );
  }

  void _showFacilityOptions(BuildContext context, FacilityModel facility) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FacilityOptionsSheet(facility: facility),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  final FacilityModel facility;
  final VoidCallback onTap;

  const _FacilityCard({
    required this.facility,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  facility.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: facility.images.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.business, size: 64, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.business, size: 64, color: Colors.grey),
                        ),
                  // Status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: facility.isActive ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            facility.isActive ? Icons.check_circle : Icons.pause_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            facility.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Verified badge
                  if (facility.isVerified)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Vérifiée',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          facility.address.city,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.star,
                        value: facility.rating.toStringAsFixed(1),
                        label: '(${facility.reviewsCount})',
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        icon: Icons.calendar_today,
                        value: '${facility.totalBookings}',
                        label: 'réservations',
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                      const Spacer(),
                      Text(
                        '${facility.hourlyRate.toStringAsFixed(0)}€/h',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

class _FacilityOptionsSheet extends StatelessWidget {
  final FacilityModel facility;

  const _FacilityOptionsSheet({required this.facility});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Facility name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              facility.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          // Options
          ListTile(
            leading:  Icon(Icons.edit, color: AppTheme.lightTheme.primaryColor),
            title: const Text('Modifier la salle'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRouter.editFacility,
                arguments: facility.id,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Colors.blue),
            title: const Text('Gérer les disponibilités'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRouter.availability,
                arguments: facility.id,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_online, color: Colors.green),
            title: const Text('Voir les réservations'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRouter.facilityBookings,
                arguments: facility.id,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Voir les avis'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRouter.reviews,
                arguments: {
                  'userId': facility.id,
                  'userType': 'facility',
                },
              );
            },
          ),
          ListTile(
            leading: Icon(
              facility.isActive ? Icons.pause : Icons.play_arrow,
              color: facility.isActive ? Colors.orange : Colors.green,
            ),
            title: Text(facility.isActive ? 'Désactiver la salle' : 'Activer la salle'),
            onTap: () async {
              Navigator.pop(context);
              final facilityProvider = Provider.of<AppFacilityProvider>(
                context,
                listen: false,
              );
              await facilityProvider.toggleFacilityStatus(facility.id, !facility.isActive);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      facility.isActive
                          ? 'Salle désactivée'
                          : 'Salle activée',
                    ),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Supprimer la salle', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmDelete(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la salle ?'),
        content: Text(
          'Voulez-vous vraiment supprimer "${facility.name}" ?\n\n'
          'Cette action est irréversible et supprimera toutes les données associées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              
              final facilityProvider = Provider.of<AppFacilityProvider>(
                context,
                listen: false,
              );
              await facilityProvider.deleteFacility(facility.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Salle supprimée')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
