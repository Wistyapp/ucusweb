import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_auth_provider.dart';
import '../../../core/providers/app_booking_provider.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class FacilityBookingsScreen extends StatefulWidget {
  const FacilityBookingsScreen({super.key});

  @override
  State<FacilityBookingsScreen> createState() => _FacilityBookingsScreenState();
}

class _FacilityBookingsScreenState extends State<FacilityBookingsScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final authProvider = context.read<AppAuthProvider>();
    final bookingProvider = context.read<AppBookingProvider>();
    
    if (authProvider.user != null) {
      await bookingProvider.loadFacilityOwnerBookings(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Confirmées'),
            Tab(text: 'Passées'),
            Tab(text: 'Annulées'),
          ],
        ),
      ),
      body: Consumer<AppBookingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pendingBookings = provider.bookings
              .where((b) => b.status == BookingStatus.pending)
              .toList();
          final confirmedBookings = provider.bookings
              .where((b) => b.status == BookingStatus.confirmed || 
                           b.status == BookingStatus.inProgress)
              .toList();
          final pastBookings = provider.bookings
              .where((b) => b.status == BookingStatus.completed)
              .toList();
          final cancelledBookings = provider.bookings
              .where((b) => b.status == BookingStatus.cancelled)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingsList(
                bookings: pendingBookings,
                emptyMessage: 'Aucune réservation en attente',
                emptyIcon: Icons.pending_actions,
                showActions: true,
              ),
              _BookingsList(
                bookings: confirmedBookings,
                emptyMessage: 'Aucune réservation confirmée',
                emptyIcon: Icons.event_available,
              ),
              _BookingsList(
                bookings: pastBookings,
                emptyMessage: 'Aucune réservation passée',
                emptyIcon: Icons.history,
              ),
              _BookingsList(
                bookings: cancelledBookings,
                emptyMessage: 'Aucune réservation annulée',
                emptyIcon: Icons.event_busy,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showActions;

  const _BookingsList({
    required this.bookings,
    required this.emptyMessage,
    required this.emptyIcon,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = context.read<AppAuthProvider>();
        final bookingProvider = context.read<AppBookingProvider>();
        
        if (authProvider.user != null) {
          await bookingProvider.loadFacilityOwnerBookings(authProvider.user!.uid);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _BookingCard(
            booking: booking,
            showActions: showActions,
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool showActions;

  const _BookingCard({
    required this.booking,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/booking-detail',
          arguments: booking.id,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.lightTheme.primaryColor.withValues(alpha:0.1),
                        child: Icon(
                          Icons.fitness_center,
                          color: AppTheme.lightTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coach', // Would fetch coach name
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Réservation #${booking.id.substring(0, 8)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  _buildStatusChip(booking.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: _formatDate(booking.startTime),
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.access_time,
                      label: 'Horaire',
                      value: _formatTimeRange(booking.startTime, booking.endTime),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.timer,
                      label: 'Durée',
                      value: '${booking.durationHours}h',
                    ),
                  ),
                  Expanded(
                    child: _InfoItem(
                      icon: Icons.euro,
                      label: 'Montant',
                      value: '${booking.totalPrice.toStringAsFixed(0)}€',
                      valueColor: AppTheme.lightTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.notes!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (showActions && booking.status == BookingStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDeclineDialog(context, booking),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text(
                          'Refuser',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmBooking(context, booking),
                        icon: const Icon(Icons.check),
                        label: const Text('Accepter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        label = 'En attente';
        icon = Icons.pending;
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        label = 'Confirmée';
        icon = Icons.check_circle;
        break;
      case BookingStatus.inProgress:
        color = Colors.blue;
        label = 'En cours';
        icon = Icons.play_circle;
        break;
      case BookingStatus.completed:
        color = Colors.grey;
        label = 'Terminée';
        icon = Icons.done_all;
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        label = 'Annulée';
        icon = Icons.cancel;
        break;
        default:
        color = Colors.grey;
        label = 'indisponible';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - '
           '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  void _showDeclineDialog(BuildContext context, BookingModel booking) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir refuser cette réservation ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Raison du refus (optionnel)',
                hintText: 'Expliquez pourquoi vous refusez...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final bookingProvider = context.read<AppBookingProvider>();
              await bookingProvider.cancelBooking(
                bookingId: booking.id,
                reason: reasonController.text.isNotEmpty 
                    ? reasonController.text 
                    : 'Refusé par le propriétaire',
                cancelledBy: context.read<AppAuthProvider>().user!.displayName ?? 'indisponible',
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Réservation refusée'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  void _confirmBooking(BuildContext context, BookingModel booking) async {
    final bookingProvider = context.read<AppBookingProvider>();
    
    try {
      await bookingProvider.confirmBooking(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation confirmée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
