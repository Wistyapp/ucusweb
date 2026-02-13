/**
 * Message Triggers - Firestore document triggers for messaging
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { COLLECTIONS } from '../config/constants';
import { sendNewMessageNotification } from '../functions/notifications';

const db = admin.firestore();

/**
 * Trigger when a new message is sent
 * - Updates conversation's last message info
 * - Sends push notification to recipient
 */
export const onMessageSent = functions.region('europe-west1')
  .firestore.document(`${COLLECTIONS.MESSAGES}/{conversationId}/messages/{messageId}`)
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const conversationId = context.params.conversationId;
    
    console.log(`New message in conversation ${conversationId}`);

    const conversationRef = db.collection(COLLECTIONS.MESSAGES).doc(conversationId);
    const conversationDoc = await conversationRef.get();

    if (!conversationDoc.exists) {
      console.error(`Conversation ${conversationId} not found`);
      return;
    }

    const conversation = conversationDoc.data()!;
    const participants = conversation.participants || [];
    
    // Find recipient (the other participant)
    const recipientId = participants.find((p: string) => p !== message.senderId);
    
    if (!recipientId) {
      console.error('Recipient not found in conversation');
      return;
    }

    // Update conversation with last message info
    const unreadCount = conversation.unreadCount || {};
    unreadCount[recipientId] = (unreadCount[recipientId] || 0) + 1;

    await conversationRef.update({
      lastMessage: message.text || (message.attachments?.length > 0 ? '📎 Pièce jointe' : ''),
      lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
      lastMessageSenderId: message.senderId,
      unreadCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send push notification to recipient
    await sendNewMessageNotification(
      recipientId,
      message.senderName || 'Quelqu\'un',
      message.text || 'Nouvelle pièce jointe',
      conversationId
    );
  });

/**
 * Trigger when a message is read
 * - Updates unread count in conversation
 */
export const onMessageRead = functions.region('europe-west1')
  .firestore.document(`${COLLECTIONS.MESSAGES}/{conversationId}/messages/{messageId}`)
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const conversationId = context.params.conversationId;

    // Check if message was just marked as read
    if (!before.isRead && after.isRead) {
      console.log(`Message marked as read in conversation ${conversationId}`);

      const conversationRef = db.collection(COLLECTIONS.MESSAGES).doc(conversationId);
      const conversationDoc = await conversationRef.get();

      if (!conversationDoc.exists) return;

      const conversation = conversationDoc.data()!;
      const unreadCount = conversation.unreadCount || {};
      
      // Get the reader (not the sender)
      const readerId = Object.keys(unreadCount).find((uid) => uid !== after.senderId);
      
      if (readerId && unreadCount[readerId] > 0) {
        unreadCount[readerId] = Math.max(0, unreadCount[readerId] - 1);

        await conversationRef.update({
          unreadCount,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
  });

/**
 * Create or get a conversation between two users
 */
export const getOrCreateConversation = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { otherUserId } = data;
    if (!otherUserId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de l\'autre utilisateur requis');
    }

    const currentUserId = context.auth.uid;

    // Check if conversation already exists
    const existingConversation = await db.collection(COLLECTIONS.MESSAGES)
      .where('participants', 'array-contains', currentUserId)
      .get();

    const existing = existingConversation.docs.find((doc) => {
      const participants = doc.data().participants || [];
      return participants.includes(otherUserId);
    });

    if (existing) {
      return {
        success: true,
        conversationId: existing.id,
        isNew: false,
      };
    }

    // Get user info for both participants
    const [currentUserDoc, otherUserDoc] = await Promise.all([
      db.collection(COLLECTIONS.USERS).doc(currentUserId).get(),
      db.collection(COLLECTIONS.USERS).doc(otherUserId).get(),
    ]);

    if (!otherUserDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Utilisateur non trouvé');
    }

    const currentUser = currentUserDoc.data()!;
    const otherUser = otherUserDoc.data()!;

    // Create new conversation
    const conversationRef = db.collection(COLLECTIONS.MESSAGES).doc();
    
    await conversationRef.set({
      id: conversationRef.id,
      participants: [currentUserId, otherUserId],
      participantInfo: {
        [currentUserId]: {
          name: currentUser.displayName,
          profileImage: currentUser.profileImage,
        },
        [otherUserId]: {
          name: otherUser.displayName,
          profileImage: otherUser.profileImage,
        },
      },
      lastMessage: '',
      lastMessageTime: null,
      lastMessageSenderId: null,
      unreadCount: {
        [currentUserId]: 0,
        [otherUserId]: 0,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      conversationId: conversationRef.id,
      isNew: true,
    };
  }
);

/**
 * Send a message in a conversation
 */
export const sendMessage = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { conversationId, text, attachments } = data;
    
    if (!conversationId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de conversation requis');
    }

    if (!text && (!attachments || attachments.length === 0)) {
      throw new functions.https.HttpsError('invalid-argument', 'Message ou pièce jointe requis');
    }

    const senderId = context.auth.uid;

    // Verify user is part of this conversation
    const conversationDoc = await db.collection(COLLECTIONS.MESSAGES).doc(conversationId).get();
    
    if (!conversationDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Conversation non trouvée');
    }

    const conversation = conversationDoc.data()!;
    if (!conversation.participants.includes(senderId)) {
      throw new functions.https.HttpsError('permission-denied', 'Vous ne faites pas partie de cette conversation');
    }

    // Get sender info
    const senderDoc = await db.collection(COLLECTIONS.USERS).doc(senderId).get();
    const sender = senderDoc.data()!;

    // Create message
    const messageRef = db.collection(COLLECTIONS.MESSAGES)
      .doc(conversationId)
      .collection('messages')
      .doc();

    const messageData = {
      id: messageRef.id,
      conversationId,
      senderId,
      senderName: sender.displayName,
      senderProfileImage: sender.profileImage,
      text: text || '',
      attachments: attachments || [],
      isRead: false,
      readAt: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await messageRef.set(messageData);

    return {
      success: true,
      messageId: messageRef.id,
    };
  }
);

/**
 * Mark messages as read
 */
export const markMessagesRead = functions.region('europe-west1').https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentification requise');
    }

    const { conversationId } = data;
    
    if (!conversationId) {
      throw new functions.https.HttpsError('invalid-argument', 'ID de conversation requis');
    }

    const userId = context.auth.uid;

    // Get unread messages in this conversation
    const unreadMessages = await db.collection(COLLECTIONS.MESSAGES)
      .doc(conversationId)
      .collection('messages')
      .where('senderId', '!=', userId)
      .where('isRead', '==', false)
      .get();

    if (unreadMessages.empty) {
      return { success: true, markedCount: 0 };
    }

    // Mark all as read
    const batch = db.batch();
    unreadMessages.docs.forEach((doc) => {
      batch.update(doc.ref, {
        isRead: true,
        readAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    // Reset unread count for this user
    batch.update(db.collection(COLLECTIONS.MESSAGES).doc(conversationId), {
      [`unreadCount.${userId}`]: 0,
    });

    await batch.commit();

    return {
      success: true,
      markedCount: unreadMessages.size,
    };
  }
);
