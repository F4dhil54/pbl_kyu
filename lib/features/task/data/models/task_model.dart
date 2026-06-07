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
  
  final int? taskNumber;
  
  // Relasi kustom
  final List<String> assignees; // User IDs
  final List<AttachmentModel> attachments;
  final String? projectTeamId;
  final String? projectMemberId;

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
    this.taskNumber,
    required this.assignees,
    required this.attachments,
    this.projectTeamId,
    this.projectMemberId,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json, {
    List<String>? assignees,
    List<AttachmentModel>? attachments,
    String? projectTeamId,
    String? projectMemberId,
  }) {
    DateTime? dl;
    if (json['deadline'] != null) {
      dl = DateTime.tryParse(json['deadline'] as String)?.toLocal();
    }
    DateTime? sf;
    if (json['scheduled_for'] != null) {
      sf = DateTime.tryParse(json['scheduled_for'] as String)?.toLocal();
    }

    // Konversi dari DB ke UI
    String rawStatus = (json['status_tugas'] as String? ?? 'draft').toLowerCase().trim();
    if (rawStatus == 'scheduled' && sf != null && sf.isBefore(DateTime.now())) {
      rawStatus = 'accept';
    }

    String uiStatus;
    switch (rawStatus) {
      case 'draft':
      case 'draf':
        uiStatus = 'Draft';
        break;
      case 'review':
        uiStatus = 'Ditinjau';
        break;
      case 'accept':
        uiStatus = 'Akan Dikerjakan';
        break;
      case 'done':
        uiStatus = 'Selesai';
        break;
      case 'scheduled':
        uiStatus = 'Dijadwalkan';
        break;
      default:
        uiStatus = 'Akan Dikerjakan';
    }

    return TaskModel(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      judulTugas: json['judul_tugas'] as String? ?? '',
      deskripsiTugas: json['deskripsi_tugas'] as String? ?? '',
      kuadranEisenhower: json['kuadran_eisenhower'] as String? ?? json['prioritas'] as String? ?? 'Schedule',
      statusTugas: uiStatus, // Gunakan status UI
      durasiPomodoro: json['durasi_pomodoro'] as int? ?? 25,
      rejectionReason: json['rejection_reason'] as String?,
      deadlineDate: dl,
      dibuatOlehRole: json['dibuat_oleh_role'] as String? ?? 'Manajer',
      keputusanManajer: json['keputusan_manajer'] as String? ?? 'Setujui',
      prioritas: json['prioritas'] as String? ?? json['kuadran_eisenhower'] as String? ?? 'Schedule',
      scheduledFor: sf,
      taskNumber: json['task_number'] as int?,
      assignees: assignees ?? [],
      attachments: attachments ?? [],
      projectTeamId: projectTeamId,
      projectMemberId: projectMemberId,
    );
  }

  Map<String, dynamic> toJson() {
    // Konversi dari UI ke DB
    String dbStatus;
    switch (statusTugas.toLowerCase().trim()) {
      case 'draft':
      case 'draf':
        dbStatus = 'draft';
        break;
      case 'ditinjau':
      case 'review':
        dbStatus = 'review';
        break;
      case 'akan dikerjakan':
      case 'accept':
        dbStatus = 'accept';
        break;
      case 'selesai':
      case 'done':
        dbStatus = 'done';
        break;
      case 'dijadwalkan':
      case 'scheduled':
        dbStatus = 'scheduled';
        break;
      default:
        dbStatus = 'draft'; // Fallback ke default DB
    }

    final data = {
      'project_id': projectId,
      'created_by': createdBy,
      'judul_tugas': judulTugas,
      'deskripsi_tugas': deskripsiTugas,
      'kuadran_eisenhower': kuadranEisenhower, 
      'status_tugas': dbStatus,               
      'durasi_pomodoro': durasiPomodoro,
      'rejection_reason': rejectionReason,
      'deadline': deadlineDate?.toUtc().toIso8601String(),
      'dibuat_oleh_role': dibuatOlehRole,
      'keputusan_manajer': keputusanManajer,
      'prioritas': prioritas,
      'scheduled_for': scheduledFor?.toUtc().toIso8601String(),
    };

    if (taskNumber != null) {
      data['task_number'] = taskNumber;
    }

    return data;
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
    int? taskNumber,
    List<String>? assignees,
    List<AttachmentModel>? attachments,
    String? projectTeamId,
    String? projectMemberId,
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
      taskNumber: taskNumber ?? this.taskNumber,
      assignees: assignees ?? this.assignees,
      attachments: attachments ?? this.attachments,
      projectTeamId: projectTeamId ?? this.projectTeamId,
      projectMemberId: projectMemberId ?? this.projectMemberId,
    );
  }
}
