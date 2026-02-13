/**
 * Review Triggers - Firestore document triggers for reviews
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  COLLECTIONS,
  REVIEW_TYPES,
} from '../config/constants';

const db = admin.firestore();

/**
 * Trigger when a review is created
 * Updates the reviewee's average rating
 */
export const onReviewCreated = functions.region('europe-west1')
  .firestore.document(`${COLLECTIONS.REVIEWS}/{reviewId}`)
  .onCreate(async (snap) => {
    const review = snap.data();
    
    console.log(`New review created for ${review.revieweeId}: ${review.overallRating} stars`);

    await updateRevieweeRating(review.revieweeId, review.reviewType);
  });

/**
 * Trigger when a review is deleted or hidden
 * Recalculates the reviewee's average rating
 */
export const onReviewDeleted = functions.region('europe-west1')
  .firestore.document(`${COLLECTIONS.REVIEWS}/{reviewId}`)
  .onDelete(async (snap) => {
    const review = snap.data();
    
    console.log(`Review deleted for ${review.revieweeId}`);

    await updateRevieweeRating(review.revieweeId, review.reviewType);
  });

/**
 * Trigger when a review is updated (e.g., hidden by moderation)
 */
export const onReviewUpdated = functions.region('europe-west1')
  .firestore.document(`${COLLECTIONS.REVIEWS}/{reviewId}`)
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    // If visibility changed, recalculate ratings
    if (before.isHidden !== after.isHidden) {
      console.log(`Review visibility changed: ${before.isHidden} -> ${after.isHidden}`);
      await updateRevieweeRating(after.revieweeId, after.reviewType);
    }
  });

/**
 * Helper function to update a user/facility's average rating
 */
async function updateRevieweeRating(revieweeId: string, reviewType: string): Promise<void> {
  // Get all visible reviews for this reviewee
  const reviewsSnapshot = await db.collection(COLLECTIONS.REVIEWS)
    .where('revieweeId', '==', revieweeId)
    .where('reviewType', '==', reviewType)
    .where('isHidden', '==', false)
    .get();

  let totalRating = 0;
  let categoryTotals: Record<string, number> = {};
  let categoryCounts: Record<string, number> = {};

  reviewsSnapshot.docs.forEach((doc) => {
    const review = doc.data();
    totalRating += review.overallRating;

    // Aggregate category ratings
    if (review.categoryRatings) {
      Object.entries(review.categoryRatings).forEach(([category, rating]) => {
        categoryTotals[category] = (categoryTotals[category] || 0) + (rating as number);
        categoryCounts[category] = (categoryCounts[category] || 0) + 1;
      });
    }
  });

  const reviewsCount = reviewsSnapshot.size;
  const averageRating = reviewsCount > 0 ? Math.round((totalRating / reviewsCount) * 10) / 10 : 0;

  // Calculate category averages
  const categoryAverages: Record<string, number> = {};
  Object.keys(categoryTotals).forEach((category) => {
    categoryAverages[category] = Math.round((categoryTotals[category] / categoryCounts[category]) * 10) / 10;
  });

  // Update the appropriate profile based on review type
  if (reviewType === REVIEW_TYPES.FACILITY_TO_COACH) {
    // Update coach profile
    await db.collection(COLLECTIONS.COACH_PROFILES).doc(revieweeId).update({
      rating: averageRating,
      reviewsCount,
      categoryRatings: categoryAverages,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    // Update facility or facility owner
    // First, try to update as a facility
    const facilityDoc = await db.collection(COLLECTIONS.FACILITIES).doc(revieweeId).get();
    
    if (facilityDoc.exists) {
      await db.collection(COLLECTIONS.FACILITIES).doc(revieweeId).update({
        rating: averageRating,
        reviewsCount,
        categoryRatings: categoryAverages,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      // It's a facility owner ID - update all their facilities
      const facilitiesSnapshot = await db.collection(COLLECTIONS.FACILITIES)
        .where('ownerId', '==', revieweeId)
        .get();

      const batch = db.batch();
      facilitiesSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          rating: averageRating,
          reviewsCount,
          categoryRatings: categoryAverages,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Also update facility profile
      batch.update(db.collection(COLLECTIONS.FACILITY_PROFILES).doc(revieweeId), {
        rating: averageRating,
        reviewsCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      await batch.commit();
    }
  }

  console.log(`Updated rating for ${revieweeId}: ${averageRating} (${reviewsCount} reviews)`);
}

/**
 * Scheduled function to send review reminders
 * Reminds users to leave reviews for bookings completed 7 days ago
 */
export const sendReviewReminders = functions.region('europe-west1')
  .pubsub.schedule('0 10 * * *') // Every day at 10 AM
  .timeZone('Europe/Paris')
  .onRun(async () => {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const sevenDaysAgoEnd = new Date(sevenDaysAgo);
    sevenDaysAgoEnd.setHours(23, 59, 59, 999);

    // Find bookings completed exactly 7 days ago without reviews
    const bookingsSnapshot = await db.collection(COLLECTIONS.BOOKINGS)
      .where('status', '==', 'completed')
      .where('hasReview', '==', false)
      .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .where('completedAt', '<=', admin.firestore.Timestamp.fromDate(sevenDaysAgoEnd))
      .get();

    let remindersSent = 0;

    for (const doc of bookingsSnapshot.docs) {
      const booking = doc.data();

      // Check if coach has reviewed
      const coachReview = await db.collection(COLLECTIONS.REVIEWS)
        .where('bookingId', '==', doc.id)
        .where('reviewerId', '==', booking.coachId)
        .limit(1)
        .get();

      if (coachReview.empty) {
        // Send reminder to coach
        await db.collection(COLLECTIONS.NOTIFICATIONS).add({
          userId: booking.coachId,
          type: 'review_reminder',
          title: 'N\'oubliez pas de laisser un avis 📝',
          body: `Partagez votre expérience à ${booking.facilityName}`,
          data: { bookingId: doc.id },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        remindersSent++;
      }

      // Check if facility owner has reviewed
      const facilityReview = await db.collection(COLLECTIONS.REVIEWS)
        .where('bookingId', '==', doc.id)
        .where('reviewerId', '==', booking.facilityOwnerId)
        .limit(1)
        .get();

      if (facilityReview.empty) {
        // Send reminder to facility owner
        await db.collection(COLLECTIONS.NOTIFICATIONS).add({
          userId: booking.facilityOwnerId,
          type: 'review_reminder',
          title: 'N\'oubliez pas de laisser un avis 📝',
          body: 'Partagez votre expérience avec ce coach',
          data: { bookingId: doc.id },
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        remindersSent++;
      }
    }

    console.log(`Sent ${remindersSent} review reminders`);
  });
