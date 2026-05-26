import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'notification_preference_item.dart';
import 'package:pbl_kyu/features/auth/presentation/views/onboarding_screen.dart';
import 'package:pbl_kyu/core/theme/colors.dart';
import 'package:pbl_kyu/core/theme/theme_mode.dart';
import 'package:pbl_kyu/core/network/supabase_provider.dart';
import '../providers/profile_provider.dart';
import 'edit_team_screen.dart';
import 'edit_member_screen.dart';

class ProfileViewManager extends ConsumerStatefulWidget {
  const ProfileViewManager({super.key});

  @override
  ConsumerState<ProfileViewManager> createState() => _ProfileViewManagerState();
}

class _ProfileViewManagerState extends ConsumerState<ProfileViewManager> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _avatarUrl;
  Uint8List? _selectedImageBytes;
  User? _currentUser;
  final _emailController = TextEditingController();
  bool _isLoadingInvitation = false;

  List<Map<String, dynamic>> _teams = [];
  bool _isLoadingTeams = false;
  final _teamNameController = TextEditingController();
  String? _selectedMemberId;
  bool _isCreatingTeam = false;
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _teamNameController.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
        _nameController.text = user.userMetadata?['nama'] ?? 
                               user.userMetadata?['name'] ?? 
                               user.userMetadata?['full_name'] ?? 
                               '';
        _avatarUrl = user.userMetadata?['avatar_url'] ?? 
                     user.userMetadata?['picture'] ?? 
                     user.userMetadata?['avatar'];
      });
      _loadInvitations();
      _loadTeams();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'aktif':
        return Colors.green;
      case 'nonaktif':
        return Colors.red;
      case 'pending':
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadInvitations() async {
    if (_currentUser == null) return;
    setState(() => _isLoadingMembers = true);
    try {
      final response = await ref.read(profileRepositoryProvider).getInvitations(_currentUser!.id);

      final list = response;
      setState(() {
        _members = list.map((item) {
          final profile = item['profiles'] as Map<String, dynamic>? ?? {};
          final name = profile['nama'] ?? 'Anggota';
          final email = profile['email'] ?? 'Tidak ada email';
          return {
            'invitation_id': item['id'] as String,
            'id': item['user_id'] as String,
            'name': name,
            'email': email,
            'role': item['role'] ?? 'Anggota',
            'initial': name.isNotEmpty ? name[0].toLowerCase() : 'u',
            'color': _getStatusColor(item['status'] as String),
            'status': item['status'] as String,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading invitations: $e');
    } finally {
      setState(() => _isLoadingMembers = false);
    }
  }



  Future<void> _loadTeams() async {
    if (_currentUser == null) return;
    setState(() => _isLoadingTeams = true);
    try {
      final response = await ref.read(profileRepositoryProvider).getTeams(_currentUser!.id);

      final list = response;
      setState(() {
        _teams = list.map((item) => {
          'id': item['id'] as String,
          'name': item['nama_tim'] as String,
          'color': Colors.blue,
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading teams: $e');
    } finally {
      setState(() => _isLoadingTeams = false);
    }
  }

  Future<void> _createTeam() async {
    final teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tim tidak boleh kosong'),
          backgroundColor: AppColors.alertText,
        ),
      );
      return;
    }

    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih anggota terlebih dahulu'),
          backgroundColor: AppColors.alertText,
        ),
      );
      return;
    }

    setState(() => _isCreatingTeam = true);

    try {
      final managerName = _currentUser!.userMetadata?['nama'] ??
          _currentUser!.userMetadata?['name'] ??
          _currentUser!.userMetadata?['full_name'] ??
          'Manajer';

      await ref.read(profileRepositoryProvider).createTeam(
        teamName: teamName,
        managerId: _currentUser!.id,
        memberId: _selectedMemberId!,
        managerName: managerName,
      );

      if (mounted) {
        _teamNameController.clear();
        setState(() {
          _selectedMemberId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tim baru berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadTeams();
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Gagal membuat tim.';
        if (e.toString().contains('teams_manajer_id_nama_tim_key') || 
            e.toString().contains('duplicate key')) {
          errorMessage = 'Nama tim "$teamName" sudah digunakan. Gunakan nama lain.';
        } else {
          errorMessage = 'Gagal membuat tim: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.alertText,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingTeam = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null && mounted) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Pangkas Foto',
              toolbarColor: const Color(0xFF1E3A8A),
              toolbarWidgetColor: Colors.white,
              cropStyle: CropStyle.circle,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Pangkas Foto',
              cropStyle: CropStyle.circle,
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
              size: const CropperSize(
                width: 320,
                height: 320,
              ),
            ),
          ],
        );

        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama lengkap tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      
      // 1. Upload image if selected → stores to avatars bucket + updates profiles table
      if (_selectedImageBytes != null) {
        final userId = _currentUser?.id ?? 'user';
        _avatarUrl = await profileRepo.uploadAvatar(
          userId,
          _selectedImageBytes!,
        );
      }
      
      // 2. Update user metadata
      final response = await profileRepo.updateUserProfile(
        name: _nameController.text.trim(),
        avatarUrl: _avatarUrl,
        currentUserMetadata: _currentUser?.userMetadata ?? {},
      );
      
      if (mounted) {
        setState(() {
          _currentUser = response.user;
          _selectedImageBytes = null; // Clear local preview since it's uploaded
          if (response.user != null) {
            _avatarUrl = response.user!.userMetadata?['avatar_url'] ?? 
                         response.user!.userMetadata?['picture'] ?? 
                         response.user!.userMetadata?['avatar'];
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeControl.themeNotifier,
      builder: (context, currentMode, child) {
        bool isDark = currentMode == ThemeMode.dark;

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'KYU',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            actions: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? AppDarkColors.surface : AppColors.inputBackground,
                child: ClipOval(
                  child: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                      ? Image.network(
                          _avatarUrl!,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            size: 24,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                          size: 24,
                        ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengaturan Manajer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola profil, anggota tim, dan grup proyek Anda dari\ndasbor terpusat.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Edit Profil Card
                _buildCardWrapper(
                  isDark: isDark,
                  title: 'Edit Profil',
                  iconData: Icons.person_add_alt_1_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? AppDarkColors.background : AppColors.inputBackground,
                                  border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 1),
                                ),
                                child: ClipOval(
                                  child: _selectedImageBytes != null
                                      ? Image.memory(
                                          _selectedImageBytes!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                          ? Image.network(
                                              _avatarUrl!,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(
                                                Icons.person_outline,
                                                size: 48,
                                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                              ),
                                            )
                                          : Icon(
                                              Icons.person_outline,
                                              size: 48,
                                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white : AppColors.textMain,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isDark ? AppDarkColors.surface : Colors.white, width: 2),
                                  ),
                                  child: Icon(Icons.camera_alt, size: 14, color: isDark ? AppDarkColors.surface : Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Nama Lengkap', style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      _buildTextField('Nama Lengkap', isDark: isDark, controller: _nameController),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.primary : AppColors.buttonDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Simpan Perubahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Manajemen Orang Card
                _buildCardWrapper(
                  isDark: isDark,
                  title: 'Manajemen Orang',
                  iconData: Icons.group_add_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTextField('Email anggota baru...', isDark: isDark, controller: _emailController),
                            const SizedBox(height: 12),
                            _buildDropdown('Jabatan: Anggota', isDark: isDark, showArrow: false),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: _isLoadingInvitation ? null : _inviteMember,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.primary : AppColors.buttonDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoadingInvitation
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Kirim Undangan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoadingMembers)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_members.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Belum ada anggota atau undangan.',
                              style: TextStyle(
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        for (int i = 0; i < _members.length; i++) ...[
                          _buildMemberListItem(
                            context,
                            _members[i]['id'] as String,
                            _members[i]['name'] as String,
                            _members[i]['role'] as String,
                            _members[i]['initial'] as String,
                            iconColor: _members[i]['color'] as Color,
                            isDark: isDark,
                            status: _members[i]['status'] as String,
                            invitationId: _members[i]['invitation_id'] as String,
                            email: _members[i]['email'] as String,
                          ),
                          if (i < _members.length - 1)
                            Divider(height: 24, color: isDark ? AppDarkColors.border : AppColors.border),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Manajemen Tim Card
                _buildCardWrapper(
                  isDark: isDark,
                  title: 'Manajemen Tim',
                  iconData: Icons.account_tree_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nama Tim', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                                const SizedBox(height: 8),
                                _buildTextField('mis. Design Sprint', height: 40, isDark: isDark, controller: _teamNameController),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pilih Anggota', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                                const SizedBox(height: 8),
                                _buildMemberDropdown(isDark: isDark),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isCreatingTeam ? null : _createTeam,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.primary : AppColors.buttonDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isCreatingTeam
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Buat Tim Baru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_isLoadingTeams)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_teams.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'Belum ada tim yang dibuat.',
                              style: TextStyle(
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        for (int i = 0; i < _teams.length; i++) ...[
                          _buildTeamListItem(
                            context,
                            _teams[i]['id'] as String,
                            _teams[i]['name'] as String,
                            _teams[i]['color'] as Color,
                            isDark: isDark,
                          ),
                          if (i < _teams.length - 1)
                            Divider(height: 24, color: isDark ? AppDarkColors.border : AppColors.border),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bagian Pengaturan Aplikasi
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'PENGATURAN APLIKASI', 
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      // Theme Toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark ? AppDarkColors.background : AppColors.inputBackground,
                              child: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: isDark ? Colors.amberAccent : Colors.orange, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isDark ? 'Mode Gelap' : 'Mode Terang',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sesuaikan tema visual aplikasi',
                                    style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isDark,
                              onChanged: (val) {
                                ThemeControl.toggleTheme();
                              },
                              activeTrackColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, indent: 72, endIndent: 16, color: isDark ? AppDarkColors.border : AppColors.border),
                      
                      // Notifikasi Suara
                      NotificationPreferenceItem(isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Keluar Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: AppColors.alertText, size: 20),
                    label: const Text('Keluar', style: TextStyle(color: AppColors.alertText, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                      side: const BorderSide(color: AppColors.alertText),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardWrapper({required String title, required IconData iconData, required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {double height = 48, required bool isDark, TextEditingController? controller}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: (height - 20) / 2),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, {double height = 48, required bool isDark, bool showArrow = true}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hint, style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14)),
          if (showArrow)
            Icon(Icons.keyboard_arrow_down, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildMemberDropdown({required bool isDark}) {
    final activeMembers = _members.where((m) => m['status'] == 'aktif').toList();
    
    if (_selectedMemberId != null && !activeMembers.any((m) => m['id'] == _selectedMemberId)) {
      _selectedMemberId = null;
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMemberId,
          hint: Text(
            'Nama Anggota', 
            style: TextStyle(
              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              fontSize: 14
            )
          ),
          dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
          isExpanded: true,
          style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
          onChanged: (String? newValue) {
            setState(() {
              _selectedMemberId = newValue;
            });
          },
          items: activeMembers.map<DropdownMenuItem<String>>((Map<String, dynamic> member) {
            return DropdownMenuItem<String>(
              value: member['id'] as String,
              child: Text(member['name'] as String),
            );
          }).toList(),
        ),
      ),
    );
  }



  Widget _buildMemberListItem(
    BuildContext context, 
    String id, 
    String name, 
    String role, 
    String initial, {
    Color iconColor = Colors.blue, 
    required bool isDark,
    required String status,
    required String invitationId,
    required String email,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Center(
            child: Icon(Icons.person, color: iconColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(role, style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: iconColor, width: 0.5),
                    ),
                    child: Text(
                      status == 'pending' ? 'Pending' : (status == 'aktif' ? 'Aktif' : 'Nonaktif'),
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: isDark ? AppDarkColors.surface : Colors.white,
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditMemberScreen(
                  invitationId: invitationId,
                  name: name,
                  email: email,
                  status: status,
                )),
              ).then((shouldReload) {
                if (shouldReload == true) {
                  _loadInvitations();
                }
              });
            } else if (value == 'delete') {
              _showDeleteConfirmation(
                context,
                isDark: isDark,
                title: 'Konfirmasi Hapus',
                message: 'Apakah anda yakin ingin menghapus orang?',
                onConfirm: () async {
                  try {
                    await ref.read(profileRepositoryProvider).deleteInvitation(invitationId);
                    await _loadInvitations();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Anggota berhasil dihapus!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus anggota: $e'),
                          backgroundColor: AppColors.alertText,
                        ),
                      );
                    }
                  }
                },
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Text(
                'Edit',
                style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(
                'Hapus',
                style: const TextStyle(color: AppColors.alertText),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamListItem(BuildContext context, String id, String name, Color iconColor, {required bool isDark}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
          child: Center(
            child: Icon(Icons.group, color: iconColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, size: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: isDark ? AppDarkColors.surface : Colors.white,
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditTeamScreen(teamId: id, teamName: name)),
              ).then((shouldReload) {
                if (shouldReload == true) {
                  _loadTeams();
                }
              });
            } else if (value == 'delete') {
              _showDeleteConfirmation(
                context,
                isDark: isDark,
                title: 'Konfirmasi Hapus',
                message: 'Apakah anda yakin ingin menghapus tim?',
                onConfirm: () async {
                  try {
                    await ref.read(profileRepositoryProvider).deleteTeam(id);
                    await _loadTeams();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tim berhasil dihapus!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus tim: $e'),
                          backgroundColor: AppColors.alertText,
                        ),
                      );
                    }
                  }
                },
              );
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'edit',
              child: Text(
                'Edit',
                style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text(
                'Hapus',
                style: const TextStyle(color: AppColors.alertText),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    required bool isDark,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: TextStyle(
              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tidak',
                style: TextStyle(
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.alertText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _inviteMember() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi telah berakhir. Silakan login kembali.'),
          backgroundColor: AppColors.alertText,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email tidak boleh kosong'),
          backgroundColor: AppColors.alertText,
        ),
      );
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid'),
          backgroundColor: AppColors.alertText,
        ),
      );
      return;
    }

    setState(() => _isLoadingInvitation = true);

    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final response = await profileRepo.getProfileByEmail(email);

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email tidak ditemukan. Pastikan pengguna sudah terdaftar.'),
              backgroundColor: AppColors.alertText,
            ),
          );
        }
        return;
      }

      final profile = response;
      final role = profile['role'] as String? ?? 'Tim';

      if (role == 'Manajer') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email tidak valid. Anda hanya dapat mengundang anggota dengan peran Tim.'),
              backgroundColor: AppColors.alertText,
            ),
          );
        }
        return;
      }
      final profileId = profile['id'] as String;

      final alreadyExists = _members.any((member) => member['id'] == profileId);
      if (alreadyExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anggota sudah ada di daftar.'),
              backgroundColor: AppColors.alertText,
            ),
          );
        }
        return;
      }

      await profileRepo.inviteMember(
        invitedBy: _currentUser!.id,
        userId: profileId,
        role: 'Anggota',
        status: 'pending',
      );

      if (mounted) {
        _emailController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Undangan berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      await _loadInvitations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengundang anggota: $e'),
            backgroundColor: AppColors.alertText,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingInvitation = false);
      }
    }
  }
}
