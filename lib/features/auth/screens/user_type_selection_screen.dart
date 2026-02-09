import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_auth_provider.dart';
import '../../../core/providers/app_user_provider.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? _selectedType;
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (_selectedType == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<AppUserProvider>();
      final authProvider = context.read<AppAuthProvider>();

      // Update user type in Firestore
      // This would typically be done through the user provider
      // For now, we'll navigate based on selection

      if (mounted) {
        if (_selectedType == UserTypes.coach) {
          Navigator.pushReplacementNamed(context, AppRouter.coachHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.facilityHome);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Header
              Text(
                'Comment souhaitez-vous\nutiliser l\'application ?',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous pourrez modifier ce choix plus tard dans les paramètres.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 48),

              // Coach option
              _buildOptionCard(
                type: UserTypes.coach,
                icon: Icons.fitness_center,
                color: AppColors.coachPrimary,
                title: 'Je suis Coach',
                description:
                    'Je recherche des espaces sportifs pour organiser mes sessions de coaching.',
                features: [
                  'Rechercher des installations',
                  'Réserver des créneaux',
                  'Gérer mes réservations',
                  'Communiquer avec les propriétaires',
                ],
              ),
              const SizedBox(height: 16),

              // Facility owner option
              _buildOptionCard(
                type: UserTypes.facility,
                icon: Icons.business,
                color: AppColors.facilityPrimary,
                title: 'Je suis Propriétaire',
                description:
                    'Je propose des espaces sportifs et je souhaite les rentabiliser.',
                features: [
                  'Publier mes installations',
                  'Gérer les disponibilités',
                  'Recevoir des réservations',
                  'Suivre mes revenus',
                ],
              ),

              const Spacer(),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _selectedType != null && !_isLoading ? _handleContinue : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Continuer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String type,
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required List<String> features,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color : null,
                                  ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: color,
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 12),
                    ...features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check,
                              size: 16,
                              color: color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              feature,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
