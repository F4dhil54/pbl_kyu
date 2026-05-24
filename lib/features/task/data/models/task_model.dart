import 'attachment_model.dart';

class TaskModel {
  final String id;
  final String projectId;
  final String createdBy;
  final String judulTugas;
  final String deskripsiTugas;
  final String kuadranEisenhower; // 'Do' | 'Schedule' | 'Delegate'
  final String statusTugas; // 'Akan Dikerjakan' | 'Sedang Dikerjakan' | 'Selesai' | 'draft' | 'scheduled'
  final int durasiPomodoro;
  final String? rejectionReason;
  final DateTime? deadlineDate;
  final String dibuatOlehRole; // 'Manajer' | 'Tim'
  final String keputusanManajer; // 'Menunggu' | 'Setujui' | 'Tidak Setujui'
  final String prioritas; // 'Do' | 'Schedule' | 'Delegate'
  final DateTime? scheduledFor;
  
  // Custom relations
  final List<String> assignees; // User IDs
  final List<AttachmentModel> attachments;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.createdBy,
    required this.judulTugas,
    required this.deskripsiTugas,
    required this.kuadranEisenhower,
    required this.statusTugas,
    required this.durasiPomodoro,
    this.rejectionReason,
    this.deadlineDate,
    required this.dibuatOlehRole,
    required this.keputusanManajer,
    required this.prioritas,
    this.scheduledFor,
    required this.assignees,
    required this.attachments,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json, {List<String>? assignees, List<AttachmentModel>? attachments}) {
    DateTime? dl;
    if (json['deadline'] != null) {
      dl = DateTime.tryParse(json['deadline'] as String);
    }
    DateTime? sf;
    if (json['scheduled_for'] != null) {
      sf = DateTime.tryParse(json['scheduled_for'] as String);
    }

    // KONVERSI DARI DATABASE (lowercase) KE TEKS UI INDONESIA
    String rawStatus = json['status_tugas'] as String? ?? 'draft';
    String uiStatus;
    switch (rawStatus) {
      case 'draft': uiStatus = 'Draft'; break;
      case 'review': uiStatus = 'Sedang Direview'; break;
      case 'accept': uiStatus = 'Akan Dikerjakan'; break;
      case 'done': uiStatus = 'Selesai'; break;
      default: uiStatus = 'Akan Dikerjakan';
    }

    return TaskModel(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      judulTugas: json['judul_tugas'] as String? ?? '',
      deskripsiTugas: json['deskripsi_tugas'] as String? ?? '',
      kuadranEisenhower: json['kuadran_eisenhower'] as String? ?? json['prioritas'] as String? ?? 'Schedule',
      statusTugas: uiStatus, // Menggunakan status yang sudah ramah UI
      durasiPomodoro: json['durasi_pomodoro'] as int? ?? 25,
      rejectionReason: json['rejection_reason'] as String?,
      deadlineDate: dl,
      dibuatOlehRole: json['dibuat_oleh_role'] as String? ?? 'Manajer',
      keputusanManajer: json['keputusan_manajer'] as String? ?? 'Setujui',
      prioritas: json['prioritas'] as String? ?? json['kuadran_eisenhower'] as String? ?? 'Schedule',
      scheduledFor: sf,
      assignees: assignees ?? [],
      attachments: attachments ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    // KONVERSI DARI TEKS UI INDONESIA KE KEYWORD DATABASE (lowercase)
    String dbStatus;
    switch (statusTugas) {
      case 'Draft':
      case 'draft': dbStatus = 'draft'; break;
      case 'Sedang Direview':
      case 'review': dbStatus = 'review'; break;
      case 'Akan Dikerjakan':
      case 'accept': dbStatus = 'accept'; break;
      case 'Selesai':
      case 'done': dbStatus = 'done'; break;
      default: dbStatus = 'draft'; // Fallback aman sesuai default struktur tabel
    }

    return {
      'project_id': projectId,
      'created_by': createdBy,
      'judul_tugas': judulTugas,
      'deskripsi_tugas': deskripsiTugas,
      'kuadran_eisenhower': kuadranEisenhower, // Sudah aman karena alter table kemarin
      'status_tugas': dbStatus,               // SEKARANG SUDAH DI-MAP KE 'accept' / 'draft'
      'durasi_pomodoro': durasiPomodoro,
      'rejection_reason': rejectionReason,
      'deadline': deadlineDate?.toIso8601String(),
      'dibuat_oleh_role': dibuatOlehRole,
      'keputusan_manajer': keputusanManajer,
      'prioritas': prioritas,
      'scheduled_for': scheduledFor?.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? projectId,
    String? createdBy,
    String? judulTugas,
    String? deskripsiTugas,
    String? kuadranEisenhower,
    String? statusTugas,
    int? durasiPomodoro,
    String? rejectionReason,
    DateTime? deadlineDate,
    String? dibuatOlehRole,
    String? keputusanManajer,
    String? prioritas,
    DateTime? scheduledFor,
    List<String>? assignees,
    List<AttachmentModel>? attachments,
  }) {
    return TaskModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      createdBy: createdBy ?? this.createdBy,
      judulTugas: judulTugas ?? this.judulTugas,
      deskripsiTugas: deskripsiTugas ?? this.deskripsiTugas,
      kuadranEisenhower: kuadranEisenhower ?? this.kuadranEisenhower,
      statusTugas: statusTugas ?? this.statusTugas,
      durasiPomodoro: durasiPomodoro ?? this.durasiPomodoro,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      dibuatOlehRole: dibuatOlehRole ?? this.dibuatOlehRole,
      keputusanManajer: keputusanManajer ?? this.keputusanManajer,
      prioritas: prioritas ?? this.prioritas,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      assignees: assignees ?? this.assignees,
      attachments: attachments ?? this.attachments,
    );
  }
}
