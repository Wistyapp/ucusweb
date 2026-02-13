/**
 * Application Constants
 */

// Platform commission percentage (15%)
export const PLATFORM_COMMISSION_RATE = 0.15;

// Booking constraints
export const BOOKING_MIN_ADVANCE_HOURS = 24; // Must book at least 24h in advance
export const BOOKING_MAX_ADVANCE_DAYS = 90; // Can book up to 90 days in advance
export const BOOKING_MIN_DURATION_HOURS = 1;
export const BOOKING_MAX_DURATION_HOURS = 8;
export const BOOKING_MAX_PER_DAY = 5; // Max bookings per coach per day
export const BOOKING_MAX_CONCURRENT = 2; // Max concurrent pending bookings
export const BOOKING_MAX_PENDING = 10; // Max pending bookings awaiting payment

// Price constraints
export const MIN_BOOKING_PRICE = 15; // EUR
export const MAX_BOOKING_PRICE = 5000; // EUR

// Review constraints
export const REVIEW_DEADLINE_DAYS = 30; // Days after booking to leave a review
export const REVIEW_MIN_LENGTH = 20;
export const REVIEW_MAX_LENGTH = 1000;
export const REVIEW_MAX_PHOTOS = 5;

// Rate limits
export const RATE_LIMIT_AUTH_ATTEMPTS = 5; // Per hour
export const RATE_LIMIT_PASSWORD_RESET = 3; // Per hour
export const RATE_LIMIT_OTP = 3; // Per 10 minutes
export const RATE_LIMIT_SEARCH = 30; // Per minute
export const RATE_LIMIT_BOOKINGS = 10; // Per hour

// Cancellation policy
export const CANCELLATION_FULL_REFUND_HOURS = 48; // > 48h = 100% refund
export const CANCELLATION_PARTIAL_REFUND_HOURS = 24; // 24-48h = 25% refund
export const CANCELLATION_PARTIAL_REFUND_RATE = 0.25;

// Verification requirements
export const MIN_FACILITY_PHOTOS = 3;
export const MIN_DESCRIPTION_LENGTH = 100;
export const MIN_RATING_FOR_BOOKING = 2.0; // Coaches
export const MIN_FACILITY_RATING = 2.5;

// Notification types
export const NOTIFICATION_TYPES = {
  BOOKING_CREATED: 'booking_created',
  BOOKING_CONFIRMED: 'booking_confirmed',
  BOOKING_CANCELLED: 'booking_cancelled',
  BOOKING_REMINDER: 'booking_reminder',
  PAYMENT_RECEIVED: 'payment_received',
  PAYMENT_FAILED: 'payment_failed',
  NEW_MESSAGE: 'new_message',
  NEW_REVIEW: 'new_review',
  VERIFICATION_APPROVED: 'verification_approved',
  VERIFICATION_REJECTED: 'verification_rejected',
};

// Booking statuses
export const BOOKING_STATUS = {
  PENDING: 'pending',
  CONFIRMED: 'confirmed',
  IN_PROGRESS: 'in_progress',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
};

// Payment statuses
export const PAYMENT_STATUS = {
  PENDING: 'pending',
  SUCCEEDED: 'succeeded',
  FAILED: 'failed',
  REFUNDED: 'refunded',
};

// Review types
export const REVIEW_TYPES = {
  COACH_TO_FACILITY: 'coach_to_facility',
  FACILITY_TO_COACH: 'facility_to_coach',
};

// Collection names
export const COLLECTIONS = {
  USERS: 'users',
  COACH_PROFILES: 'coachProfiles',
  FACILITY_PROFILES: 'facilityProfiles',
  FACILITIES: 'facilities',
  SPACES: 'spaces',
  BOOKINGS: 'bookings',
  REVIEWS: 'reviews',
  MESSAGES: 'messages',
  PAYMENTS: 'payments',
  AVAILABILITY: 'availability',
  ANALYTICS: 'analytics',
  NOTIFICATIONS: 'notifications',
};

// Storage paths
export const STORAGE_PATHS = {
  FACILITY_IMAGES: 'facility-images',
  COACH_PROFILES: 'coach-profiles',
  FACILITY_DOCUMENTS: 'facility-documents',
  RECEIPTS: 'receipts',
  REVIEW_PHOTOS: 'review-photos',
  MESSAGE_ATTACHMENTS: 'message-attachments',
};
