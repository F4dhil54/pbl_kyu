class KudosReaction {
  final String id;
  final String pengirimId;
  final String pengirimNama;
  final String reaksiEmoji;

  KudosReaction({
    required this.id,
    required this.pengirimId,
    required this.pengirimNama,
    required this.reaksiEmoji,
  });

  factory KudosReaction.fromJson(Map<String, dynamic> json) {
    final pengirimProfile = json['profiles'] as Map<String, dynamic>? ?? {};
    return KudosReaction(
      id: json['id'] as String? ?? '',
      pengirimId: json['pengirim_id'] as String? ?? '',
      pengirimNama: pengirimProfile['nama'] as String? ?? 'Anggota',
      reaksiEmoji: json['reaksi_emoji'] as String? ?? '👏🏻',
    );
  }
}

class ActivityModel {
  final String id;
  final String userName;
  final String? userAvatar;
  final String actionText;
  final String linkText;
  final DateTime time;
  final String type;
  final String? taskId;
  final String projectId;
  final String projectName;
  final String userId;
  final String? commitSha;
  final List<KudosReaction> reactions;

  ActivityModel({
    required this.id,
    required this.userName,
    this.userAvatar,
    required this.actionText,
    required this.linkText,
    required this.time,
    required this.type,
    this.taskId,
    required this.projectId,
    required this.projectName,
    required this.userId,
    this.commitSha,
    required this.reactions,
  });
}
