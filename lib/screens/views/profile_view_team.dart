import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../theme/colors.dart';
import 'onboarding_screen.dart';
import 'github_status.dart';

class ProfileViewTeam extends StatefulWidget {
  const ProfileViewTeam({super.key});

  @override
  State<ProfileViewTeam> createState() => _ProfileViewTeamState();
}

class _ProfileViewTeamState extends State<ProfileViewTeam> {
  bool _isConnecting = false;
  bool _isConnected = false;
  String? _githubAccessToken;
  String? _githubUsername;

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
          print("Token berhasil disimpan: $_githubAccessToken");
          final userResponse = await http.get(
            Uri.parse('https://api.github.com/user'),
            headers: {'Authorization': 'Bearer $token'},
          );
          final userData = json.decode(userResponse.body);
          
          if (mounted) {
            setState(() {
              _githubAccessToken = token;
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
  }

  void _loadData() {
    if (mounted) {
      setState(() {
        _isConnected = GitHubStatus.isConnected;
        _githubUsername = GitHubStatus.username;
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('KYU', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1)),
        actions: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.inputBackground,
            child: Icon(Icons.person, color: AppColors.textMain, size: 24),
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
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Image.asset(
                          'image/ic_avatar_team.png',
                          width: 48,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.phone_android, size: 40, color: AppColors.rank1Background),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.textMain,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Tim',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Project Lead & PBL Enthusiast',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Profil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      Icon(Icons.person_add_alt_1_outlined, color: AppColors.textSecondary, size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Avatar with camera icon
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.inputBackground,
                            border: Border.all(color: AppColors.border, width: 1),
                          ),
                          child: const Icon(Icons.person_outline, size: 48, color: AppColors.textSecondary),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.textMain,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Nama Lengkap
                  const Text(
                    'Nama Lengkap',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Nama Lengkap',
                        hintStyle: TextStyle(color: AppColors.textMain, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Alamat Email
                  const Text(
                    'Alamat Email',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Alamat Email',
                        hintStyle: TextStyle(color: AppColors.textMain, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Simpan Perubahan Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statistik Fokus',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMain,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Metrik Performa\nPomodoro',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '12.5j',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          Text(
                            'Minggu\nIni',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Chart
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBar('S', 0.3, false),
                        _buildBar('S', 0.4, false),
                        _buildBar('R', 0.8, true),
                        _buildBar('K', 0.2, false),
                        _buildBar('J', 1.0, true),
                        _buildBar('S', 0.35, false),
                        _buildBar('M', 0.15, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Row of 2 Cards (Mode Terang & Notifikasi)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.dark_mode_outlined, color: AppColors.textSecondary, size: 28),
                        SizedBox(height: 16),
                        Text(
                          'Mode Terang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notifications_none, color: AppColors.textSecondary, size: 28),
                        SizedBox(height: 16),
                        Text(
                          'Notifikasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                  style: TextStyle(
                    color: AppColors.alertText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
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
  }

  Widget _buildBar(String label, double fillHeight, bool isHighlight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32,
          height: 80 * fillHeight,
          color: isHighlight ? const Color(0xFF6F8CAE) : const Color(0xFFEEEEEE),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}