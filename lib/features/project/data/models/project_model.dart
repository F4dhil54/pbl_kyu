import 'package:intl/intl.dart'; // Pastikan sudah menambahkan package intl di pubspec.yaml

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final List<String> labels;
  final String githubRepo;
  final double progress;
  final String category;
  final String date; // Menyimpan string tanggal dari UI
  final String creatorId;
  final bool statusAktif;
  final DateTime? createdAt;
  final bool isReadOnly;
  final String? githubRepoUrl;
  final String? managerGithubToken;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.labels,
    required this.githubRepo,
    required this.progress,
    required this.category,
    required this.date,
    required this.creatorId,
    required this.statusAktif,
    this.createdAt,
    this.isReadOnly = false,
    this.githubRepoUrl,
    this.managerGithubToken,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final progressVal =
        (json['progress_persen'] as num?)?.toDouble() ??
        (json['progress'] as num?)?.toDouble() ??
        0.0;

    // Map integer percentage (e.g. 75) to double 0.75 if it is greater than 1.0
    final double doubleProgress = progressVal > 1.0
        ? progressVal / 100.0
        : progressVal;

    // Ambil string dari database, lalu buat agar tampil rapi di UI jika perlu
    String rawDate =
        json['deadline'] as String? ??
        json['date_deadline'] as String? ??
        json['date'] as String? ??
        '';

    // Jika format dari Supabase adalah ISO String (ada huruf T atau Z), kita bersihkan atau biarkan berupa String
    if (rawDate.contains('T')) {
      try {
        DateTime parsed = DateTime.parse(rawDate).toLocal();
        rawDate = DateFormat(
          'yyyy-MM-dd',
        ).format(parsed); // Diubah ke format string standar standar
      } catch (_) {}
    }

    return ProjectModel(
      id: json['id'] as String? ?? '',
      name: json['nama_proyek'] as String? ?? json['name'] as String? ?? '',
      description:
          json['deskripsi'] as String? ?? json['description'] as String? ?? '',
      labels: json['labels'] is List
          ? (json['labels'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],
      githubRepo:
          json['tautan_github'] as String? ??
          json['github_repo'] as String? ??
          '',
      progress: doubleProgress,
      category:
          json['kategori'] as String? ?? json['category'] as String? ?? '',
      date: rawDate,
      creatorId:
          json['pembuat_id'] as String? ?? json['creatorId'] as String? ?? '',
      statusAktif:
          json['status_aktif'] as bool? ?? json['statusAktif'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      githubRepoUrl: json['github_repo_url'] as String?,
      managerGithubToken: json['manager_github_token'] as String?,
    );
  }

  /// Menangani konversi String Tanggal dari UI ke format ISO yang dimengerti PostgreSQL
  String? _formatToPostgresTimestamp(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      // 1. Jika formatnya sudah valid standar (YYYY-MM-DD), langsung parsing aman
      return DateTime.parse(dateStr).toIso8601String();
    } catch (_) {
      try {
        // 2. Jika formatnya kustom seperti "23 Mei" atau "23 Mei 2026"
        // Kita paksa parse menggunakan bantuan DateFormat locale Indonesia/English
        int currentYear = DateTime.now().year;
        DateTime parsed;

        if (!dateStr.contains(currentYear.toString())) {
          // Jika tidak ada tahunnya (misal cuma "23 Mei"), tambahkan tahun sekarang otomatis
          parsed = DateFormat(
            "d MMMM yyyy",
            "id",
          ).parse("$dateStr $currentYear");
        } else {
          parsed = DateFormat("d MMMM yyyy", "id").parse(dateStr);
        }
        return parsed.toIso8601String();
      } catch (e) {
        // Fallback terakhir: Coba format 'yyyy-MM-dd' manual jika library intl mendeteksi variasi lain
        try {
          return DateFormat('yyyy-MM-dd').parse(dateStr).toIso8601String();
        } catch (_) {
          return null; // Jika benar-benar acak-acakan, kembalikan null agar tidak crash
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_proyek': name,
      'deskripsi': description,
      'tautan_github': githubRepo,
      'progress_persen': (progress * 100).toInt(),
      'kategori': category,
      'deadline': _formatToPostgresTimestamp(
        date,
      ), // Di-formatting otomatis di sini
      'pembuat_id': creatorId.isNotEmpty && !creatorId.startsWith('local-')
          ? creatorId
          : null,
      'status_aktif': statusAktif,
      'github_repo_url': githubRepoUrl,
      'manager_github_token': managerGithubToken,
    };
  }

  Map<String, dynamic> toJsonWithId() {
    return {
      if (id.isNotEmpty && !id.startsWith('local-')) 'id': id,
      'nama_proyek': name,
      'deskripsi': description,
      'tautan_github': githubRepo,
      'progress_persen': (progress * 100).toInt(),
      'kategori': category,
      'deadline': _formatToPostgresTimestamp(
        date,
      ), // Di-formatting otomatis di sini
      'pembuat_id': creatorId.isNotEmpty && !creatorId.startsWith('local-')
          ? creatorId
          : null,
      'status_aktif': statusAktif,
      'github_repo_url': githubRepoUrl,
      'manager_github_token': managerGithubToken,
    };
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? labels,
    String? githubRepo,
    double? progress,
    String? category,
    String? date,
    String? creatorId,
    bool? statusAktif,
    DateTime? createdAt,
    bool? isReadOnly,
    String? githubRepoUrl,
    String? managerGithubToken,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      labels: labels ?? this.labels,
      githubRepo: githubRepo ?? this.githubRepo,
      progress: progress ?? this.progress,
      category: category ?? this.category,
      date: date ?? this.date,
      creatorId: creatorId ?? this.creatorId,
      statusAktif: statusAktif ?? this.statusAktif,
      createdAt: createdAt ?? this.createdAt,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      githubRepoUrl: githubRepoUrl ?? this.githubRepoUrl,
      managerGithubToken: managerGithubToken ?? this.managerGithubToken,
    );
  }
}
