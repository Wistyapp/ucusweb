/**
 * Review Functions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as Joi from 'joi';
import {
  COLLECTIONS,
  REVIEW_TYPES,
  REVIEW_MIN_LENGTH,
  REVIEW_MAX_LENGTH,
  REVIEW_MAX_PHOTOS,
  REVIEW_DEADLINE_DAYS,
  BOOKING_STATUS,
} from '../config/constants';
import { sendNewReviewNotification } from './notifications';

const db = admin.firestore();

// Validation schemas
const createReviewSchema = Joi.object({
  bookingId: Joi.string().required(),
  revieweeId: Joi.string().required(),
  reviewType: Joi.string().valid(REVIEW_TYPES.COACH_TO_FACILITY, REVIEW_TYPES.FACILITY_TO_COACH).required(),
  overallRating: Joi.number().min(1).max(5).required(),
  comment: Joi.string().min(REVIEW_MIN_LENGTH).max(REVIEW_MAX_LENGTH).required(),
  categoryRatings: Joi.object().required(),
  photos: Joi.array().items(Joi.string().uri()).max(REVIEW_MAX_PHOTOS).optional(),
});

/**
 * Create a new review
 */
export const createReview = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    // Validate input
    const { error, value } = createReviewSchema.validate(data);
    if (error) {
      throw new functions.https.HttpsError('invalid-argument', error.details[0].message);
    }

    const { bookingId, revieweeId, reviewType, overallRating, comment, categoryRatings, photos } = value;
    const reviewerId = context.auth.uid;

    // Get booking
    const bookingDoc = await db.collection(COLLECTIONS.BOOKINGS).doc(bookingId).get();
    if (!bookingDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Réservation non trouvée');
    }

    const booking = bookingDoc.data()!;

    // Verify booking is completed
    if (booking.status !== BOOKING_STATUS.COMPLETED) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Vous ne pouvez laisser un avis que pour une réservation terminée'
      );
    }

    // Verify user is part of this booking
    const isCoach = reviewerId === booking.coachId;
    const isFacilityOwner = reviewerId === booking.facilityOwnerId;

    if (!isCoach && !isFacilityOwner) {
      throw new functions.https.HttpsError('permission-denied', 'Action non autorisée');
    }

    // Verify review type matches user role
    if (isCoach && reviewType !== REVIEW_TYPES.COACH_TO_FACILITY) {
      throw new functions.https.HttpsError('invalid-argument', 'Type d\'avis incorrect');
    }
    if (isFacilityOwner && reviewType !== REVIEW_TYPES.FACILITY_TO_COACH) {
      throw new functions.https.HttpsError('invalid-argument', 'Type d\'avis incorrect');
    }

    // Verify reviewee is correct
    const expectedRevieweeId = isCoach ? booking.facilityId : booking.coachId;
    if (revieweeId !== expectedRevieweeId && revieweeId !== booking.facilityOwnerId) {
      throw new functions.https.HttpsError('invalid-argument', 'Destinataire de l\'avis incorrect');
    }

    // Check review deadline (30 days after booking completion)
    const completedAt = booking.completedAt?.toDate() || booking.endTime.toDate();
    const deadline = new Date(completedAt.getTime() + REVIEW_DEADLINE_DAYS * 24 * 60 * 60 * 1000);
    if (new Date() > deadline) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Le délai pour laisser un avis est dépassé (30 jours)'
      );
    }

    // Check if review already exists
    const existingReview = await db.collection(COLLECTIONS.REVIEWS)
      .where('bookingId', '==', bookingId)
      .where('reviewerId', '==', reviewerId)
      .limit(1)
      .get();

    if (!existingReview.empty) {
      throw new functions.https.HttpsError(
        'already-exists',
        'Vous avez déjà laissé un avis pour cette réservation'
      );
    }

    // Get reviewer info
    const reviewerDoc = await db.collection(COLLECTIONS.USERS).doc(reviewerId).get();
    const reviewerData = reviewerDoc.data()!;

    // Create review
    const reviewRef = db.collection(COLLECTIONS.REVIEWS).doc();
    const reviewData = {
      id: reviewRef.id,
      bookingId,
      reviewerId,
      revieweeId,
      reviewerName: reviewerData.displayName,
      reviewerImage: reviewerData.profileImage,
      reviewType,
      overallRating,
      comment,
      categoryRatings,
      photos: photos || [],
      isVerified: false,
      isHidden: false,
      isReported: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await reviewRef.set(reviewData);

    // Update booking to mark as reviewed
    await db.collection(COLLECTIONS.BOOKINGS).doc(bookingId).update({
      hasReview: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update reviewee's rating
    await updateUserRating(revieweeId, reviewType);

    // Send notification to reviewee
    await sendNewReviewNotification(
      reviewType === REVIEW_TYPES.COACH_TO_FACILITY ? booking.facilityOwnerId : booking.coachId,
      reviewerData.displayName,
      overallRating,
      reviewRef.id
    );

    return {
      success: true,
      reviewId: reviewRef.id,
    };
  }
);

/**
 * Update user's average rating based on recent reviews
 */
async function updateUserRating(userId: string, reviewType: string): Promise<void> {
  // Get last 30 reviews for this user
  const reviewsSnapshot = await db.collection(COLLECTIONS.REVIEWS)
    .where('revieweeId', '==', userId)
    .where('reviewType', '==', reviewType)
    .where('isHidden', '==', false)
    .orderBy('createdAt', 'desc')
    .limit(30)
    .get();

  if (reviewsSnapshot.empty) return;

  // Calculate average rating
  let totalRating = 0;
  reviewsSnapshot.docs.forEach((doc) => {
    totalRating += doc.data().overallRating;
  });
  const averageRating = totalRating / reviewsSnapshot.size;

  // Update the appropriate profile
  if (reviewType === REVIEW_TYPES.FACILITY_TO_COACH) {
    // Update coach profile
    await db.collection(COLLECTIONS.COACH_PROFILES).doc(userId).update({
      rating: Math.round(averageRating * 10) / 10,
      reviewsCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    // Update facility
    const facilitiesSnapshot = await db.collection(COLLECTIONS.FACILITIES)
      .where('ownerId', '==', userId)
      .get();

    const batch = db.batch();
    facilitiesSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        rating: Math.round(averageRating * 10) / 10,
        reviewsCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
  }
}

/**
 * Get reviews for a user or facility
 */
export const getReviews = functions.region('europe-west1').https.onCall(
  async (data) => {
    const { userId, reviewType, limit = 20, startAfter } = data;

    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID utilisateur requis');
    }

    let query = db.collection(COLLECTIONS.REVIEWS)
      .where('revieweeId', '==', userId)
      .where('isHidden', '==', false)
      .orderBy('createdAt', 'desc')
      .limit(limit);

    if (reviewType) {
      query = query.where('reviewType', '==', reviewType);
    }

    if (startAfter) {
      const startAfterDoc = await db.collection(COLLECTIONS.REVIEWS).doc(startAfter).get();
      if (startAfterDoc.exists) {
        query = query.startAfter(startAfterDoc);
      }
    }

    const snapshot = await query.get();

    const reviews = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate().toISOString(),
    }));

    return {
      success: true,
      reviews,
      hasMore: snapshot.docs.length === limit,
    };
  }
);

