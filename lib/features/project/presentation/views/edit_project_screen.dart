import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import '../../data/models/project_model.dart';
import '../providers/project_provider.dart';

class EditProjectScreen extends ConsumerStatefulWidget {
  final ProjectModel project;

  const EditProjectScreen({super.key, required this.project});

  @override
  ConsumerState<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends ConsumerState<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _githubController;

  final List<String> _availableLabels = ['Backend', 'Design System', 'Frontend', 'DevOps'];
  late final List<String> _selectedLabels;

  late String _selectedCategory;
  final List<String> _categories = ['Teknologi', 'Pemasaran', 'Operasional', 'Keuangan', 'Kreatif/Media', 'Lainnya'];
  final TextEditingController _customCategoryController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descController = TextEditingController(text: widget.project.description);
    _githubController = TextEditingController(text: widget.project.githubRepo);
    
    // Find matching category or set as "Lainnya"
    final matchingCat = _categories.firstWhere(
      (c) => c.toLowerCase() == widget.project.category.toLowerCase(),
      orElse: () => 'Lainnya',
    );
    _selectedCategory = matchingCat;
    if (_selectedCategory == 'Lainnya') {
      _customCategoryController.text = widget.project.category;
    }
    _selectedLabels = List.from(widget.project.labels);

    // Ensure initial label is in available list
    for (final label in _selectedLabels) {
      if (!_availableLabels.contains(label)) {
        _availableLabels.add(label);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _githubController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _showAddLabelDialog() {
    final TextEditingController labelInputController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Label Baru'),
          content: TextField(
            controller: labelInputController,
            decoration: const InputDecoration(
              hintText: 'Nama label (misal: Security)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final label = labelInputController.text.trim();
                if (label.isNotEmpty) {
                  setState(() {
                    if (!_availableLabels.contains(label)) {
                      _availableLabels.add(label);
                    }
                    if (!_selectedLabels.contains(label)) {
                      _selectedLabels.add(label);
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final finalCategory = _selectedCategory == 'Lainnya'
          ? _customCategoryController.text.trim()
          : _selectedCategory;

      final updatedProject = widget.project.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        labels: _selectedLabels,
        githubRepo: _githubController.text.trim(),
        category: finalCategory,
      );

      await ref.read(projectListProvider.notifier).updateProject(updatedProject);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perubahan proyek berhasil disimpan!'),
            backgroundColor: AppColors.successText,
          ),
        );
        // Pop and return updated project to refresh detail screen
        Navigator.pop(context, updatedProject);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan perubahan: $e'),
            backgroundColor: AppColors.alertText,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
              const ProfileAvatarButton(),
              const SizedBox(width: 20),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  Row(
                    children: [
                      Text(
                        'MANAJEMEN PROYEK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EDIT PROYEK',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Edit Proyek',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ubah deskripsi, label, kategori, dan repositori proyek Anda.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.surface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, width: 0.5),
                      boxShadow: isDark ? null : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('NAMA PROYEK *', isDark: isDark),
                        _buildTextField(
                          _nameController,
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama proyek tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildInputLabel('DESKRIPSI', isDark: isDark),
                        _buildTextArea(_descController, isDark: isDark),
                        const SizedBox(height: 20),

                        _buildInputLabel('KATEGORI PROYEK *', isDark: isDark),
                        _buildCategoryDropdown(isDark: isDark),
                        if (_selectedCategory == 'Lainnya') ...[
                          const SizedBox(height: 12),
                          _buildTextField(
                            _customCategoryController,
                            isDark: isDark,
                            validator: (value) {
                              if (_selectedCategory == 'Lainnya' && (value == null || value.trim().isEmpty)) {
                                return 'Kategori kustom tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),

                        _buildInputLabel('PILIH LABEL', isDark: isDark),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final label in _availableLabels)
                              _buildChip(
                                label,
                                _selectedLabels.contains(label),
                                _getLabelColor(label),
                                isDark: isDark,
                                onTap: () {
                                  setState(() {
                                    if (_selectedLabels.contains(label)) {
                                      _selectedLabels.remove(label);
                                    } else {
                                      _selectedLabels.add(label);
                                    }
                                  });
                                },
                              ),
                            _buildAddLabelChip(isDark: isDark, onTap: _showAddLabelDialog),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildInputLabel('TAUTAN REPOSITORI GITHUB', isDark: isDark),
                        _buildTextFieldWithIcon(
                          _githubController,
                          Icons.link,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pastikan repositori dapat diakses oleh anggota proyek.',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProject,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppColors.primary : AppColors.buttonDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Simpan Proyek',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Card 1
                  _buildInfoCard(
                    'Panduan',
                    'Manajer harus menentukan milestone yang jelas pada langkah selanjutnya untuk memastikan keselarasan tim sejak hari pertama.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  // Info Card 2
                  _buildInfoCard(
                    'Visibilitas',
                    'Secara default, proyek baru bersifat privat. Anda dapat mengubah pengaturan visibilitas setelah proyek dibuat.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
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
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {required bool isDark, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14),
    );
  }

  Widget _buildTextFieldWithIcon(TextEditingController controller, IconData icon, {required bool isDark, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: Icon(icon, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary, size: 20),
      ),
      style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14),
    );
  }

  Widget _buildTextArea(TextEditingController controller, {required bool isDark, String? Function(String?)? validator}) {
    return SizedBox(
      height: 120,
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
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
          contentPadding: const EdgeInsets.all(16),
        ),
        style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain, fontSize: 14),
      ),
    );
  }

  Widget _buildCategoryDropdown({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.background : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          dropdownColor: isDark ? AppDarkColors.surface : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
          icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white : Colors.black),
          isExpanded: true,
          items: _categories.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCategory = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, Color dotColor, {required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? AppColors.primary.withValues(alpha: 0.2) : AppColors.lightBlueSelection) 
              : (isDark ? AppDarkColors.background : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppDarkColors.border : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : (isDark ? AppDarkColors.textMain : AppColors.textMain),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.close, size: 14, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddLabelChip({required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppDarkColors.background : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              'Add Label',
              style: TextStyle(fontSize: 12, color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLabelColor(String label) {
    switch (label) {
      case 'Urgent':
        return AppColors.primary;
      case 'Backend':
        return const Color(0xFF2E7D32);
      case 'Design System':
        return const Color(0xFFA1887F);
      case 'Frontend':
        return const Color(0xFF1976D2);
      case 'DevOps':
        return const Color(0xFF7B1FA2);
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildInfoCard(String title, String content, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
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
    );
  }
}
