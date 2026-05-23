import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';

class EditTeamScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  const EditTeamScreen({super.key, required this.teamId, required this.teamName});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  late TextEditingController _teamNameController;

  List<Map<String, dynamic>> _selectedMembers = [];
  List<Map<String, dynamic>> _availableMembers = [];
  List<Map<String, dynamic>> _projects = [];
  
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _teamNameController = TextEditingController(text: widget.teamName);
    _loadData();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Load team members
      final teamMembersRes = await supabase
          .from('team_members')
          .select('user_id, profiles!inner(nama)')
          .eq('team_id', widget.teamId);

      final List<Map<String, dynamic>> currentMembers = [];
      for (final tm in teamMembersRes) {
        currentMembers.add({
          'id': tm['user_id'],
          'name': tm['profiles']['nama'],
        });
      }

      // 2. Load all colleagues to see who is available
      final colleaguesRes = await supabase
          .from('invitations')
          .select('user_id, profiles!invitations_user_id_fkey(nama)')
          .eq('invited_by', user.id)
          .eq('status', 'aktif');

      final List<Map<String, dynamic>> availableMembers = [];
      for (final c in colleaguesRes) {
        final cid = c['user_id'] as String;
        if (!currentMembers.any((m) => m['id'] == cid)) {
          availableMembers.add({
            'id': cid,
            'name': c['profiles']['nama'] ?? 'Unknown',
          });
        }
      }

      // 3. Load user's projects
      final projectsRes = await supabase
          .from('projects')
          .select('id, nama_proyek')
          .eq('pembuat_id', user.id);

      final List<Map<String, dynamic>> loadedProjects = (projectsRes as List<dynamic>).map((p) => {
        'id': p['id'] as String,
        'name': p['nama_proyek'] as String,
      }).toList();

      if (mounted) {
        setState(() {
          _selectedMembers = currentMembers;
          _availableMembers = availableMembers;
          _projects = loadedProjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading edit team data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data tim: $e'), backgroundColor: AppColors.alertText),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final teamName = _teamNameController.text.trim();
    if (teamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tim tidak boleh kosong'), backgroundColor: AppColors.alertText),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser!;

      // 1. Update team name if changed
      if (teamName != widget.teamName) {
        await supabase.from('teams').update({'nama_tim': teamName}).eq('id', widget.teamId);
      }

      // 2. Sync team_members (simplest way: delete all and insert current selection)
      await supabase.from('team_members').delete().eq('team_id', widget.teamId);

      if (_selectedMembers.isNotEmpty) {
        final inserts = _selectedMembers.map((m) => {
          'team_id': widget.teamId,
          'user_id': m['id'],
        }).toList();
        await supabase.from('team_members').insert(inserts);
      }

      // 3. If a project is selected, upsert members to project_members
      if (_selectedProjectId != null && _selectedMembers.isNotEmpty) {
        for (final m in _selectedMembers) {
          await supabase.from('project_members').upsert({
            'project_id': _selectedProjectId!,
            'user_id': m['id'],
            'invited_by': currentUser.id,
            'status_akses': 'aktif',
          }, onConflict: 'project_id, user_id');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menyimpan perubahan'), backgroundColor: AppColors.successText),
        );
        Navigator.pop(context, true); // return true to trigger refresh
      }
    } catch (e) {
      debugPrint('Error saving team: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e'), backgroundColor: AppColors.alertText),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _removeMember(Map<String, dynamic> member) {
    setState(() {
      _selectedMembers.remove(member);
      _availableMembers.add(member);
    });
  }

  void _addMember(Map<String, dynamic> member) {
    setState(() {
      _availableMembers.remove(member);
      _selectedMembers.add(member);
    });
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
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'KYU',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          body: _isLoading 
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manajemen Tim',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola tim kolaborasi dan hak akses tim dalam\nproyek.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppDarkColors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Tim',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildInputLabel('Nama Grup', isDark: isDark),
                      _buildTextField(isDark: isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('Pilih Anggota', isDark: isDark),
                      _buildTagsInput(isDark: isDark),
                      const SizedBox(height: 20),

                      _buildInputLabel('Pilih Proyek', isDark: isDark),
                      _buildProjectDropdown(isDark: isDark),
                      const SizedBox(height: 32),
                      Divider(color: isDark ? AppDarkColors.border : AppColors.border),
                      const SizedBox(height: 24),

                      // Action Buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.primary : const Color(0xFF020617),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          child: _isSaving 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildInputLabel(String label, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildTextField({required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: TextField(
        controller: _teamNameController,
        decoration: InputDecoration(
          hintText: 'Nama Tim',
          hintStyle: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14),
      ),
    );
  }

  Widget _buildProjectDropdown({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProjectId,
          hint: Text(
            'Opsional: Terapkan ke Proyek',
            style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 14),
          ),
          dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
          isExpanded: true,
          style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
          onChanged: (String? newValue) {
            setState(() {
              _selectedProjectId = newValue;
            });
          },
          items: _projects.map<DropdownMenuItem<String>>((Map<String, dynamic> project) {
            return DropdownMenuItem<String>(
              value: project['id'] as String,
              child: Text(project['name'] as String),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTagsInput({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedMembers.map((m) => _buildTagChip(m, isDark: isDark)).toList(),
          ),
          if (_selectedMembers.isNotEmpty) const SizedBox(height: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              hint: Text(
                'Tambah anggota ke tim...',
                style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, fontSize: 14),
              ),
              dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
              icon: Icon(Icons.add, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
              items: _availableMembers.map((member) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: member,
                  child: Text(member['name'] as String, style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain)),
                );
              }).toList(),
              onChanged: (member) {
                if (member != null) _addMember(member);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(Map<String, dynamic> member, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 4),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppDarkColors.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            member['name'] as String,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _removeMember(member),
            child: Icon(
              Icons.close,
              size: 16,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}