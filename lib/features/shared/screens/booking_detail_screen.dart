import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_booking_provider.dart';
import '../../../core/providers/app_auth_provider.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingModel? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      setState(() => _isLoading = true);
      final bookingProvider = Provider.of<AppBookingProvider>(context, listen: false);
      final booking = await bookingProvider.getBookingById(widget.bookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la réservation'),
        actions: [
          if (_booking != null)
            IconButton(
              icon: const Icon(Icons.chat_outlined),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRouter.chat,
                arguments: {
                  'conversationId': _booking!.conversationId,
                  'otherUserName': _booking!.facilityName,
                },
              ),
              tooltip: 'Envoyer un message',
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBooking,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_booking == null) {
      return const Center(child: Text('Réservation non trouvée'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusBanner(),
          _buildFacilityInfo(),
          const Divider(height: 1),
          _buildBookingDetails(),
          const Divider(height: 1),
          _buildPaymentInfo(),
          const Divider(height: 1),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final color = _getStatusColor(_booking!.status);
    final icon = _getStatusIcon(_booking!.status);
    final label = _getStatusLabel(_booking!.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: color?.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Text(
            label?? '',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Facility image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _booking!.facilityImage != null
                ? CachedNetworkImage(
                    imageUrl: _booking!.facilityImage!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.business, size: 48, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 16),
          // Facility details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _booking?.facilityName ?? 'Nom de l\'établissement non disponible',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_booking!.spaceName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Espace: ${_booking!.spaceName}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 8),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: dateFormat.format(_booking!.startTime),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Horaire',
            value: '${timeFormat.format(_booking!.startTime)} - ${timeFormat.format(_booking!.endTime)}',
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.timelapse,
            label: 'Durée',
            value: '${_booking!.durationHours} heure${_booking!.durationHours > 1 ? 's' : ''}',
          ),
          if (_booking!.notes != null && _booking!.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.note,
              label: 'Notes',
              value: _booking!.notes!,
            ),
          ],
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.confirmation_number,
            label: 'Référence',
            value: _booking!.id.substring(0, 8).toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paiement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sous-total'),
              Text('${_booking!.subtotal.toStringAsFixed(2)} €'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Commission plateforme (15%)'),
              Text('${_booking!.platformCommission.toStringAsFixed(2)} €'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '${_booking!.totalPrice.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppTheme.lightTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(_booking!.paymentStatus)?.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPaymentStatusIcon(_booking!.paymentStatus),
                  size: 18,
                  color: _getPaymentStatusColor(_booking!.paymentStatus),
                ),
                const SizedBox(width: 8),
                Text(
                  _getPaymentStatusLabel(_booking!.paymentStatus ) ?? 'non disponible',
                  style: TextStyle(
                    color: _getPaymentStatusColor(_booking!.paymentStatus),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final isCoach = authProvider.userType == 'coach';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Show write review button if booking is completed and no review yet
          if (_booking!.status == BookingStatus.completed && !_booking!.hasReview) ...[
            CustomButton(
              text: 'Laisser un avis',
              onPressed: () => Navigator.pushNamed(
                context,
                AppRouter.writeReview,
                arguments: {
                  'bookingId': _booking!.id,
                  'revieweeId': isCoach ? _booking!.facilityId : _booking!.coachId,
                  'reviewType': isCoach ? 'coach_to_facility' : 'facility_to_coach',
                },
              ),
              icon: Icons.star_border,
            ),
            const SizedBox(height: 12),
          ],

          // Cancel button for pending/confirmed bookings
          if (_booking!.status == BookingStatus.pending ||
              _booking!.status == BookingStatus.confirmed) ...[
            CustomButton(
              text: 'Annuler la réservation',
              onPressed: () => _showCancelDialog(),
              variant: ButtonVariant.outlined,
              icon: Icons.cancel_outlined,
            ),
            const SizedBox(height: 12),
          ],

          // Contact button
          CustomButton(
            text: isCoach ? 'Contacter le propriétaire' : 'Contacter le coach',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRouter.chat,
              arguments: {
                'conversationId': _booking!.conversationId,
                'otherUserName': isCoach ? _booking!.facilityName : _booking!.coachName,
              },
            ),
            variant: ButtonVariant.secondary,
            icon: Icons.chat_bubble_outline,
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
            const SizedBox(height: 16),
            _buildCancellationPolicy(),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison de l\'annulation (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelBooking(reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicy() {
    final hoursUntilStart = _booking!.startTime.difference(DateTime.now()).inHours;
    
    String refundText;
    Color refundColor;
    
    if (hoursUntilStart > 48) {
      refundText = 'Remboursement: 100%';
      refundColor = Colors.green;
    } else if (hoursUntilStart > 24) {
      refundText = 'Remboursement: 25%';
      refundColor = Colors.orange;
    } else {
      refundText = 'Pas de remboursement';
      refundColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: refundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: refundColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: refundColor, size: 20),
          const SizedBox(width: 8),
          Text(
            refundText,
            style: TextStyle(color: refundColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String reason) async {
    try {
      final bookingProvider = Provider.of<AppBookingProvider>(context, listen: false);
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      
      await bookingProvider.cancelBooking(
        bookingId: _booking!.id,
        reason: reason,
        cancelledBy: authProvider.userType ?? 'coach',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation annulée')),
        );
        _loadBooking(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Color? _getStatusColor(String status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      default:
        return null;
    }
  }

  IconData? _getStatusIcon(String status) {
    switch (status) {
      case BookingStatus.pending:
        return Icons.hourglass_empty;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.play_circle;
      case BookingStatus.completed:
        return Icons.verified;
      case BookingStatus.cancelled:
        return Icons.cancel;
      default:
        return null;
    }
  }

  String? _getStatusLabel(String status) {
    switch (status) {
      case BookingStatus.pending:
        return 'En attente de confirmation';
      case BookingStatus.confirmed:
        return 'Confirmée';
      case BookingStatus.inProgress:
        return 'En cours';
      case BookingStatus.completed:
        return 'Terminée';
      case BookingStatus.cancelled:
        return 'Annulée';
      default:
        return null;
    }
  }

  Color? _getPaymentStatusColor(String status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.blue;
        default:
        return null;
    }
  }

  IconData? _getPaymentStatusIcon(String status) {
    switch (status) {
      case PaymentStatus.pending:
        return Icons.pending;
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error;
      case PaymentStatus.refunded:
        return Icons.replay;
      default:
        return null;
    }
  }

  String? _getPaymentStatusLabel(String status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Paiement en attente';
      case PaymentStatus.completed:
        return 'Paiement effectué';
      case PaymentStatus.failed:
        return 'Paiement échoué';
      case PaymentStatus.refunded:
        return 'Remboursé';
      default:
        return null;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
