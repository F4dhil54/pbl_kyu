import 'profile_model.dart';

class InvitationModel {
  final String id;
  final String userId;
  final String invitedBy;
  final String status;
  final String role;
  final ProfileModel? profile;

  InvitationModel({
    required this.id,
    required this.userId,
    required this.invitedBy,
    required this.status,
    required this.role,
    this.profile,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? prof;
    if (json['profiles'] != null) {
      prof = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }
    return InvitationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      invitedBy: json['invited_by'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      role: json['role'] as String? ?? 'Anggota',
      profile: prof,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'invited_by': invitedBy,
      'status': status,
      'role': role,
      if (profile != null) 'profiles': profile!.toJson(),
    };
  }
}
