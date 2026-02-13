/**
 * Analytics Functions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import {
  COLLECTIONS,
  BOOKING_STATUS,
} from '../config/constants';

const db = admin.firestore();

/**
 * Get facility analytics
 */
export const getFacilityAnalytics = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { facilityId, period = 'month' } = data;
    if (!facilityId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de salle requis');
    }

    // Verify user owns this facility
    const facilityDoc = await db.collection(COLLECTIONS.FACILITIES).doc(facilityId).get();
    if (!facilityDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Salle non trouvée');
    }

    const facility = facilityDoc.data()!;
    if (context.auth.uid !== facility.ownerId) {
      throw new functions.https.HttpsError('permission-denied', 'Action non autorisée');
    }

    // Calculate date range
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'year':
        startDate = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
        break;
      case 'month':
      default:
        startDate = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
    }

    // Get bookings for the period
    const bookingsSnapshot = await db.collection(COLLECTIONS.BOOKINGS)
      .where('facilityId', '==', facilityId)
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
      .get();

    // Calculate metrics
    let totalBookings = 0;
    let completedBookings = 0;
    let cancelledBookings = 0;
    let totalRevenue = 0;
    let totalHours = 0;
    const uniqueCoaches = new Set<string>();
    const revenueByDay: Record<string, number> = {};
    const bookingsByDay: Record<string, number> = {};

    bookingsSnapshot.docs.forEach((doc) => {
      const booking = doc.data();
      totalBookings++;

      if (booking.status === BOOKING_STATUS.COMPLETED) {
        completedBookings++;
        totalRevenue += booking.subtotal || 0; // Revenue excluding platform commission
        totalHours += booking.durationHours || 0;
      }

      if (booking.status === BOOKING_STATUS.CANCELLED) {
        cancelledBookings++;
      }

      uniqueCoaches.add(booking.coachId);

      // Group by day
      const dayKey = booking.createdAt?.toDate().toISOString().split('T')[0];
      if (dayKey) {
        revenueByDay[dayKey] = (revenueByDay[dayKey] || 0) + (booking.subtotal || 0);
        bookingsByDay[dayKey] = (bookingsByDay[dayKey] || 0) + 1;
      }
    });

    // Get reviews for the period
    const reviewsSnapshot = await db.collection(COLLECTIONS.REVIEWS)
      .where('revieweeId', '==', facilityId)
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
      .get();

    let totalRating = 0;
    reviewsSnapshot.docs.forEach((doc) => {
      totalRating += doc.data().overallRating;
    });
    const averageRating = reviewsSnapshot.size > 0 ? totalRating / reviewsSnapshot.size : facility.rating;

    // Calculate rates
    const completionRate = totalBookings > 0 ? (completedBookings / totalBookings) * 100 : 0;
    const cancellationRate = totalBookings > 0 ? (cancelledBookings / totalBookings) * 100 : 0;
    const averageBookingValue = completedBookings > 0 ? totalRevenue / completedBookings : 0;
    const averageHoursPerBooking = completedBookings > 0 ? totalHours / completedBookings : 0;

    return {
      success: true,
      analytics: {
        period,
        startDate: startDate.toISOString(),
        endDate: now.toISOString(),
        summary: {
          totalBookings,
          completedBookings,
          cancelledBookings,
          totalRevenue: Math.round(totalRevenue * 100) / 100,
          totalHours: Math.round(totalHours * 10) / 10,
          uniqueCoaches: uniqueCoaches.size,
          averageRating: Math.round(averageRating * 10) / 10,
          newReviews: reviewsSnapshot.size,
        },
        rates: {
          completionRate: Math.round(completionRate * 10) / 10,
          cancellationRate: Math.round(cancellationRate * 10) / 10,
          averageBookingValue: Math.round(averageBookingValue * 100) / 100,
          averageHoursPerBooking: Math.round(averageHoursPerBooking * 10) / 10,
        },
        charts: {
          revenueByDay,
          bookingsByDay,
        },
      },
    };
  }
);

/**
 * Get coach analytics
 */
