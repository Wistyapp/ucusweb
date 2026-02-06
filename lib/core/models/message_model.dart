import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ConversationModel extends Equatable {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Denormalized data
  final Map<String, ParticipantInfo>? participantsInfo;

  const ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.lastMessageSenderId = '',
    this.unreadCount = const {},
    required this.createdAt,
    required this.updatedAt,
    this.participantsInfo,
  });

  int getUnreadCountFor(String userId) => unreadCount[userId] ?? 0;

  ParticipantInfo? getOtherParticipant(String currentUserId) {
    if (participantsInfo == null) return null;
    final otherId = participants.firstWhere(
          (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantsInfo![otherId];
  }

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<String, ParticipantInfo>? participantsInfo;
    if (data['participantsInfo'] != null) {
      participantsInfo = {};
      (data['participantsInfo'] as Map<String, dynamic>).forEach((key, value) {
        participantsInfo![key] = ParticipantInfo.fromMap(value);
      });
    }

    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      participantsInfo: participantsInfo,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (participantsInfo != null)
        'participantsInfo': participantsInfo!.map(
              (key, value) => MapEntry(key, value.toMap()),
        ),
    };
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, ParticipantInfo>? participantsInfo,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participantsInfo: participantsInfo ?? this.participantsInfo,
    );
  }

  @override
  List<Object?> get props => [id, participants, lastMessageTime];
}

class ParticipantInfo extends Equatable {
  final String displayName;
  final String? profileImage;
  final String userType;

  const ParticipantInfo({
    required this.displayName,
    this.profileImage,
    required this.userType,
  });

  factory ParticipantInfo.fromMap(Map<String, dynamic> map) {
    return ParticipantInfo(
      displayName: map['displayName'] ?? '',
      profileImage: map['profileImage'],
      userType: map['userType'] ?? 'coach',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'profileImage': profileImage,
      'userType': userType,
    };
  }

  @override
  List<Object?> get props => [displayName, profileImage, userType];
}

class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderProfileImage;
  final String text;
  final List<Attachment> attachments;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? editedAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderProfileImage,
    required this.text,
    this.attachments = const [],
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.editedAt,
  });

  bool get hasAttachments => attachments.isNotEmpty;
  bool get isEdited => editedAt != null;

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderProfileImage: data['senderProfileImage'],
      text: data['text'] ?? '',
      attachments: (data['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
      isRead: data['isRead'] ?? false,
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileImage': senderProfileImage,
      'text': text,
      'attachments': attachments.map((e) => e.toMap()).toList(),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderProfileImage,
    String? text,
    List<Attachment>? attachments,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? editedAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfileImage: senderProfileImage ?? this.senderProfileImage,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, text, createdAt];
}

class Attachment extends Equatable {
  final String type; // 'image', 'file', 'document'
  final String url;
  final String storagePath;
  final String fileName;
  final int fileSize;

  const Attachment({
    required this.type,
    required this.url,
    required this.storagePath,
    required this.fileName,
    this.fileSize = 0,
  });

  bool get isImage => type == 'image';
  bool get isFile => type == 'file';
  bool get isDocument => type == 'document';

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      type: map['type'] ?? 'file',
      url: map['url'] ?? '',
      storagePath: map['storagePath'] ?? '',
      fileName: map['fileName'] ?? '',
      fileSize: map['fileSize'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'url': url,
      'storagePath': storagePath,
      'fileName': fileName,
      'fileSize': fileSize,
    };
  }

  @override
  List<Object> get props => [type, url, storagePath, fileName, fileSize];
}
