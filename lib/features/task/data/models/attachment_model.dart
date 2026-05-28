class AttachmentModel {
  final String id;
  final String taskId;
  final String? logId;
  final String tipeLampiran; // 'foto' | 'file' | 'link'
  final String filePathOrUrl;
  final String namaFile;

  AttachmentModel({
    required this.id,
    required this.taskId,
    this.logId,
    required this.tipeLampiran,
    required this.filePathOrUrl,
    required this.namaFile,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] as String? ?? '',
      taskId: json['task_id'] as String? ?? '',
      logId: json['log_id'] as String?,
      tipeLampiran: json['tipe_lampiran'] as String? ?? '',
      filePathOrUrl: json['file_path_or_url'] as String? ?? '',
      namaFile: json['nama_file'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipe_lampiran': tipeLampiran,
      'file_path_or_url': filePathOrUrl,
      'nama_file': namaFile,
      if (logId != null) 'log_id': logId,
    };
  }
}
