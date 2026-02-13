/**
 * Stripe Webhook Handler
 * 
 * Handles Stripe webhook events for payment processing
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
  apiVersion: '2023-10-16',
});

const endpointSecret = functions.config().stripe?.webhook_secret || process.env.STRIPE_WEBHOOK_SECRET || '';

/**
 * Stripe Webhook Endpoint
 * 
 * Listens for Stripe events and updates booking/payment status accordingly
 */
export const stripeWebhook = functions.region('europe-west1').https.onRequest(
  async (req, res) => {
    const sig = req.headers['stripe-signature'] as string;

    if (!sig) {
      console.error('No Stripe signature found');
      res.status(400).send('No signature');
      return;
    }

    let event: Stripe.Event;

    try {
      // Verify webhook signature
      event = stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
    } catch (err) {
      console.error('Webhook signature verification failed:', err);
      res.status(400).send(`Webhook Error: ${(err as Error).message}`);
      return;
    }

    console.log(`Received Stripe event: ${event.type}`);

    try {
      switch (event.type) {
        case 'payment_intent.succeeded':
          await handlePaymentSucceeded(event.data.object as Stripe.PaymentIntent);
          break;

        case 'payment_intent.payment_failed':
          await handlePaymentFailed(event.data.object as Stripe.PaymentIntent);
          break;

        case 'payment_intent.canceled':
          await handlePaymentCanceled(event.data.object as Stripe.PaymentIntent);
          break;

        case 'charge.refunded':
          await handleChargeRefunded(event.data.object as Stripe.Charge);
          break;

        case 'charge.dispute.created':
          await handleDisputeCreated(event.data.object as Stripe.Dispute);
          break;

        case 'customer.subscription.created':
        case 'customer.subscription.updated':
        case 'customer.subscription.deleted':
          // Handle subscription events if implementing premium features
          console.log('Subscription event:', event.type);
          break;

        default:
          console.log(`Unhandled event type: ${event.type}`);
      }

      res.status(200).send('Received');
    } catch (err) {
      console.error('Error processing webhook:', err);
      res.status(500).send('Processing error');
    }
  }
);

/**
 * Handle successful payment
 */
