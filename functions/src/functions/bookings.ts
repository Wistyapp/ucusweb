/**
 * Booking Functions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as Joi from 'joi';
import { Decimal } from 'decimal.js';
import {
  COLLECTIONS,
  PLATFORM_COMMISSION_RATE,
  BOOKING_MIN_ADVANCE_HOURS,
  BOOKING_MAX_ADVANCE_DAYS,
  BOOKING_MIN_DURATION_HOURS,
  BOOKING_MAX_DURATION_HOURS,
  BOOKING_MAX_PER_DAY,
  BOOKING_MAX_PENDING,
  MIN_BOOKING_PRICE,
  MAX_BOOKING_PRICE,
  BOOKING_STATUS,
  PAYMENT_STATUS,
  CANCELLATION_FULL_REFUND_HOURS,
  CANCELLATION_PARTIAL_REFUND_HOURS,
  CANCELLATION_PARTIAL_REFUND_RATE,
} from '../config/constants';

const db = admin.firestore();

// Validation schemas
const createBookingSchema = Joi.object({
  facilityId: Joi.string().required(),
  spaceId: Joi.string().optional(),
  startTime: Joi.number().required(), // Unix timestamp in milliseconds
  endTime: Joi.number().required(),
  notes: Joi.string().max(500).optional(),
});

const cancelBookingSchema = Joi.object({
  bookingId: Joi.string().required(),
  reason: Joi.string().max(500).optional(),
});

/**
 * Create a new booking
 */
