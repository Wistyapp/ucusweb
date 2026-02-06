import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';

// Notification model
class AppNotification {
  final String id;
  final String type; // booking_confirmed, booking_cancelled, new_message, new_review, payment_received
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // In a real app, this would fetch from Firestore
    // For now, we'll use mock data
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _notifications = _getMockNotifications();
      _isLoading = false;
    });
  }

  List<AppNotification> _getMockNotifications() {
    // Mock notifications for demonstration
    return [
      AppNotification(
        id: '1',
        type: 'booking_confirmed',
        title: 'Réservation confirmée',
        body: 'Votre réservation au Fitness Center Paris a été confirmée pour le 10 février à 14h00.',
        data: {'bookingId': 'booking123'},
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AppNotification(
        id: '2',
        type: 'new_message',
        title: 'Nouveau message',
        body: 'Jean Dupont vous a envoyé un message.',
        data: {'conversationId': 'conv123', 'senderId': 'user123'},
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      AppNotification(
        id: '3',
        type: 'new_review',
        title: 'Nouvel avis',
        body: 'Vous avez reçu un nouvel avis 5 étoiles !',
        data: {'reviewId': 'review123'},
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: '4',
        type: 'payment_received',
        title: 'Paiement reçu',
        body: 'Vous avez reçu un paiement de 45,00 € pour votre réservation.',
        data: {'paymentId': 'payment123'},
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      AppNotification(
        id: '5',
        type: 'booking_reminder',
        title: 'Rappel de réservation',
        body: 'N\'oubliez pas votre séance demain à 10h00 au Studio Yoga Zen.',
        data: {'bookingId': 'booking456'},
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Tout marquer lu'),
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('Paramètres'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 12),
                    Text('Tout effacer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none,
        title: 'Aucune notification',
        message: 'Vous n\'avez pas de notification pour le moment.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _NotificationItem(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _dismissNotification(notification.id),
          );
        },
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data,
        createdAt: n.createdAt,
        isRead: true,
      )).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toutes les notifications marquées comme lues')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _showNotificationSettings();
        break;
      case 'clear_all':
        _confirmClearAll();
        break;
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _NotificationSettingsSheet(),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les notifications ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _notifications.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications effacées')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1 && !notification.isRead) {
        _notifications[index] = AppNotification(
          id: notification.id,
          type: notification.type,
          title: notification.title,
          body: notification.body,
          data: notification.data,
          createdAt: notification.createdAt,
          isRead: true,
        );
      }
    });

    // Navigate based on type
    switch (notification.type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_reminder':
        if (notification.data?['bookingId'] != null) {
          Navigator.pushNamed(
            context,
            AppRouter.bookingDetail,
            arguments: notification.data!['bookingId'],
          );
        }
        break;
      case 'new_message':
        if (notification.data?['conversationId'] != null) {
          Navigator.pushNamed(
            context,
            AppRouter.chat,
            arguments: {
              'conversationId': notification.data!['conversationId'],
              'otherUserName': 'Contact',
            },
          );
        }
        break;
      case 'new_review':
        Navigator.pushNamed(context, AppRouter.reviews);
        break;
      case 'payment_received':
        // Could navigate to a payment details screen
        break;
    }
  }

  void _dismissNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification supprimée'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: _loadNotifications,
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead ? null : AppTheme.primaryColor.withOpacity(0.05),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'booking_confirmed':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'booking_reminder':
        return Icons.alarm;
      case 'new_message':
        return Icons.chat_bubble;
      case 'new_review':
        return Icons.star;
      case 'payment_received':
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'booking_confirmed':
        return Colors.green;
      case 'booking_cancelled':
        return Colors.red;
      case 'booking_reminder':
        return Colors.orange;
      case 'new_message':
        return Colors.blue;
      case 'new_review':
        return Colors.amber;
      case 'payment_received':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours} h';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return DateFormat('d MMM', 'fr_FR').format(time);
    }
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  @override
  State<_NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<_NotificationSettingsSheet> {
  bool _bookingNotifications = true;
  bool _messageNotifications = true;
  bool _reviewNotifications = true;
  bool _paymentNotifications = true;
  bool _marketingNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Paramètres de notification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          _buildSwitch(
            'Réservations',
            'Confirmations, rappels, annulations',
            _bookingNotifications,
            (v) => setState(() => _bookingNotifications = v),
          ),
          _buildSwitch(
            'Messages',
            'Nouveaux messages de conversation',
            _messageNotifications,
            (v) => setState(() => _messageNotifications = v),
          ),
          _buildSwitch(
            'Avis',
            'Nouveaux avis reçus',
            _reviewNotifications,
            (v) => setState(() => _reviewNotifications = v),
          ),
          _buildSwitch(
            'Paiements',
            'Confirmation de paiement, remboursements',
            _paymentNotifications,
            (v) => setState(() => _paymentNotifications = v),
          ),
          _buildSwitch(
            'Marketing',
            'Promotions et actualités',
            _marketingNotifications,
            (v) => setState(() => _marketingNotifications = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Paramètres enregistrés')),
                );
              },
              child: const Text('Enregistrer'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
      contentPadding: EdgeInsets.zero,
    );
  }
}
