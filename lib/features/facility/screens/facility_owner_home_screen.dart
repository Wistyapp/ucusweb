import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/facility_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class FacilityOwnerHomeScreen extends StatefulWidget {
  const FacilityOwnerHomeScreen({super.key});

  @override
  State<FacilityOwnerHomeScreen> createState() => _FacilityOwnerHomeScreenState();
}

class _FacilityOwnerHomeScreenState extends State<FacilityOwnerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final facilityProvider = context.read<FacilityProvider>();
    final bookingProvider = context.read<BookingProvider>();

    if (authProvider.user != null) {
      await facilityProvider.loadOwnerFacilities(authProvider.user!.uid);
      await bookingProvider.loadFacilityOwnerBookings(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          _MyFacilitiesTab(),
          _BookingsTab(),
          _MessagesTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Mes Salles',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Réservations',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          final authProvider = context.read<AuthProvider>();
          final facilityProvider = context.read<FacilityProvider>();
          final bookingProvider = context.read<BookingProvider>();

          if (authProvider.user != null) {
            await facilityProvider.loadOwnerFacilities(authProvider.user!.uid);
            await bookingProvider.loadFacilityOwnerBookings(authProvider.user!.uid);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildQuickStats(context),
              const SizedBox(height: 24),
              _buildTodayBookings(context),
              const SizedBox(height: 24),
              _buildRevenueChart(context),
              const SizedBox(height: 24),
              _buildRecentActivity(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour,',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            Text(
              user?.displayName ?? 'Propriétaire',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
              icon: Badge(
                label: const Text('3'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundImage: user?.profileImage != null
                  ? NetworkImage(user!.profileImage!)
                  : null,
              child: user?.profileImage == null
                  ? const Icon(Icons.person)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final facilityProvider = context.watch<FacilityProvider>();

    final pendingBookings = bookingProvider.bookings
        .where((b) => b.status == BookingStatus.pending)
        .length;
    final confirmedBookings = bookingProvider.bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;
    final totalFacilities = facilityProvider.ownerFacilities.length;
    
    // Calculate monthly revenue
    final now = DateTime.now();
    final monthlyRevenue = bookingProvider.bookings
        .where((b) => 
            b.status == BookingStatus.completed &&
            b.startTime.month == now.month &&
            b.startTime.year == now.year)
        .fold<double>(0, (sum, b) => sum + (b.totalPrice - b.platformCommission));

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          title: 'En attente',
          value: pendingBookings.toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, '/facility-bookings', arguments: {'filter': 'pending'}),
        ),
        _StatCard(
          title: 'Confirmées',
          value: confirmedBookings.toString(),
          icon: Icons.check_circle_outline,
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, '/facility-bookings', arguments: {'filter': 'confirmed'}),
        ),
        _StatCard(
          title: 'Mes Salles',
          value: totalFacilities.toString(),
          icon: Icons.business,
          color: AppTheme.primaryColor,
          onTap: () => Navigator.pushNamed(context, '/my-facilities'),
        ),
        _StatCard(
          title: 'Ce mois',
          value: '${monthlyRevenue.toStringAsFixed(0)}€',
          icon: Icons.euro,
          color: Colors.purple,
          onTap: () => Navigator.pushNamed(context, '/analytics'),
        ),
      ],
    );
  }

  Widget _buildTodayBookings(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final now = DateTime.now();
    
    final todayBookings = bookingProvider.bookings.where((b) =>
        b.startTime.year == now.year &&
        b.startTime.month == now.month &&
        b.startTime.day == now.day &&
        (b.status == BookingStatus.confirmed || b.status == BookingStatus.inProgress)
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Réservations aujourd\'hui',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/facility-bookings'),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (todayBookings.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune réservation aujourd\'hui',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayBookings.length > 3 ? 3 : todayBookings.length,
            itemBuilder: (context, index) {
              final booking = todayBookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.fitness_center,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text('${booking.startTime.hour}:${booking.startTime.minute.toString().padLeft(2, '0')} - ${booking.endTime.hour}:${booking.endTime.minute.toString().padLeft(2, '0')}'),
                  subtitle: Text('${booking.totalPrice.toStringAsFixed(0)}€ • ${booking.durationHours}h'),
                  trailing: _buildStatusChip(booking.status),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/booking-detail',
                    arguments: booking.id,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    Color color;
    String label;

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        label = 'En attente';
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        label = 'Confirmée';
        break;
      case BookingStatus.inProgress:
        color = Colors.blue;
        label = 'En cours';
        break;
      case BookingStatus.completed:
        color = Colors.grey;
        label = 'Terminée';
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        label = 'Annulée';
        break;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenus - 7 derniers jours',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final dayNames = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                  final heights = [60.0, 80.0, 45.0, 120.0, 90.0, 150.0, 100.0];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 30,
                        height: heights[index],
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayNames[index],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité récente',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _ActivityItem(
                icon: Icons.book_online,
                title: 'Nouvelle réservation',
                subtitle: 'Coach Martin - Salle Fitness A',
                time: 'Il y a 2h',
                color: Colors.green,
              ),
              const Divider(height: 1),
              _ActivityItem(
                icon: Icons.star,
                title: 'Nouvel avis',
                subtitle: '5 étoiles de Coach Sophie',
                time: 'Il y a 4h',
                color: Colors.amber,
              ),
              const Divider(height: 1),
              _ActivityItem(
                icon: Icons.message,
                title: 'Nouveau message',
                subtitle: 'Coach Pierre vous a écrit',
                time: 'Hier',
                color: AppTheme.primaryColor,
              ),
              const Divider(height: 1),
              _ActivityItem(
                icon: Icons.payment,
                title: 'Paiement reçu',
                subtitle: '150€ - Réservation #12345',
                time: 'Hier',
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
    );
  }
}

// Placeholder tabs
class _MyFacilitiesTab extends StatelessWidget {
  const _MyFacilitiesTab();

  @override
  Widget build(BuildContext context) {
    return const MyFacilitiesScreen();
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  @override
  Widget build(BuildContext context) {
    return const FacilityBookingsScreen();
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return const ConversationsScreen();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}

// These screens will be imported from their respective files
class MyFacilitiesScreen extends StatelessWidget {
  const MyFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Salles'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/create-facility'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<FacilityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.ownerFacilities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune salle enregistrée',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre première salle pour\ncommencer à recevoir des réservations',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/create-facility'),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une salle'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.ownerFacilities.length,
            itemBuilder: (context, index) {
              final facility = provider.ownerFacilities[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/facility-detail',
                    arguments: facility.id,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Facility Image
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: facility.images.isNotEmpty
                            ? Image.network(
                                facility.images.first,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.business,
                                  size: 48,
                                  color: Colors.grey[500],
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    facility.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (facility.isVerified)
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${facility.address.city}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      facility.rating.toStringAsFixed(1),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      ' (${facility.reviewsCount} avis)',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${facility.hourlyRate.toStringAsFixed(0)}€/h',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatusBadge(
                                  label: facility.isActive ? 'Active' : 'Inactive',
                                  color: facility.isActive ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${facility.totalBookings} réservations',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
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
            },
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class FacilityBookingsScreen extends StatelessWidget {
  const FacilityBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Écran des réservations - À implémenter'),
      ),
    );
  }
}

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Écran des conversations - À implémenter'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Écran du profil - À implémenter'),
      ),
    );
  }
}