export const getCoachAnalytics = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { period = 'month' } = data;
    const coachId = context.auth.uid;

    // Calculate date range
    const now = new Date();
    let startDate: Date;

    switch (period) {
      case 'week':
        startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        break;
      case 'year':
        startDate = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
        break;
      case 'month':
      default:
        startDate = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
    }

    // Get bookings for the period
    const bookingsSnapshot = await db.collection(COLLECTIONS.BOOKINGS)
      .where('coachId', '==', coachId)
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
      .get();

    // Calculate metrics
    let totalBookings = 0;
    let completedSessions = 0;
    let cancelledBookings = 0;
    let totalSpent = 0;
    let totalHours = 0;
    const facilitiesVisited = new Set<string>();
    const spendingByDay: Record<string, number> = {};

    bookingsSnapshot.docs.forEach((doc) => {
      const booking = doc.data();
      totalBookings++;

      if (booking.status === BOOKING_STATUS.COMPLETED) {
        completedSessions++;
        totalSpent += booking.totalPrice || 0;
        totalHours += booking.durationHours || 0;
        facilitiesVisited.add(booking.facilityId);
      }

      if (booking.status === BOOKING_STATUS.CANCELLED) {
        cancelledBookings++;
      }

      // Group by day
      const dayKey = booking.createdAt?.toDate().toISOString().split('T')[0];
      if (dayKey && booking.status === BOOKING_STATUS.COMPLETED) {
        spendingByDay[dayKey] = (spendingByDay[dayKey] || 0) + (booking.totalPrice || 0);
      }
    });

    // Get reviews received
    const reviewsSnapshot = await db.collection(COLLECTIONS.REVIEWS)
      .where('revieweeId', '==', coachId)
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
      .get();

    let totalRating = 0;
    reviewsSnapshot.docs.forEach((doc) => {
      totalRating += doc.data().overallRating;
    });

    // Get coach profile for overall rating
    const coachDoc = await db.collection(COLLECTIONS.COACH_PROFILES).doc(coachId).get();
    const coachData = coachDoc.data() || {};
    const averageRating = reviewsSnapshot.size > 0 
      ? totalRating / reviewsSnapshot.size 
      : coachData.rating || 0;

    // Calculate rates
    const completionRate = totalBookings > 0 ? (completedSessions / totalBookings) * 100 : 0;
    const averageSessionCost = completedSessions > 0 ? totalSpent / completedSessions : 0;
    const averageHoursPerSession = completedSessions > 0 ? totalHours / completedSessions : 0;

    return {
      success: true,
      analytics: {
        period,
        startDate: startDate.toISOString(),
        endDate: now.toISOString(),
        summary: {
          totalBookings,
          completedSessions,
          cancelledBookings,
          totalSpent: Math.round(totalSpent * 100) / 100,
          totalHours: Math.round(totalHours * 10) / 10,
          facilitiesVisited: facilitiesVisited.size,
          averageRating: Math.round(averageRating * 10) / 10,
          reviewsReceived: reviewsSnapshot.size,
        },
        rates: {
          completionRate: Math.round(completionRate * 10) / 10,
          averageSessionCost: Math.round(averageSessionCost * 100) / 100,
          averageHoursPerSession: Math.round(averageHoursPerSession * 10) / 10,
        },
        charts: {
          spendingByDay,
        },
      },
    };
  }
);

/**
 * Update analytics daily (scheduled function)
 */
export const updateDailyAnalytics = functions.region('europe-west1')
  .pubsub.schedule('0 2 * * *') // Every day at 2 AM
  .timeZone('Europe/Paris')
  .onRun(async () => {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const yearMonth = `${yesterday.getFullYear()}-${String(yesterday.getMonth() + 1).padStart(2, '0')}`;

    // Get all facilities
    const facilitiesSnapshot = await db.collection(COLLECTIONS.FACILITIES).get();

    for (const facilityDoc of facilitiesSnapshot.docs) {
      const facilityId = facilityDoc.id;

      // Get yesterday's bookings for this facility
      const bookingsSnapshot = await db.collection(COLLECTIONS.BOOKINGS)
        .where('facilityId', '==', facilityId)
        .where('completedAt', '>=', admin.firestore.Timestamp.fromDate(yesterday))
        .where('completedAt', '<', admin.firestore.Timestamp.fromDate(today))
        .where('status', '==', BOOKING_STATUS.COMPLETED)
        .get();

      let dayRevenue = 0;
      let dayBookings = 0;
      let dayHours = 0;
      const coaches = new Set<string>();

      bookingsSnapshot.docs.forEach((doc) => {
        const booking = doc.data();
        dayRevenue += booking.subtotal || 0;
        dayBookings++;
        dayHours += booking.durationHours || 0;
        coaches.add(booking.coachId);
      });

      // Update or create analytics document
      const analyticsRef = db.collection(COLLECTIONS.ANALYTICS).doc(`${facilityId}_stats`);
      const analyticsDoc = await analyticsRef.get();

      if (analyticsDoc.exists) {
        const currentData = analyticsDoc.data()!;
        const monthlyMetrics = currentData.monthlyMetrics || {};
        const currentMonth = monthlyMetrics[yearMonth] || {
          bookings: 0,
          revenue: 0,
          totalHours: 0,
          uniqueCoaches: 0,
        };

        await analyticsRef.update({
          totalBookings: admin.firestore.FieldValue.increment(dayBookings),
          totalRevenue: admin.firestore.FieldValue.increment(dayRevenue),
          [`monthlyMetrics.${yearMonth}.bookings`]: currentMonth.bookings + dayBookings,
          [`monthlyMetrics.${yearMonth}.revenue`]: currentMonth.revenue + dayRevenue,
          [`monthlyMetrics.${yearMonth}.totalHours`]: currentMonth.totalHours + dayHours,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await analyticsRef.set({
          id: `${facilityId}_stats`,
          facilityId,
          totalBookings: dayBookings,
          totalRevenue: dayRevenue,
          totalPlatformCommission: dayRevenue * 0.15,
          averageRating: facilityDoc.data().rating || 0,
          totalReviews: facilityDoc.data().reviewsCount || 0,
          monthlyMetrics: {
            [yearMonth]: {
              bookings: dayBookings,
              revenue: dayRevenue,
              totalHours: dayHours,
              uniqueCoaches: coaches.size,
            },
          },
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    console.log('Daily analytics updated');
  });
