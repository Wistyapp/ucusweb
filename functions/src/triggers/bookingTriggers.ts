/**
 * Booking Triggers - Firestore document triggers for bookings
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  COLLECTIONS,
  BOOKING_STATUS,
  PAYMENT_STATUS,
} from '../config/constants';
import {
  sendNotification,
  sendBookingCancellation,
  sendPaymentReceivedNotification,
} from '../functions/notifications';
import { NOTIFICATION_TYPES } from '../config/constants';

const db = admin.firestore();

/**
 * Trigger when a booking is created
 */
export const onBookingCreated = functions.region('europe-west1')
  .firestore.document(`${COLLECTIONS.BOOKINGS}/{bookingId}`)
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    const bookingId = context.params.bookingId;

    console.log(`New booking created: ${bookingId}`);

    // Notify facility owner about new booking request
    await sendNotification({
      userId: booking.facilityOwnerId,
      type: NOTIFICATION_TYPES.BOOKING_CREATED,
      title: 'Nouvelle demande de réservation',
      body: `Un coach souhaite réserver ${booking.facilityName}`,
      data: { bookingId },
    });
  });

/**
 * Trigger when a booking is updated
 */
export const onBookingUpdated = functions.region('europe-west1')
  .firestore.document(`${COLLECTIONS.BOOKINGS}/{bookingId}`)
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const bookingId = context.params.bookingId;

    // Status changed
    if (before.status !== after.status) {
      console.log(`Booking ${bookingId} status changed: ${before.status} -> ${after.status}`);

      // Booking confirmed
      if (after.status === BOOKING_STATUS.CONFIRMED) {
        const startTime = after.startTime.toDate();
        const formattedDate = startTime.toLocaleDateString('fr-FR', {
          weekday: 'long',
          day: 'numeric',
          month: 'long',
          hour: '2-digit',
          minute: '2-digit',
        });

        await sendNotification({
          userId: after.coachId,
          type: NOTIFICATION_TYPES.BOOKING_CONFIRMED,
          title: 'Réservation confirmée ✅',
          body: `Votre réservation à ${after.facilityName} le ${formattedDate} est confirmée.`,
          data: { bookingId },
        });
      }

      // Booking cancelled
      if (after.status === BOOKING_STATUS.CANCELLED) {
        await sendBookingCancellation(
          bookingId,
          after.cancellationInitiatedBy || 'coach',
          after.cancellationReason
        );
      }

      // Booking completed - set review deadline
      if (after.status === BOOKING_STATUS.COMPLETED) {
        const reviewDeadline = new Date();
        reviewDeadline.setDate(reviewDeadline.getDate() + 30);

        await change.after.ref.update({
          reviewDeadline: admin.firestore.Timestamp.fromDate(reviewDeadline),
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Prompt users to leave reviews
        await sendNotification({
          userId: after.coachId,
          type: NOTIFICATION_TYPES.BOOKING_CONFIRMED,
          title: 'Séance terminée 🎉',
          body: `N'oubliez pas de laisser un avis pour ${after.facilityName}`,
          data: { bookingId },
        });

        await sendNotification({
          userId: after.facilityOwnerId,
          type: NOTIFICATION_TYPES.BOOKING_CONFIRMED,
          title: 'Séance terminée 🎉',
          body: `N'oubliez pas de laisser un avis pour votre coach`,
          data: { bookingId },
        });
      }
    }

    // Payment status changed
    if (before.paymentStatus !== after.paymentStatus) {
      console.log(`Booking ${bookingId} payment status changed: ${before.paymentStatus} -> ${after.paymentStatus}`);

      // Payment succeeded
      if (after.paymentStatus === PAYMENT_STATUS.SUCCEEDED) {
        // Notify facility owner
        await sendPaymentReceivedNotification(
          after.facilityOwnerId,
          after.subtotal, // Amount they'll receive (minus platform commission)
          bookingId
        );

        // Create payment record
        await db.collection(COLLECTIONS.PAYMENTS).add({
          bookingId,
          userId: after.coachId,
          facilityOwnerId: after.facilityOwnerId,
          type: 'payment',
          amount: after.totalPrice,
          currency: 'EUR',
          platformCommission: after.platformCommission,
          facilityAmount: after.subtotal,
          status: 'succeeded',
          stripePaymentIntentId: after.stripePaymentIntentId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Payment failed
      if (after.paymentStatus === PAYMENT_STATUS.FAILED) {
        await sendNotification({
          userId: after.coachId,
          type: NOTIFICATION_TYPES.PAYMENT_FAILED,
          title: 'Échec du paiement ❌',
          body: 'Votre paiement a échoué. Veuillez réessayer.',
          data: { bookingId },
        });
      }
    }
  });

/**
 * Scheduled function to mark in-progress bookings as completed
 */
export const markBookingsCompleted = functions.region('europe-west1')
  .pubsub.schedule('*/15 * * * *') // Every 15 minutes
  .timeZone('Europe/Paris')
  .onRun(async () => {
    const now = new Date();

    // Find bookings that should be completed
    const bookingsSnapshot = await db.collection(COLLECTIONS.BOOKINGS)
      .where('status', '==', BOOKING_STATUS.CONFIRMED)
      .where('endTime', '<=', admin.firestore.Timestamp.fromDate(now))
      .get();

    const batch = db.batch();
    let count = 0;

    bookingsSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: BOOKING_STATUS.COMPLETED,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      count++;
    });

    if (count > 0) {
      await batch.commit();
      console.log(`Marked ${count} bookings as completed`);
    }
  });

/**
 * Scheduled function to mark bookings as in-progress
 */
export const markBookingsInProgress = functions.region('europe-west1')
  .pubsub.schedule('*/5 * * * *') // Every 5 minutes
  .timeZone('Europe/Paris')
  .onRun(async () => {
    const now = new Date();

    // Find bookings that should be in progress
    const bookingsSnapshot = await db.collection(COLLECTIONS.BOOKINGS)
      .where('status', '==', BOOKING_STATUS.CONFIRMED)
      .where('startTime', '<=', admin.firestore.Timestamp.fromDate(now))
      .where('endTime', '>', admin.firestore.Timestamp.fromDate(now))
      .get();

    const batch = db.batch();
    let count = 0;

    bookingsSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: BOOKING_STATUS.IN_PROGRESS,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      count++;
    });

    if (count > 0) {
      await batch.commit();
      console.log(`Marked ${count} bookings as in-progress`);
    }
  });

/**
 * Cleanup expired pending bookings (payment not completed within 30 minutes)
 */
export const cleanupExpiredBookings = functions.region('europe-west1')
  .pubsub.schedule('*/10 * * * *') // Every 10 minutes
  .timeZone('Europe/Paris')
  .onRun(async () => {
    const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);

    // Find pending bookings created more than 30 minutes ago with no payment
    const expiredBookings = await db.collection(COLLECTIONS.BOOKINGS)
      .where('status', '==', BOOKING_STATUS.PENDING)
      .where('paymentStatus', '==', PAYMENT_STATUS.PENDING)
      .where('createdAt', '<=', admin.firestore.Timestamp.fromDate(thirtyMinutesAgo))
      .get();

    const batch = db.batch();
    let count = 0;

    expiredBookings.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: BOOKING_STATUS.CANCELLED,
        cancellationReason: 'Paiement non effectué dans les délais',
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      count++;
    });

    if (count > 0) {
      await batch.commit();
      console.log(`Cancelled ${count} expired pending bookings`);
    }
  });
