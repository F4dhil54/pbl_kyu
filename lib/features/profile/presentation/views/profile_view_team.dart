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
import 'package:pbl_kyu/core/theme/colors.dart';
import 'package:pbl_kyu/core/theme/theme_mode.dart';
import 'package:pbl_kyu/features/auth/presentation/views/onboarding_screen.dart';
import 'package:pbl_kyu/features/auth/providers/auth_provider.dart';
import 'notification_preference_item.dart';
import 'package:pbl_kyu/core/services/github_status.dart';
import 'package:pbl_kyu/core/network/supabase_provider.dart';
import '../providers/profile_provider.dart';

class ProfileViewTeam extends ConsumerStatefulWidget {
  const ProfileViewTeam({super.key});

  @override
  ConsumerState<ProfileViewTeam> createState() => _ProfileViewTeamState();
}

class _ProfileViewTeamState extends ConsumerState<ProfileViewTeam> {
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _githubUsername;

  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _avatarUrl;
  Uint8List? _selectedImageBytes;
  User? _currentUser;

  // State Statistik Pomodoro
  double _totalFocusHoursThisWeek = 0.0;
  List<double> _weeklyFocusMinutes = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  RealtimeChannel? _pomodoroChannel;

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
          SnackBar(content: Text('Gagal menghubungkan GitHub: $e'), backgroundColor: AppColors.alertText),
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
    _loadGithubStatus();
    _loadUserProfile();
    _subscribePomodoroRealtime();
  }

  @override
  void dispose() {
    _pomodoroChannel?.unsubscribe();
    _nameController.dispose();
    super.dispose();
  }

  void _subscribePomodoroRealtime() {
    final supabase = ref.read(supabaseClientProvider);
    _pomodoroChannel = supabase.channel('pomodoro_stats_realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'pomodoro_sessions',
        callback: (payload) {
          debugPrint('Realtime: New pomodoro session detected, refreshing stats...');
          _loadFocusStats();
        },
      )
      .subscribe();
  }

  Future<void> _loadUserProfile() async {
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

      try {
        final profileData = await supabase
            .from('profiles')
            .select('nama, avatar_url')
            .eq('id', user.id)
            .maybeSingle();
            
        if (profileData != null && mounted) {
           setState(() {
             if (profileData['nama'] != null && profileData['nama'].toString().isNotEmpty) {
               _nameController.text = profileData['nama'];
             }
             if (profileData['avatar_url'] != null && profileData['avatar_url'].toString().isNotEmpty) {
               _avatarUrl = profileData['avatar_url'];
             }
           });
        }
      } catch (e) {
        debugPrint("Failed to fetch profile from DB: $e");
      }

      _loadFocusStats();
    }
  }

  Future<void> _loadFocusStats() async {
    final supabase = ref.read(supabaseClientProvider);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final currentWeekday = now.weekday;
      
      // Hitung Senin minggu ini
      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final response = await ref.read(profileRepositoryProvider).getPomodoroSessions(
        userId: user.id,
        startOfWeek: startOfWeek,
        endOfWeek: endOfWeek,
      );

      final List<dynamic> data = response;

      final List<double> weeklyMinutes = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
      double totalMinutes = 0.0;

      for (final session in data) {
        final double durasi = (session['durasi_menit'] as num).toDouble();
        final String startedAtStr = session['started_at'] as String;
        final DateTime startedAt = DateTime.parse(startedAtStr).toLocal();

        final int weekday = startedAt.weekday;
        final int index = weekday - 1;

        if (index >= 0 && index < 7) {
          weeklyMinutes[index] += durasi;
          totalMinutes += durasi;
        }
      }

      if (mounted) {
        setState(() {
          _weeklyFocusMinutes = weeklyMinutes;
          _totalFocusHoursThisWeek = totalMinutes / 60.0;
        });
      }
    } catch (e) {
      debugPrint('Error loading focus stats: $e');
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
      
      // Upload & simpan avatar
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
                letterSpacing: 1
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
              children: [
                // Header Profil
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
                            'Pengaturan Tim',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Project Lead & PBL Enthusiast',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Kartu Edit Profil
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Profil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Avatar dengan ikon kamera
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
                      Text(
                        'Nama Lengkap',
                        style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? AppDarkColors.background : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
                        ),
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                          decoration: InputDecoration(
                            hintText: 'Nama Lengkap',
                            hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.primary : AppColors.buttonDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

                // Tombol Hubungkan GitHub
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
                
                const SizedBox(height: 40),

                // Kartu Statistik Fokus
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF78909C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.timer_outlined, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Statistik Fokus',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Metrik Performa\nPomodoro',
                                  style: TextStyle(fontSize: 14, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_totalFocusHoursThisWeek.toStringAsFixed(1)}j',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                              ),
                              Text(
                                'Minggu\nIni',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 120,
                        child: Builder(
                          builder: (context) {
                            double maxMin = 0.0;
                            for (final m in _weeklyFocusMinutes) {
                              if (m > maxMin) maxMin = m;
                            }
                            if (maxMin < 25.0) maxMin = 25.0;

                            final labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
                            final todayIndex = DateTime.now().weekday - 1;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(7, (index) {
                                final double minutes = _weeklyFocusMinutes[index];
                                final double fillHeight = minutes / maxMin;
                                final String label = labels[index];
                                final bool isToday = index == todayIndex;

                                return _buildBar(label, fillHeight, isToday, isDark);
                              }),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Pengaturan Aplikasi
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
                      // Toggle Tema
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
                      
                      // Suara Notifikasi
                      NotificationPreferenceItem(isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Keluar
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
                    label: const Text(
                      'Keluar',
                      style: TextStyle(color: AppColors.alertText, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? AppDarkColors.surface : Colors.white,
                      side: const BorderSide(color: AppColors.alertText),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildBar(String label, double fillHeight, bool isHighlight, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 80 * fillHeight,
          color: isHighlight ? const Color(0xFF6F8CAE) : (isDark ? AppDarkColors.border : const Color(0xFFEEEEEE)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