/**
 * Report a review
 */
export const reportReview = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { reviewId, reason } = data;
    if (!reviewId || !reason) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de l\'avis et raison requis');
    }

    const reviewRef = db.collection(COLLECTIONS.REVIEWS).doc(reviewId);
    const reviewDoc = await reviewRef.get();

    if (!reviewDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Avis non trouvé');
    }

    // Create report
    await db.collection('reviewReports').add({
      reviewId,
      reporterId: context.auth.uid,
      reason,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
    });

    // Mark review as reported
    await reviewRef.update({
      isReported: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);

/**
 * Get review statistics for a user
 */
export const getReviewStats = functions.region('europe-west1').https.onCall(
  async (data) => {
    const { userId, reviewType } = data;

    if (!userId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID utilisateur requis');
    }

    let query = db.collection(COLLECTIONS.REVIEWS)
      .where('revieweeId', '==', userId)
      .where('isHidden', '==', false);

    if (reviewType) {
      query = query.where('reviewType', '==', reviewType);
    }

    const snapshot = await query.get();

    // Calculate stats
    const ratingCounts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    let totalRating = 0;

    snapshot.docs.forEach((doc) => {
      const rating = Math.round(doc.data().overallRating);
      ratingCounts[rating as keyof typeof ratingCounts]++;
      totalRating += doc.data().overallRating;
    });

    const totalReviews = snapshot.size;
    const averageRating = totalReviews > 0 ? totalRating / totalReviews : 0;

    return {
      success: true,
      stats: {
        totalReviews,
        averageRating: Math.round(averageRating * 10) / 10,
        ratingDistribution: ratingCounts,
      },
    };
  }
);
