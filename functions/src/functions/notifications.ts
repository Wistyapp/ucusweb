/**
 * Notification Functions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  COLLECTIONS,
  NOTIFICATION_TYPES,
} from '../config/constants';

const db = admin.firestore();
const messaging = admin.messaging();

interface NotificationPayload {
  userId: string;
  type: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Send a push notification to a user
 */
export async function sendNotification(payload: NotificationPayload): Promise<void> {
  const { userId, type, title, body, data } = payload;

  try {
    // Get user's FCM token and notification preferences
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data()!;
    const fcmToken = userData.fcmToken;
    const preferences = userData.notificationPreferences || {};

    // Check if user wants this type of notification
    const categoryMap: Record<string, string> = {
      [NOTIFICATION_TYPES.BOOKING_CREATED]: 'bookings',
      [NOTIFICATION_TYPES.BOOKING_CONFIRMED]: 'bookings',
      [NOTIFICATION_TYPES.BOOKING_CANCELLED]: 'bookings',
      [NOTIFICATION_TYPES.BOOKING_REMINDER]: 'bookings',
      [NOTIFICATION_TYPES.PAYMENT_RECEIVED]: 'bookings',
      [NOTIFICATION_TYPES.PAYMENT_FAILED]: 'bookings',
      [NOTIFICATION_TYPES.NEW_MESSAGE]: 'messages',
      [NOTIFICATION_TYPES.NEW_REVIEW]: 'reviews',
      [NOTIFICATION_TYPES.VERIFICATION_APPROVED]: 'bookings',
      [NOTIFICATION_TYPES.VERIFICATION_REJECTED]: 'bookings',
    };

    const category = categoryMap[type];
    if (category && preferences[category] === false) {
      console.log(`User ${userId} has disabled ${category} notifications`);
      return;
    }

    // Save notification to Firestore
    await db.collection(COLLECTIONS.NOTIFICATIONS).add({
      userId,
      type,
      title,
      body,
      data: data || {},
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send push notification if token exists
    if (fcmToken) {
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: {
          type,
          ...data,
        },
        android: {
          notification: {
            channelId: 'default',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title,
                body,
              },
              badge: 1,
              sound: 'default',
            },
          },
        },
        webpush: {
          notification: {
            icon: '/icons/icon-192x192.png',
            badge: '/icons/badge-72x72.png',
          },
        },
      };

      await messaging.send(message);
      console.log(`Push notification sent to user ${userId}`);
    }
  } catch (err) {
    console.error('Error sending notification:', err);
  }
}

/**
 * Send booking confirmation notification
 */
export const sendBookingConfirmation = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { bookingId } = data;
    if (!bookingId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de réservation requis');
    }

    const bookingDoc = await db.collection(COLLECTIONS.BOOKINGS).doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Réservation non trouvée');
    }

    const booking = bookingDoc.data()!;
    const startTime = booking.startTime.toDate();
    const formattedDate = startTime.toLocaleDateString('fr-FR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

    // Notify coach
    await sendNotification({
      userId: booking.coachId,
      type: NOTIFICATION_TYPES.BOOKING_CONFIRMED,
      title: 'Réservation confirmée ✅',
      body: `Votre réservation à ${booking.facilityName} le ${formattedDate} est confirmée.`,
      data: { bookingId },
    });

    return { success: true };
  }
);

/**
 * Send booking cancellation notification
 */
export async function sendBookingCancellation(
  bookingId: string,
  cancelledBy: 'coach' | 'facility',
  reason?: string
): Promise<void> {
  const bookingDoc = await db.collection(COLLECTIONS.BOOKINGS).doc(bookingId).get();
  if (!bookingDoc.exists) return;

  const booking = bookingDoc.data()!;
  const startTime = booking.startTime.toDate();
  const formattedDate = startTime.toLocaleDateString('fr-FR', {
    day: 'numeric',
    month: 'long',
    hour: '2-digit',
    minute: '2-digit',
  });

  // Notify the other party
  const recipientId = cancelledBy === 'coach' ? booking.facilityOwnerId : booking.coachId;
  const cancellerType = cancelledBy === 'coach' ? 'Le coach' : 'Le propriétaire';

  await sendNotification({
    userId: recipientId,
    type: NOTIFICATION_TYPES.BOOKING_CANCELLED,
    title: 'Réservation annulée ❌',
    body: `${cancellerType} a annulé la réservation du ${formattedDate}.${reason ? ` Raison: ${reason}` : ''}`,
    data: { bookingId },
  });
}

