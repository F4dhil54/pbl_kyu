class ProfileModel {
  final String id;
  final String nama;
  final String email;
  final String? avatarUrl;

  ProfileModel({
    required this.id,
    required this.nama,
    required this.email,
    this.avatarUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }
}
