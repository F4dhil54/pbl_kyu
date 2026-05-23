class TeamModel {
  final String id;
  final String namaTim;
  final String manajerId;
  final String? deskripsi;

  TeamModel({
    required this.id,
    required this.namaTim,
    required this.manajerId,
    this.deskripsi,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String? ?? '',
      namaTim: json['nama_tim'] as String? ?? '',
      manajerId: json['manajer_id'] as String? ?? '',
      deskripsi: json['deskripsi'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_tim': namaTim,
      'manajer_id': manajerId,
      'deskripsi': deskripsi,
    };
  }
}
