import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../widgets/upcoming_booking_card.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<BookingProvider>().loadCoachBookings(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeContent(),
            _buildSearchPlaceholder(),
            _buildBookingsPlaceholder(),
            _buildMessagesPlaceholder(),
            _buildProfilePlaceholder(),
          ],
        ),
      ),
      bottomNavigationBar: CoachBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, AppRouter.facilitySearch);
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRouter.coachBookings);
          } else if (index == 3) {
            Navigator.pushNamed(context, AppRouter.conversations);
          } else if (index == 4) {
            Navigator.pushNamed(context, AppRouter.profile);
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with greeting
            _buildHeader(),
            const SizedBox(height: 24),

            // Quick search
            _buildQuickSearch(),
            const SizedBox(height: 24),

            // Upcoming bookings
            _buildUpcomingBookings(),
            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(),
            const SizedBox(height: 24),

            // Featured facilities
            _buildFeaturedFacilities(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.currentUser;
        final greeting = _getGreeting();
        
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.displayName ?? 'Coach',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            // Notification bell
            IconButton(
              onPressed: () {
                // TODO: Navigate to notifications
              },
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, size: 28),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Profile avatar
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRouter.profile);
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: user?.profileImage != null
                    ? NetworkImage(user!.profileImage!)
                    : null,
                child: user?.profileImage == null
                    ? Text(
                        user?.displayName.substring(0, 1).toUpperCase() ?? 'C',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickSearch() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRouter.facilitySearch);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rechercher une installation...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Filtres',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, _) {
        final upcomingBookings = bookingProvider.upcomingCoachBookings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prochaines sessions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.coachBookings);
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (bookingProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (upcomingBookings.isEmpty)
              _buildEmptyBookings()
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingBookings.take(5).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return UpcomingBookingCard(
                      booking: upcomingBookings[index],
                      onTap: () {
                        // Navigate to booking details
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyBookings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune session à venir',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Recherchez un espace et réservez votre prochaine session',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.facilitySearch);
            },
            icon: const Icon(Icons.search),
            label: const Text('Trouver un espace'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.search,
                label: 'Rechercher',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.facilitySearch);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_month,
                label: 'Mes réservations',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.coachBookings);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.message_outlined,
                label: 'Messages',
                color: AppColors.accent,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.conversations);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedFacilities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Installations populaires',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        // Placeholder for featured facilities
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Découvrez les espaces près de vous',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchPlaceholder() => const Center(child: Text('Recherche'));
  Widget _buildBookingsPlaceholder() => const Center(child: Text('Réservations'));
  Widget _buildMessagesPlaceholder() => const Center(child: Text('Messages'));
  Widget _buildProfilePlaceholder() => const Center(child: Text('Profil'));

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}