async function handlePaymentSucceeded(paymentIntent: Stripe.PaymentIntent): Promise<void> {
  console.log(`Payment succeeded: ${paymentIntent.id}`);

  const bookingId = paymentIntent.metadata?.bookingId;
  if (!bookingId) {
    console.error('No booking ID in payment intent metadata');
    return;
  }

  const bookingRef = db.collection(COLLECTIONS.BOOKINGS).doc(bookingId);
  const bookingDoc = await bookingRef.get();

  if (!bookingDoc.exists) {
    console.error(`Booking ${bookingId} not found`);
    return;
  }

  // Update booking status
  await bookingRef.update({
    paymentStatus: PAYMENT_STATUS.SUCCEEDED,
    status: BOOKING_STATUS.CONFIRMED, // Auto-confirm on payment
    confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    paymentMethod: paymentIntent.payment_method_types?.[0] || 'card',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Store payment details
  const booking = bookingDoc.data()!;
  
  await db.collection(COLLECTIONS.PAYMENTS).add({
    bookingId,
    stripePaymentIntentId: paymentIntent.id,
    stripeChargeId: paymentIntent.latest_charge as string,
    userId: booking.coachId,
    facilityOwnerId: booking.facilityOwnerId,
    amount: paymentIntent.amount / 100, // Convert from cents
    currency: paymentIntent.currency.toUpperCase(),
    platformCommission: booking.platformCommission,
    facilityAmount: booking.subtotal,
    status: PAYMENT_STATUS.SUCCEEDED,
    paymentMethod: paymentIntent.payment_method_types?.[0] || 'card',
    cardLast4: null, // Would need to retrieve from payment method
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Booking ${bookingId} confirmed with payment`);
}

/**
 * Handle failed payment
 */
async function handlePaymentFailed(paymentIntent: Stripe.PaymentIntent): Promise<void> {
  console.log(`Payment failed: ${paymentIntent.id}`);

  const bookingId = paymentIntent.metadata?.bookingId;
  if (!bookingId) {
    console.error('No booking ID in payment intent metadata');
    return;
  }

  const bookingRef = db.collection(COLLECTIONS.BOOKINGS).doc(bookingId);

  await bookingRef.update({
    paymentStatus: PAYMENT_STATUS.FAILED,
    paymentFailureReason: paymentIntent.last_payment_error?.message || 'Payment failed',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Booking ${bookingId} payment failed`);
}

/**
 * Handle canceled payment
 */
async function handlePaymentCanceled(paymentIntent: Stripe.PaymentIntent): Promise<void> {
  console.log(`Payment canceled: ${paymentIntent.id}`);

  const bookingId = paymentIntent.metadata?.bookingId;
  if (!bookingId) return;

  const bookingRef = db.collection(COLLECTIONS.BOOKINGS).doc(bookingId);
  const bookingDoc = await bookingRef.get();

  if (!bookingDoc.exists) return;

  // Only cancel if still pending
  const booking = bookingDoc.data()!;
  if (booking.status === BOOKING_STATUS.PENDING) {
    await bookingRef.update({
      status: BOOKING_STATUS.CANCELLED,
      cancellationReason: 'Paiement annulé',
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  console.log(`Booking ${bookingId} canceled due to payment cancellation`);
}

/**
 * Handle refunded charge
 */
async function handleChargeRefunded(charge: Stripe.Charge): Promise<void> {
  console.log(`Charge refunded: ${charge.id}`);

  // Find booking by charge ID
  const paymentsSnapshot = await db.collection(COLLECTIONS.PAYMENTS)
    .where('stripeChargeId', '==', charge.id)
    .limit(1)
    .get();

  if (paymentsSnapshot.empty) {
    console.error(`No payment found for charge ${charge.id}`);
    return;
  }

  const paymentDoc = paymentsSnapshot.docs[0];
  const payment = paymentDoc.data();
  const bookingId = payment.bookingId;

  // Calculate refund amount
  const refundedAmount = (charge.amount_refunded || 0) / 100;
  const isFullRefund = charge.refunded;

  // Update booking
  await db.collection(COLLECTIONS.BOOKINGS).doc(bookingId).update({
    paymentStatus: isFullRefund ? PAYMENT_STATUS.REFUNDED : PAYMENT_STATUS.SUCCEEDED,
    refundAmount: refundedAmount,
    refundDate: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Create refund record
  await db.collection(COLLECTIONS.PAYMENTS).add({
    bookingId,
    stripeChargeId: charge.id,
    stripeRefundId: charge.refunds?.data[0]?.id || null,
    userId: payment.userId,
    facilityOwnerId: payment.facilityOwnerId,
    type: 'refund',
    amount: refundedAmount,
    currency: charge.currency.toUpperCase(),
    status: 'succeeded',
    isPartialRefund: !isFullRefund,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Refund processed for booking ${bookingId}: ${refundedAmount} EUR`);
}

/**
 * Handle dispute created
 */
async function handleDisputeCreated(dispute: Stripe.Dispute): Promise<void> {
  console.log(`Dispute created: ${dispute.id}`);

  const chargeId = typeof dispute.charge === 'string' ? dispute.charge : dispute.charge?.id;
  
  if (!chargeId) {
    console.error('No charge ID in dispute');
    return;
  }

  // Find related payment
  const paymentsSnapshot = await db.collection(COLLECTIONS.PAYMENTS)
    .where('stripeChargeId', '==', chargeId)
    .limit(1)
    .get();

  if (paymentsSnapshot.empty) {
    console.error(`No payment found for charge ${chargeId}`);
    return;
  }

  const payment = paymentsSnapshot.docs[0].data();

  // Create dispute record for admin review
  await db.collection('disputes').add({
    stripeDisputeId: dispute.id,
    stripeChargeId: chargeId,
    bookingId: payment.bookingId,
    coachId: payment.userId,
    facilityOwnerId: payment.facilityOwnerId,
    amount: dispute.amount / 100,
    currency: dispute.currency.toUpperCase(),
    reason: dispute.reason,
    status: dispute.status,
    evidenceDueBy: dispute.evidence_details?.due_by 
      ? new Date(dispute.evidence_details.due_by * 1000) 
      : null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Notify admin (in production, send email)
  console.log(`Dispute requires attention: ${dispute.id} for ${dispute.amount / 100} ${dispute.currency}`);
}
