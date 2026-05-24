import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../providers/notification_provider.dart';

class ComposeMessageScreen extends ConsumerStatefulWidget {
  const ComposeMessageScreen({super.key});

  @override
  ConsumerState<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends ConsumerState<ComposeMessageScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_emailController.text.isEmpty || _subjectController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua kolom.'), backgroundColor: AppColors.alertText),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(notificationNotifierProvider.notifier).sendMessage(
        _emailController.text.trim(),
        _subjectController.text.trim(),
        _bodyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesan berhasil dikirim!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesan: $e'), backgroundColor: AppColors.alertText),
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
              'Tulis Pesan',
              style: TextStyle(
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.send, color: AppColors.primary),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Kepada
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Kepada',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                              decoration: InputDecoration(
                                hintText: 'email@contoh.com',
                                hintStyle: TextStyle(
                                  color: isDark ? AppDarkColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary.withValues(alpha: 0.5),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: isDark ? AppDarkColors.border : AppColors.border),
                      
                      // Subjek
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Subjek',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _subjectController,
                              style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                              decoration: InputDecoration(
                                hintText: 'Judul Pesan',
                                hintStyle: TextStyle(
                                  color: isDark ? AppDarkColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary.withValues(alpha: 0.5),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(color: isDark ? AppDarkColors.border : AppColors.border),
                      
                      // Isi Pesan
                      Expanded(
                        child: TextField(
                          controller: _bodyController,
                          style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'Tulis pesan...',
                            hintStyle: TextStyle(
                              color: isDark ? AppDarkColors.textSecondary.withValues(alpha: 0.5) : AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
