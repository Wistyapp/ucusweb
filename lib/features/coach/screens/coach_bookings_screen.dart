import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class CoachBookingsScreen extends StatefulWidget {
  const CoachBookingsScreen({super.key});

  @override
  State<CoachBookingsScreen> createState() => _CoachBookingsScreenState();
}

class _CoachBookingsScreenState extends State<CoachBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<BookingProvider>().loadCoachBookings(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Passées'),
            Tab(text: 'Annulées'),
          ],
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final upcoming = provider.coachBookings
              .where((b) => b.isUpcoming && !b.isCancelled)
              .toList();
          final past = provider.coachBookings
              .where((b) => b.isPast && !b.isCancelled)
              .toList();
          final cancelled = provider.coachBookings
              .where((b) => b.isCancelled)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(upcoming, 'Aucune réservation à venir'),
              _buildBookingsList(past, 'Aucune réservation passée'),
              _buildBookingsList(cancelled, 'Aucune réservation annulée'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Facility image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surfaceVariant,
                    ),
                    child: booking.facilityImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              booking.facilityImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.fitness_center,
                            color: AppColors.textTertiary,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.facilityName ?? 'Installation',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (booking.spaceName != null)
                          Text(
                            booking.spaceName!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Date and time
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat('dd/MM/yyyy').format(booking.startTime),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.access_time,
                      label: 'Horaire',
                      value:
                          '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.euro,
                      label: 'Prix',
                      value: '${booking.totalPrice.toStringAsFixed(2)}€',
                    ),
                  ),
                ],
              ),

              // Actions
              if (booking.canCancel) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showCancelDialog(booking),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ],

              // Review reminder
              if (booking.canReview) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.rate_review,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Laissez un avis sur votre expérience',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to write review
                        },
                        child: const Text('Écrire'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case BookingStatus.pending:
        color = AppColors.warning;
        label = 'En attente';
        break;
      case BookingStatus.confirmed:
        color = AppColors.success;
        label = 'Confirmé';
        break;
      case BookingStatus.inProgress:
        color = AppColors.primary;
        label = 'En cours';
        break;
      case BookingStatus.completed:
        color = AppColors.textTertiary;
        label = 'Terminé';
        break;
      case BookingStatus.cancelled:
        color = AppColors.error;
        label = 'Annulé';
        break;
      default:
        color = AppColors.textTertiary;
        label = status;
    }

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
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Détails de la réservation',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                // Add more booking details here
                _buildDetailRow('Installation', booking.facilityName ?? '-'),
                _buildDetailRow('Espace', booking.spaceName ?? '-'),
                _buildDetailRow(
                  'Date',
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                      .format(booking.startTime),
                ),
                _buildDetailRow(
                  'Horaire',
                  '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                ),
                _buildDetailRow('Durée', '${booking.durationHours}h'),
                _buildDetailRow(
                  'Prix total',
                  '${booking.totalPrice.toStringAsFixed(2)}€',
                ),
                _buildDetailRow('Statut', booking.status),
                if (booking.notes != null)
                  _buildDetailRow('Notes', booking.notes!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Politique de remboursement :',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              booking.refundPolicyText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Montant remboursé : ${booking.calculateRefundAmount().toStringAsFixed(2)}€',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result =
                  await context.read<BookingProvider>().cancelBooking(
                        bookingId: booking.id,
                        reason: 'Annulé par le coach',
                        cancelledBy: 'coach',
                      );
              if (result.success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Réservation annulée. Remboursement : ${result.refundAmount.toStringAsFixed(2)}€',
                    ),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );
  }
}
