class MessageModel {
  final String id;
  final String jobId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  MessageModel({
    required this.id,
    required this.jobId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      jobId: json['jobId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      receiverId: json['receiverId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  bool isMine(String currentUserId) => senderId == currentUserId;

  MessageModel copyWith({
    String? id,
    String? jobId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
  }) {
    return MessageModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
