/**
 * Payment Functions (Stripe Integration)
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import {
  COLLECTIONS,
  PAYMENT_STATUS,
  BOOKING_STATUS,
} from '../config/constants';

const db = admin.firestore();

// Initialize Stripe
const stripe = new Stripe(functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2024-12-18.acacia',
});

/**
 * Create a Payment Intent for a booking
 */
export const createPaymentIntent = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { bookingId } = data;
    if (!bookingId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de réservation requis');
    }

    // Get booking
    const bookingDoc = await db.collection(COLLECTIONS.BOOKINGS).doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Réservation non trouvée');
    }

    const booking = bookingDoc.data()!;

    // Verify user owns this booking
    if (context.auth.uid !== booking.coachId) {
      throw new functions.https.HttpsError('permission-denied', 'Action non autorisée');
    }

    // Verify booking is pending payment
    if (booking.paymentStatus !== PAYMENT_STATUS.PENDING) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Cette réservation a déjà été payée'
      );
    }

    try {
      // Get or create Stripe customer
      const userDoc = await db.collection(COLLECTIONS.USERS).doc(context.auth.uid).get();
      const userData = userDoc.data()!;

      let customerId = userData.stripeCustomerId;
      
      if (!customerId) {
        const customer = await stripe.customers.create({
          email: userData.email,
          name: userData.displayName,
          metadata: {
            firebaseUid: context.auth.uid,
          },
        });
        customerId = customer.id;

        // Save customer ID
        await db.collection(COLLECTIONS.USERS).doc(context.auth.uid).update({
          stripeCustomerId: customerId,
        });
      }

      // Create Payment Intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(booking.totalPrice * 100), // Convert to cents
        currency: 'eur',
        customer: customerId,
        metadata: {
          bookingId,
          coachId: booking.coachId,
          facilityId: booking.facilityId,
          facilityOwnerId: booking.facilityOwnerId,
        },
        automatic_payment_methods: {
          enabled: true,
        },
        description: `Réservation ${bookingId} - ${booking.facilityName}`,
      });

      // Update booking with payment intent ID
      await db.collection(COLLECTIONS.BOOKINGS).doc(bookingId).update({
        stripePaymentIntentId: paymentIntent.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (err) {
      console.error('Error creating payment intent:', err);
      throw new functions.https.HttpsError('internal', 'Erreur lors de la création du paiement');
    }
  }
);

/**
 * Process a refund for a cancelled booking
 */
export const processRefund = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { bookingId, amount, reason } = data;
    if (!bookingId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de réservation requis');
    }

    // Get booking
    const bookingDoc = await db.collection(COLLECTIONS.BOOKINGS).doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Réservation non trouvée');
    }

    const booking = bookingDoc.data()!;

    // Verify booking can be refunded
    if (booking.status !== BOOKING_STATUS.CANCELLED) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Seules les réservations annulées peuvent être remboursées'
      );
    }

    if (!booking.stripePaymentIntentId) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Aucun paiement associé à cette réservation'
      );
    }

    try {
      // Create refund
      const refund = await stripe.refunds.create({
        payment_intent: booking.stripePaymentIntentId,
        amount: amount ? Math.round(amount * 100) : undefined, // Partial or full
        reason: 'requested_by_customer',
        metadata: {
          bookingId,
          reason: reason || 'Booking cancelled',
        },
      });

      // Update booking
      await db.collection(COLLECTIONS.BOOKINGS).doc(bookingId).update({
        paymentStatus: PAYMENT_STATUS.REFUNDED,
        refundAmount: refund.amount / 100,
        refundReason: reason,
        refundDate: admin.firestore.FieldValue.serverTimestamp(),
        stripeRefundId: refund.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create payment record
      await db.collection(COLLECTIONS.PAYMENTS).add({
        bookingId,
        userId: booking.coachId,
        facilityOwnerId: booking.facilityOwnerId,
        type: 'refund',
        amount: refund.amount / 100,
        currency: 'EUR',
        status: 'succeeded',
        stripeRefundId: refund.id,
        stripePaymentIntentId: booking.stripePaymentIntentId,
        reason,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        refundId: refund.id,
        amount: refund.amount / 100,
      };
    } catch (err) {
      console.error('Error processing refund:', err);
      throw new functions.https.HttpsError('internal', 'Erreur lors du remboursement');
    }
  }
);

/**
 * Get payment methods for a user
 */
export const getPaymentMethods = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const userDoc = await db.collection(COLLECTIONS.USERS).doc(context.auth.uid).get();
    const userData = userDoc.data();

    if (!userData?.stripeCustomerId) {
      return { success: true, paymentMethods: [] };
    }

    try {
      const paymentMethods = await stripe.paymentMethods.list({
        customer: userData.stripeCustomerId,
        type: 'card',
      });

      return {
        success: true,
        paymentMethods: paymentMethods.data.map((pm) => ({
          id: pm.id,
          brand: pm.card?.brand,
          last4: pm.card?.last4,
          expMonth: pm.card?.exp_month,
          expYear: pm.card?.exp_year,
        })),
      };
    } catch (err) {
      console.error('Error getting payment methods:', err);
      throw new functions.https.HttpsError('internal', 'Erreur lors de la récupération des cartes');
    }
  }
);

/**
 * Create Setup Intent for adding new payment method
 */
export const createSetupIntent = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const userDoc = await db.collection(COLLECTIONS.USERS).doc(context.auth.uid).get();
    const userData = userDoc.data()!;

    let customerId = userData.stripeCustomerId;

    // Create customer if doesn't exist
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userData.email,
        name: userData.displayName,
        metadata: {
          firebaseUid: context.auth.uid,
        },
      });
      customerId = customer.id;

      await db.collection(COLLECTIONS.USERS).doc(context.auth.uid).update({
        stripeCustomerId: customerId,
      });
    }

    try {
      const setupIntent = await stripe.setupIntents.create({
        customer: customerId,
        automatic_payment_methods: {
          enabled: true,
        },
      });

      return {
        success: true,
        clientSecret: setupIntent.client_secret,
      };
    } catch (err) {
      console.error('Error creating setup intent:', err);
      throw new functions.https.HttpsError('internal', 'Erreur lors de la configuration du paiement');
    }
  }
);

/**
 * Delete a payment method
 */
export const deletePaymentMethod = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { paymentMethodId } = data;
    if (!paymentMethodId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de la carte requis');
    }

    try {
      // Verify the payment method belongs to this user
      const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);
      const userDoc = await db.collection(COLLECTIONS.USERS).doc(context.auth.uid).get();
      const userData = userDoc.data();

      if (paymentMethod.customer !== userData?.stripeCustomerId) {
        throw new functions.https.HttpsError('permission-denied', 'Cette carte ne vous appartient pas');
      }

      await stripe.paymentMethods.detach(paymentMethodId);

      return { success: true };
    } catch (err) {
      console.error('Error deleting payment method:', err);
      throw new functions.https.HttpsError('internal', 'Erreur lors de la suppression de la carte');
    }
  }
);
