/**
 * Authentication Functions
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as Joi from 'joi';
import { COLLECTIONS } from '../config/constants';

const db = admin.firestore();

// Validation schemas
const signupSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(8).pattern(/(?=.*[A-Z])(?=.*[0-9])/).required(),
  displayName: Joi.string().min(2).max(50).required(),
  userType: Joi.string().valid('coach', 'facility').required(),
  phoneNumber: Joi.string().pattern(/^\+33[0-9]{9}$/).optional(),
  agreeToTerms: Joi.boolean().valid(true).required(),
});

const passwordResetSchema = Joi.object({
  email: Joi.string().email().required(),
});

/**
 * Create a new user account
 */
export const createUser = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    try {
      // Validate input
      const { error, value } = signupSchema.validate(data);
      if (error) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          error.details[0].message
        );
      }

      const { email, password, displayName, userType, phoneNumber } = value;

      // Check if email already exists
      try {
        await admin.auth().getUserByEmail(email);
        throw new functions.https.HttpsError(
          'already-exists',
          'Un compte existe déjà avec cet email'
        );
      } catch (err: unknown) {
        if ((err as {code?: string}).code !== 'auth/user-not-found') {
          throw err;
        }
      }

      // Create user in Firebase Auth
      const userRecord = await admin.auth().createUser({
        email,
        password,
        displayName,
        phoneNumber,
        emailVerified: false,
      });

      // Create user document in Firestore
      const userData = {
        uid: userRecord.uid,
        email,
        displayName,
        type: userType,
        phoneNumber: phoneNumber || null,
        profileImage: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
        verification: {
          identity: false,
          insurance: false,
          license: false,
          backgroundCheck: false,
        },
        fcmToken: null,
        notificationPreferences: {
          bookings: true,
          messages: true,
          reviews: true,
          marketing: false,
        },
      };

      await db.collection(COLLECTIONS.USERS).doc(userRecord.uid).set(userData);

      // Create type-specific profile
      if (userType === 'coach') {
        await db.collection(COLLECTIONS.COACH_PROFILES).doc(userRecord.uid).set({
          id: userRecord.uid,
          userId: userRecord.uid,
          bio: '',
          specialties: [],
          certifications: [],
          hourlyRate: 0,
          minimumDuration: 1,
          availableHours: {},
          totalSessions: 0,
          rating: 0,
          reviewsCount: 0,
          clientsCount: 0,
          responseTime: 0,
          acceptanceRate: 0,
          cancellationRate: 0,
          preferredFacilityTypes: [],
          preferredAmenities: [],
          languages: ['fr'],
          isVerified: false,
          isFeatured: false,
          isSuspended: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        await db.collection(COLLECTIONS.FACILITY_PROFILES).doc(userRecord.uid).set({
          id: userRecord.uid,
          userId: userRecord.uid,
          facilityName: '',
          address: null,
          description: '',
          websiteUrl: null,
          capacity: 0,
          amenities: [],
          equipmentList: [],
          hourlyRate: 0,
          peakHourRate: 0,
          peakHours: [],
          minimumBookingDuration: 1,
          images: [],
          businessLicense: null,
          insuranceDocument: null,
          totalBookings: 0,
          rating: 0,
          reviewsCount: 0,
          responseTime: 0,
          acceptanceRate: 0,
          cancellationRate: 0,
          operatingHours: {},
          isVerified: false,
          isFeatured: false,
          isSuspended: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Set custom claims for user type
      await admin.auth().setCustomUserClaims(userRecord.uid, { userType });

      // Send verification email
      const verificationLink = await admin.auth().generateEmailVerificationLink(email);
      // In production, send this via SendGrid
      console.log('Verification link:', verificationLink);

      return {
        success: true,
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: userRecord.displayName,
        userType,
      };
    } catch (err) {
      console.error('Error creating user:', err);
      if (err instanceof functions.https.HttpsError) {
        throw err;
      }
      throw new functions.https.HttpsError('internal', 'Erreur lors de la création du compte');
    }
  }
);

/**
 * Send password reset email
 */
export const sendPasswordReset = functions.region('europe-west1').https.onCall(
  async (data) => {
    try {
      const { error, value } = passwordResetSchema.validate(data);
      if (error) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          error.details[0].message
        );
      }

      const { email } = value;

      // Generate reset link
      const resetLink = await admin.auth().generatePasswordResetLink(email);
      
      // In production, send via SendGrid
      console.log('Password reset link:', resetLink);

      return {
        success: true,
        message: 'Email de réinitialisation envoyé',
      };
    } catch (err) {
      console.error('Error sending password reset:', err);
      // Don't reveal if email exists for security
      return {
        success: true,
        message: 'Si un compte existe avec cet email, un lien de réinitialisation a été envoyé',
      };
    }
  }
);

/**
 * Update FCM token for push notifications
 */
export const updateFcmToken = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { fcmToken } = data;
    if (!fcmToken) {
      throw new functions.https.HttpsError('invalid-argument', 'Token FCM requis');
    }

    await db.collection(COLLECTIONS.USERS).doc(context.auth.uid).update({
      fcmToken,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);

/**
 * Delete user account (GDPR compliance)
 */
export const deleteUserAccount = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { reason } = data;
    const uid = context.auth.uid;

    try {
      // Get user data for archiving
      const userDoc = await db.collection(COLLECTIONS.USERS).doc(uid).get();
      const userData = userDoc.data();

      // Archive user data before deletion (for legal compliance)
      await db.collection('deletedUsers').doc(uid).set({
        ...userData,
        deletionReason: reason || 'User requested',
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Soft delete user document
      await db.collection(COLLECTIONS.USERS).doc(uid).update({
        isActive: false,
        deletedAt: admin.firestore.FieldValue.serverTimestamp(),
        email: `deleted_${uid}@deleted.com`,
        displayName: 'Utilisateur supprimé',
        phoneNumber: null,
        profileImage: null,
      });

      // Anonymize reviews (keep for integrity)
      const reviewsSnapshot = await db.collection(COLLECTIONS.REVIEWS)
        .where('reviewerId', '==', uid)
        .get();

      const batch = db.batch();
      reviewsSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          reviewerName: 'Utilisateur supprimé',
          reviewerImage: null,
        });
      });
      await batch.commit();

      // Delete from Firebase Auth
      await admin.auth().deleteUser(uid);

      return {
        success: true,
        message: 'Compte supprimé avec succès',
      };
    } catch (err) {
      console.error('Error deleting user:', err);
      throw new functions.https.HttpsError('internal', 'Erreur lors de la suppression du compte');
    }
  }
);
