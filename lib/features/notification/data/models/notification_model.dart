
class NotificationModel {
  final String id;
  final String userId;
  final String? senderId;
  final String? projectId;
  final String? projectName;
  final String tipeNotifikasi; // 'pesan', 'tugas', 'mention', 'undangan', 'kudos', dll
  final String judul;
  final String pesan;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;
  final String? senderEmail;
  final String? senderAvatar;

  NotificationModel({
    required this.id,
    required this.userId,
    this.senderId,
    this.projectId,
    this.projectName,
    required this.tipeNotifikasi,
    required this.judul,
    required this.pesan,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderEmail,
    this.senderAvatar,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final project = json['projects'] as Map<String, dynamic>? ?? {};
    final sender = json['sender'] as Map<String, dynamic>? ?? {};
    
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      senderId: json['sender_id'] as String?,
      projectId: json['project_id'] as String?,
      projectName: project['nama_proyek'] as String?,
      tipeNotifikasi: json['tipe_notifikasi'] as String,
      judul: json['judul'] as String,
      pesan: json['pesan'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      senderName: sender['nama'] as String?,
      senderEmail: sender['email'] as String?,
      senderAvatar: sender['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'sender_id': senderId,
      'project_id': projectId,
      'tipe_notifikasi': tipeNotifikasi,
      'judul': judul,
      'pesan': pesan,
      'is_read': isRead,
    };
  }
}