/**
 * Send booking reminder (24h before)
 */
export const sendBookingReminders = functions.region('europe-west1')
  .pubsub.schedule('0 9 * * *') // Every day at 9 AM
  .timeZone('Europe/Paris')
  .onRun(async () => {
    const now = new Date();
    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const tomorrowEnd = new Date(tomorrow.getTime() + 60 * 60 * 1000);

    // Find bookings starting tomorrow around this time
    const bookingsSnapshot = await db.collection(COLLECTIONS.BOOKINGS)
      .where('status', '==', 'confirmed')
      .where('startTime', '>=', admin.firestore.Timestamp.fromDate(tomorrow))
      .where('startTime', '<', admin.firestore.Timestamp.fromDate(tomorrowEnd))
      .where('reminderSentAt', '==', null)
      .get();

    for (const doc of bookingsSnapshot.docs) {
      const booking = doc.data();
      const startTime = booking.startTime.toDate();
      const formattedTime = startTime.toLocaleTimeString('fr-FR', {
        hour: '2-digit',
        minute: '2-digit',
      });

      // Remind coach
      await sendNotification({
        userId: booking.coachId,
        type: NOTIFICATION_TYPES.BOOKING_REMINDER,
        title: 'Rappel: réservation demain 📅',
        body: `N'oubliez pas votre séance demain à ${formattedTime} à ${booking.facilityName}`,
        data: { bookingId: doc.id },
      });

      // Remind facility owner
      await sendNotification({
        userId: booking.facilityOwnerId,
        type: NOTIFICATION_TYPES.BOOKING_REMINDER,
        title: 'Rappel: réservation demain 📅',
        body: `Vous avez une réservation demain à ${formattedTime}`,
        data: { bookingId: doc.id },
      });

      // Mark reminder as sent
      await doc.ref.update({
        reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    console.log(`Sent ${bookingsSnapshot.size * 2} booking reminders`);
  });

/**
 * Send new message notification
 */
export async function sendNewMessageNotification(
  recipientId: string,
  senderName: string,
  messagePreview: string,
  conversationId: string
): Promise<void> {
  await sendNotification({
    userId: recipientId,
    type: NOTIFICATION_TYPES.NEW_MESSAGE,
    title: `Message de ${senderName}`,
    body: messagePreview.length > 100 ? `${messagePreview.substring(0, 100)}...` : messagePreview,
    data: { conversationId },
  });
}

/**
 * Send new review notification
 */
export async function sendNewReviewNotification(
  revieweeId: string,
  reviewerName: string,
  rating: number,
  reviewId: string
): Promise<void> {
  const stars = '⭐'.repeat(Math.round(rating));
  
  await sendNotification({
    userId: revieweeId,
    type: NOTIFICATION_TYPES.NEW_REVIEW,
    title: 'Nouvel avis reçu !',
    body: `${reviewerName} vous a laissé un avis ${stars}`,
    data: { reviewId },
  });
}

/**
 * Send payment received notification (for facility owners)
 */
export async function sendPaymentReceivedNotification(
  facilityOwnerId: string,
  amount: number,
  bookingId: string
): Promise<void> {
  await sendNotification({
    userId: facilityOwnerId,
    type: NOTIFICATION_TYPES.PAYMENT_RECEIVED,
    title: 'Paiement reçu 💰',
    body: `Vous avez reçu un paiement de ${amount.toFixed(2)} €`,
    data: { bookingId },
  });
}

/**
 * Mark notifications as read
 */
export const markNotificationsRead = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { notificationIds } = data;
    
    if (!notificationIds || !Array.isArray(notificationIds)) {
      throw new functions.https.HttpsError('invalid-argument', 'IDs de notifications requis');
    }

    const batch = db.batch();

    for (const notificationId of notificationIds) {
      const ref = db.collection(COLLECTIONS.NOTIFICATIONS).doc(notificationId);
      batch.update(ref, {
        isRead: true,
        readAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    return { success: true };
  }
);

/**
 * Get user's unread notification count
 */
export const getUnreadCount = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const snapshot = await db.collection(COLLECTIONS.NOTIFICATIONS)
      .where('userId', '==', context.auth.uid)
      .where('isRead', '==', false)
      .count()
      .get();

    return {
      success: true,
      count: snapshot.data().count,
    };
  }
);
