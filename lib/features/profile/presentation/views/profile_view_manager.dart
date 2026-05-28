import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'notification_preference_item.dart';
import 'package:pbl_kyu/features/auth/presentation/views/onboarding_screen.dart';
import 'package:pbl_kyu/features/auth/providers/auth_provider.dart';
import 'package:pbl_kyu/core/theme/colors.dart';
import 'package:pbl_kyu/core/theme/theme_mode.dart';
import 'package:pbl_kyu/core/network/supabase_provider.dart';
import 'package:pbl_kyu/core/services/github_status.dart';
import '../providers/profile_provider.dart';
import 'edit_team_screen.dart';
import 'edit_member_screen.dart';
import 'all_members_screen.dart';
import 'all_teams_screen.dart';

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
  final _inviteFormKey = GlobalKey<FormState>();
  bool _isLoadingInvitation = false;

  List<Map<String, dynamic>> _teams = [];
  bool _isLoadingTeams = false;
  final _teamNameController = TextEditingController();
  final _teamFormKey = GlobalKey<FormState>();
  String? _selectedMemberId;
  bool _isCreatingTeam = false;
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingMembers = false;

  bool _isConnected = false;
  bool _isConnecting = false;
  String? _githubUsername;

  // Konfigurasi GitHub OAuth
  final String clientId = 'Ov23liyhzVvur2XKSlmg';
  final String clientSecret = '2532f44f75ea3f045b886a02257cb30b1ab6bf13'; 

  Future<void> hubungkanAkunGithub() async {
    setState(() => _isConnecting = true);

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: "https://github.com/login/oauth/authorize?client_id=$clientId&scope=repo,user",
        callbackUrlScheme: "kyu",
      );

      final code = Uri.parse(result).queryParameters['code'];

      if (code != null) {
        final response = await http.post(
          Uri.parse('https://github.com/login/oauth/access_token'),
          headers: {'Accept': 'application/json'},
          body: {
            'client_id': clientId,
            'client_secret': clientSecret,
            'code': code,
          },
        );

        final data = json.decode(response.body);
        final token = data['access_token'] as String?;

        if (token != null) {
          final userResponse = await http.get(
            Uri.parse('https://api.github.com/user'),
            headers: {'Authorization': 'Bearer $token'},
          );
          final userData = json.decode(userResponse.body);
          final githubUsername = userData['login'] as String;

          final supabase = ref.read(supabaseClientProvider);
          final user = supabase.auth.currentUser;
          if (user != null) {
            await supabase.from('profiles').update({
              'github_username': githubUsername,
              'github_token': token,
            }).eq('id', user.id);
          }

          await GitHubStatus.saveStatus(true, githubUsername, true);

          if (mounted) {
            setState(() {
              _isConnected = true;
              _githubUsername = githubUsername;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Akun GitHub berhasil terhubung!'),
                backgroundColor: AppColors.successText,
              ),
            );
          }
        } else {
          throw Exception('Token akses tidak valid.');
        }
      } else {
        throw Exception('Kode otorisasi tidak ditemukan.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghubungkan GitHub. Silakan coba lagi.'), backgroundColor: AppColors.alertText),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _loadGithubStatus() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final res = await supabase
            .from('profiles')
            .select('github_username, github_token')
            .eq('id', user.id)
            .maybeSingle();
        if (res != null) {
          final username = res['github_username'] as String?;
          final token = res['github_token'] as String?;
          if (username != null && token != null && username.isNotEmpty && token.isNotEmpty) {
            await GitHubStatus.saveStatus(true, username, true);
            if (mounted) {
              setState(() {
                _isConnected = true;
                _githubUsername = username;
              });
            }
            return;
          }
        }
      } catch (e) {
        debugPrint("Error loading GitHub status from DB: $e");
      }
    }
    if (mounted) {
      setState(() {
        _isConnected = GitHubStatus.isConnected;
        _githubUsername = GitHubStatus.username.isNotEmpty ? GitHubStatus.username : null;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadGithubStatus();
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadGithubStatus();
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
    if (!_teamFormKey.currentState!.validate()) {
      return;
    }

    final teamName = _teamNameController.text.trim();

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
          if (bytes.length > 2 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ukuran foto profil tidak boleh lebih dari 2 MB'),
                  backgroundColor: AppColors.alertText,
                ),
              );
            }
            return;
          }
          setState(() {
            _selectedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar. Silakan coba lagi.'),
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
      
      // Upload image if selected → stores to avatars bucket + updates profiles table
      if (_selectedImageBytes != null) {
        final userId = _currentUser?.id ?? 'user';
        _avatarUrl = await profileRepo.uploadAvatar(
          userId,
          _selectedImageBytes!,
        );
      }
      
      // Update user metadata
      final response = await profileRepo.updateUserProfile(
        name: _nameController.text.trim(),
        avatarUrl: _avatarUrl,
        currentUserMetadata: _currentUser?.userMetadata ?? {},
      );
      
      if (mounted) {
        setState(() {
          _currentUser = response.user;
          _selectedImageBytes = null;
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
          const SnackBar(
            content: Text('Gagal memperbarui profil. Silakan coba lagi.'),
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
                Row(
                  children: [
                    Image.asset(
                      'image/logoSemua.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.groups, size: 72, color: isDark ? AppDarkColors.textSecondary : AppColors.primary),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
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
                            'Kelola profil, anggota tim, dan grup proyek Anda dari dasbor terpusat.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

                // Hubungkan Akun Github Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? null : hubungkanAkunGithub,
                    icon: _isConnecting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(_isConnected ? Icons.check_circle : Icons.sync_alt, color: Colors.white, size: 20),
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isConnected ? 'Terhubung dengan akun GitHub' : 'Hubungkan Akun Github',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (_isConnected && _githubUsername != null)
                          Text(
                            '@$_githubUsername',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
                          ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isConnected ? const Color(0xFF2EA043) : AppColors.rank1Background,
                      disabledBackgroundColor: const Color(0xFF2EA043), 
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                            Form(
                              key: _inviteFormKey,
                              child: _buildTextField('Email anggota baru *', isDark: isDark, controller: _emailController, validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Format email tidak valid';
                                return null;
                              }),
                            ),
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
                      else ...[
                        for (int i = 0; i < (_members.length > 5 ? 5 : _members.length); i++) ...[
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
                          if (i < (_members.length > 5 ? 5 : _members.length) - 1)
                            Divider(height: 24, color: isDark ? AppDarkColors.border : AppColors.border),
                        ],
                        if (_members.length > 5) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AllMembersScreen()),
                                ).then((_) => _loadInvitations());
                              },
                              icon: const Icon(Icons.people, size: 16, color: AppColors.primary),
                              label: const Text(
                                'Lihat Semua Anggota',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
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
                      Form(
                        key: _teamFormKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nama Tim *', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                                  const SizedBox(height: 8),
                                  _buildTextField('mis. Design Sprint', height: 40, isDark: isDark, controller: _teamNameController, validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Nama tim tidak boleh kosong';
                                    return null;
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pilih Anggota *', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                                  const SizedBox(height: 8),
                                  _buildMemberDropdown(isDark: isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                      else ...[
                        for (int i = 0; i < (_teams.length > 5 ? 5 : _teams.length); i++) ...[
                          _buildTeamListItem(
                            context,
                            _teams[i]['id'] as String,
                            _teams[i]['name'] as String,
                            _teams[i]['color'] as Color,
                            isDark: isDark,
                          ),
                          if (i < (_teams.length > 5 ? 5 : _teams.length) - 1)
                            Divider(height: 24, color: isDark ? AppDarkColors.border : AppColors.border),
                        ],
                        if (_teams.length > 5) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AllTeamsScreen()),
                                ).then((_) => _loadTeams());
                              },
                              icon: const Icon(Icons.group, size: 16, color: AppColors.primary),
                              label: const Text(
                                'Lihat Semua Tim',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
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
                    onPressed: () async {
                      final authController = ref.read(authControllerProvider);
                      await authController.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                          (route) => false,
                        );
                      }
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

  Widget _buildTextField(String hint, {double height = 48, required bool isDark, TextEditingController? controller, String? Function(String?)? validator}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 14),
          filled: true,
          fillColor: isDark ? AppDarkColors.background : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
          errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
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

    return DropdownButtonFormField<String>(
      value: _selectedMemberId,
      hint: Text(
        'Nama Anggota', 
        style: TextStyle(
          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
          fontSize: 14
        )
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Pilih anggota terlebih dahulu';
        }
        return null;
      },
      dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
      isExpanded: true,
      style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14),
      icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? AppDarkColors.background : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2.0),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
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
                        const SnackBar(
                          content: Text('Gagal menghapus anggota. Silakan coba lagi.'),
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
                        const SnackBar(
                          content: Text('Gagal menghapus tim. Silakan coba lagi.'),
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
    if (!_inviteFormKey.currentState!.validate()) {
      return;
    }

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
          const SnackBar(
            content: Text('Gagal mengundang anggota. Silakan coba lagi.'),
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