export const createBooking = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    // Validate input
    const { error, value } = createBookingSchema.validate(data);
    if (error) {
      throw new functions.https.HttpsError('invalid-argument', error.details[0].message);
    }

    const { facilityId, spaceId, startTime, endTime, notes } = value;
    const coachId = context.auth.uid;

    // Convert timestamps
    const startDate = new Date(startTime);
    const endDate = new Date(endTime);
    const now = new Date();

    // Validate time constraints
    const hoursUntilStart = (startDate.getTime() - now.getTime()) / (1000 * 60 * 60);
    if (hoursUntilStart < BOOKING_MIN_ADVANCE_HOURS) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Les réservations doivent être faites au moins ${BOOKING_MIN_ADVANCE_HOURS}h à l'avance`
      );
    }

    const daysUntilStart = hoursUntilStart / 24;
    if (daysUntilStart > BOOKING_MAX_ADVANCE_DAYS) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Les réservations ne peuvent pas dépasser ${BOOKING_MAX_ADVANCE_DAYS} jours à l'avance`
      );
    }

    if (endDate <= startDate) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'La date de fin doit être après la date de début'
      );
    }

    const durationHours = (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60);
    if (durationHours < BOOKING_MIN_DURATION_HOURS || durationHours > BOOKING_MAX_DURATION_HOURS) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `La durée doit être entre ${BOOKING_MIN_DURATION_HOURS} et ${BOOKING_MAX_DURATION_HOURS} heures`
      );
    }

    // Get facility data
    const facilityDoc = await db.collection(COLLECTIONS.FACILITIES).doc(facilityId).get();
    if (!facilityDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Salle non trouvée');
    }

    const facility = facilityDoc.data()!;
    if (!facility.isActive) {
      throw new functions.https.HttpsError('failed-precondition', 'Cette salle n\'est pas disponible');
    }

    // Check coach's pending bookings count
    const pendingBookings = await db.collection(COLLECTIONS.BOOKINGS)
      .where('coachId', '==', coachId)
      .where('status', '==', BOOKING_STATUS.PENDING)
      .get();

    if (pendingBookings.size >= BOOKING_MAX_PENDING) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Vous avez trop de réservations en attente de paiement'
      );
    }

    // Check coach's bookings for the same day
    const dayStart = new Date(startDate);
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date(startDate);
    dayEnd.setHours(23, 59, 59, 999);

    const sameDayBookings = await db.collection(COLLECTIONS.BOOKINGS)
      .where('coachId', '==', coachId)
      .where('startTime', '>=', admin.firestore.Timestamp.fromDate(dayStart))
      .where('startTime', '<=', admin.firestore.Timestamp.fromDate(dayEnd))
      .where('status', 'in', [BOOKING_STATUS.PENDING, BOOKING_STATUS.CONFIRMED])
      .get();

    if (sameDayBookings.size >= BOOKING_MAX_PER_DAY) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Vous ne pouvez pas avoir plus de ${BOOKING_MAX_PER_DAY} réservations par jour`
      );
    }

    // Check for booking conflicts
    const conflictingBookings = await db.collection(COLLECTIONS.BOOKINGS)
      .where('facilityId', '==', facilityId)
      .where('startTime', '<', admin.firestore.Timestamp.fromDate(endDate))
      .where('status', 'in', [BOOKING_STATUS.PENDING, BOOKING_STATUS.CONFIRMED])
      .get();

    const hasConflict = conflictingBookings.docs.some((doc) => {
      const booking = doc.data();
      const bookingEnd = booking.endTime.toDate();
      return bookingEnd > startDate;
    });

    if (hasConflict) {
      throw new functions.https.HttpsError(
        'already-exists',
        'Ce créneau est déjà réservé'
      );
    }

    // Calculate price
    const hourlyRate = new Decimal(facility.hourlyRate);
    const subtotal = hourlyRate.times(durationHours);
    const platformCommission = subtotal.times(PLATFORM_COMMISSION_RATE);
    const totalPrice = subtotal.plus(platformCommission);

    // Validate price constraints
    if (totalPrice.lessThan(MIN_BOOKING_PRICE)) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Le montant minimum de réservation est de ${MIN_BOOKING_PRICE}€`
      );
    }

    if (totalPrice.greaterThan(MAX_BOOKING_PRICE)) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Le montant maximum de réservation est de ${MAX_BOOKING_PRICE}€`
      );
    }

    // Create booking document
    const bookingRef = db.collection(COLLECTIONS.BOOKINGS).doc();
    const bookingId = bookingRef.id;

    const bookingData = {
      id: bookingId,
      coachId,
      facilityId,
      spaceId: spaceId || null,
      facilityOwnerId: facility.ownerId,
      facilityName: facility.name,
      facilityImage: facility.images?.[0] || null,
      facilityAddress: facility.address?.formattedAddress || null,
      startTime: admin.firestore.Timestamp.fromDate(startDate),
      endTime: admin.firestore.Timestamp.fromDate(endDate),
      durationHours,
      status: BOOKING_STATUS.PENDING,
      totalPrice: totalPrice.toNumber(),
      subtotal: subtotal.toNumber(),
      platformCommission: platformCommission.toNumber(),
      platformCommissionPercentage: PLATFORM_COMMISSION_RATE * 100,
      paymentStatus: PAYMENT_STATUS.PENDING,
      paymentMethod: null,
      stripePaymentIntentId: null,
      notes: notes || null,
      cancellationReason: null,
      cancellationInitiatedBy: null,
      cancelledAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      confirmedAt: null,
      completedAt: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      hasReview: false,
      reviewDeadline: null,
      reminderSentAt: null,
    };

    await bookingRef.set(bookingData);

    // Return booking info (Stripe PaymentIntent to be created by payments function)
    return {
      success: true,
      bookingId,
      totalPrice: totalPrice.toNumber(),
      subtotal: subtotal.toNumber(),
      platformCommission: platformCommission.toNumber(),
      startTime: startDate.toISOString(),
      endTime: endDate.toISOString(),
      durationHours,
    };
  }
);

/**
 * Confirm a booking after payment
 */
export const confirmBooking = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { bookingId } = data;
    if (!bookingId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de réservation requis');
    }

    const bookingRef = db.collection(COLLECTIONS.BOOKINGS).doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Réservation non trouvée');
    }

    const booking = bookingDoc.data()!;

    // Verify user is facility owner
    if (context.auth.uid !== booking.facilityOwnerId) {
      throw new functions.https.HttpsError('permission-denied', 'Action non autorisée');
    }

    // Verify booking is pending and paid
    if (booking.status !== BOOKING_STATUS.PENDING) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Cette réservation ne peut pas être confirmée'
      );
    }

    if (booking.paymentStatus !== PAYMENT_STATUS.SUCCEEDED) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Le paiement n\'a pas été effectué'
      );
    }

    // Update booking status
    await bookingRef.update({
      status: BOOKING_STATUS.CONFIRMED,
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update facility stats
    await db.collection(COLLECTIONS.FACILITIES).doc(booking.facilityId).update({
      totalBookings: admin.firestore.FieldValue.increment(1),
    });

    return {
      success: true,
      message: 'Réservation confirmée',
    };
  }
);

/**
 * Cancel a booking
 */
export const cancelBooking = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { error, value } = cancelBookingSchema.validate(data);
    if (error) {
      throw new functions.https.HttpsError('invalid-argument', error.details[0].message);
    }

    const { bookingId, reason } = value;
    const userId = context.auth.uid;

    const bookingRef = db.collection(COLLECTIONS.BOOKINGS).doc(bookingId);
    const bookingDoc = await bookingRef.get();

    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Réservation non trouvée');
    }

    const booking = bookingDoc.data()!;

    // Verify user can cancel (coach or facility owner)
    const isCoach = userId === booking.coachId;
    const isFacilityOwner = userId === booking.facilityOwnerId;

    if (!isCoach && !isFacilityOwner) {
      throw new functions.https.HttpsError('permission-denied', 'Action non autorisée');
    }

    // Verify booking can be cancelled
    if (![BOOKING_STATUS.PENDING, BOOKING_STATUS.CONFIRMED].includes(booking.status)) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Cette réservation ne peut pas être annulée'
      );
    }

    // Calculate refund based on cancellation policy
    const startTime = booking.startTime.toDate();
    const hoursUntilStart = (startTime.getTime() - Date.now()) / (1000 * 60 * 60);
    
    let refundRate = 0;
    if (hoursUntilStart > CANCELLATION_FULL_REFUND_HOURS) {
      refundRate = 1; // 100% refund
    } else if (hoursUntilStart > CANCELLATION_PARTIAL_REFUND_HOURS) {
      refundRate = CANCELLATION_PARTIAL_REFUND_RATE; // 25% refund
    }
    // else: no refund

    const refundAmount = booking.totalPrice * refundRate;

    // Update booking
    await bookingRef.update({
      status: BOOKING_STATUS.CANCELLED,
      cancellationReason: reason || null,
      cancellationInitiatedBy: isCoach ? 'coach' : 'facility',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      refundAmount,
      refundRate,
    });

    // If payment was made, initiate refund (handled by payment functions)
    if (booking.paymentStatus === PAYMENT_STATUS.SUCCEEDED && refundAmount > 0) {
      // Trigger refund process (implemented in payments.ts)
      await db.collection('refundRequests').add({
        bookingId,
        amount: refundAmount,
        originalAmount: booking.totalPrice,
        stripePaymentIntentId: booking.stripePaymentIntentId,
        initiatedBy: userId,
        reason,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      message: 'Réservation annulée',
      refundAmount,
      refundRate: refundRate * 100,
    };
  }
);

/**
 * Get user's bookings
 */
export const getUserBookings = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { status, limit = 20, startAfter } = data;
    const userId = context.auth.uid;

    // Get user type
    const userDoc = await db.collection(COLLECTIONS.USERS).doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Utilisateur non trouvé');
    }

    const userType = userDoc.data()!.type;
    const filterField = userType === 'coach' ? 'coachId' : 'facilityOwnerId';

    let query = db.collection(COLLECTIONS.BOOKINGS)
      .where(filterField, '==', userId)
      .orderBy('startTime', 'desc')
      .limit(limit);

    if (status) {
      query = query.where('status', '==', status);
    }

    if (startAfter) {
      const startAfterDoc = await db.collection(COLLECTIONS.BOOKINGS).doc(startAfter).get();
      if (startAfterDoc.exists) {
        query = query.startAfter(startAfterDoc);
      }
    }

    const snapshot = await query.get();

    const bookings = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      startTime: doc.data().startTime?.toDate().toISOString(),
      endTime: doc.data().endTime?.toDate().toISOString(),
      createdAt: doc.data().createdAt?.toDate().toISOString(),
    }));

    return {
      success: true,
      bookings,
      hasMore: snapshot.docs.length === limit,
    };
  }
);
