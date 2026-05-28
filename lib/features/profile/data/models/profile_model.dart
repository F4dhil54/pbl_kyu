class ProfileModel {
  final String id;
  final String nama;
  final String email;
  final String? avatarUrl;
  final String? githubUsername;
  final String? githubToken;

  ProfileModel({
    required this.id,
    required this.nama,
    required this.email,
    this.avatarUrl,
    this.githubUsername,
    this.githubToken,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      githubUsername: json['github_username'] as String?,
      githubToken: json['github_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'avatar_url': avatarUrl,
      'github_username': githubUsername,
      'github_token': githubToken,
    };
  }
}
