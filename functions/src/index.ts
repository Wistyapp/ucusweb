



/**
 * UnCoachUneSalle - Cloud Functions
 *
 * Beta Version (sans paiements)
 */

import * as admin from 'firebase-admin';

admin.initializeApp();

// Auth functions
export * from './functions/auth';

// Bookings (sans paiement)
export * from './functions/bookings';

// Notifications
export * from './functions/notifications';

// Reviews
export * from './functions/reviews';

// Triggers
export * from './triggers/bookingTriggers';
export * from './triggers/reviewTriggers';
export * from './triggers/messageTriggers';

// BETA: Désactivé pour la v1
// export * from './functions/payments';
// export * from './functions/analytics';
// export * from './webhooks/stripeWebhook';

