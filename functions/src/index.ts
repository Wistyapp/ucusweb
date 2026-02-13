/**
 * UnCoachUneSalle - Cloud Functions
 * 
 * Main entry point for all Firebase Cloud Functions
 * 
 * @version 1.0.0
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

// Export all functions
export * from './functions/auth';
export * from './functions/bookings';
export * from './functions/payments';
export * from './functions/notifications';
export * from './functions/reviews';
export * from './functions/analytics';
export * from './triggers/bookingTriggers';
export * from './triggers/reviewTriggers';
export * from './triggers/messageTriggers';
export * from './webhooks/stripeWebhook';
