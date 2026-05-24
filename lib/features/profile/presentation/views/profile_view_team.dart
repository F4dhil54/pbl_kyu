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
  String? _selectedImageName;
  User? _currentUser;

  // Real-time Pomodoro Focus Stats state
  double _totalFocusHoursThisWeek = 0.0;
  List<double> _weeklyFocusMinutes = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  RealtimeChannel? _pomodoroChannel;

  // Konfigurasi GitHub OAuth
  final String clientId = 'Ov23liyhzVvur2XKSlmg';
  final String clientSecret = '2532f44f75ea3f045b886a02257cb30b1ab6bf13'; 

  Future<void> _hubungkanGitHub() async {
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
        final token = data['access_token'];

        if (token != null) {
          final userResponse = await http.get(
            Uri.parse('https://api.github.com/user'),
            headers: {'Authorization': 'Bearer $token'},
          );
          final userData = json.decode(userResponse.body);
          
          if (mounted) {
            setState(() {
              _isConnected = true;
              _githubUsername = userData['login'];

              GitHubStatus.isConnected = true;
              GitHubStatus.username = userData['login'];
              GitHubStatus.isSyncActive = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _loadData() {
    if (mounted) {
      setState(() {
        _isConnected = GitHubStatus.isConnected;
        _githubUsername = GitHubStatus.username;
      });
    }
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
      
      // Calculate Monday (1) of this week
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
            _selectedImageName = image.name;
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
      
      // 1. Upload image if selected
      if (_selectedImageBytes != null) {
        final userId = _currentUser?.id ?? 'user';
        _avatarUrl = await profileRepo.uploadAvatar(
          userId,
          _selectedImageBytes!,
          _selectedImageName ?? 'avatar.png',
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
                // Profile Header
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: isDark ? AppDarkColors.surface : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppDarkColors.border : Colors.transparent),
                          ),
                          child: Center(
                            child: Image.asset(
                              'image/ic_avatar_team.png',
                              width: 48,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.phone_android, size: 40, color: isDark ? AppDarkColors.textSecondary : AppColors.rank1Background,),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.primary : AppColors.textMain,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppDarkColors.background : AppColors.background, width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
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

                // Edit Profil Card
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
                      // Avatar with camera icon
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

                // Hubungkan Akun Github Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? null : _hubungkanGitHub,
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

                // Statistik Fokus Card
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
                            if (maxMin < 25.0) maxMin = 25.0; // Avoid division by zero, min 25 mins scale

                            final labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
                            final todayIndex = DateTime.now().weekday - 1; // 0 = Senin, 6 = Minggu

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
