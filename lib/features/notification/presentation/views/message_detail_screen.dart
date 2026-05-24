import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

class MessageDetailScreen extends ConsumerStatefulWidget {
  final NotificationModel notification;

  const MessageDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  ConsumerState<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends ConsumerState<MessageDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isReplying = false;
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _toggleReply() {
    setState(() {
      _isReplying = !_isReplying;
    });
  }

  Future<void> _sendReply() async {
    if (_replyController.text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      // The sender of this notification is the receiver of the reply
      await ref.read(notificationNotifierProvider.notifier).replyMessage(
        widget.notification.senderId ?? '',
        widget.notification.judul,
        _replyController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balasan berhasil dikirim!'), backgroundColor: AppColors.success),
        );
        setState(() {
          _isReplying = false;
          _replyController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim balasan: $e'), backgroundColor: AppColors.alertText),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
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
        
        final senderName = widget.notification.senderName ?? 'Sistem KYU';
        final senderAvatar = widget.notification.senderAvatar;
        final senderEmail = widget.notification.senderEmail ?? '';

        return Scaffold(
          backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? AppDarkColors.background : AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back, 
                color: isDark ? AppDarkColors.textMain : AppColors.textMain
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Detail Pesan',
              style: TextStyle(
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.more_vert, 
                  color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                ),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isDark ? AppDarkColors.surface : AppColors.inputBackground,
                      backgroundImage: senderAvatar != null && senderAvatar.isNotEmpty 
                          ? NetworkImage(senderAvatar) 
                          : null,
                      child: senderAvatar == null || senderAvatar.isEmpty
                          ? Icon(
                              Icons.account_circle, 
                              size: 48, 
                              color: isDark ? AppDarkColors.textSecondary : Colors.grey[400]
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                            ),
                          ),
                          if (senderEmail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'ke saya',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      _formatDateDetailed(widget.notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  widget.notification.judul,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.notification.pesan,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Reply Section
                if (widget.notification.tipeNotifikasi == 'pesan' || widget.notification.tipeNotifikasi == 'mention') ...[
                  if (!_isReplying)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _toggleReply,
                        icon: const Icon(Icons.reply),
                        label: const Text(
                          'Balas Pesan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? AppDarkColors.textMain : AppColors.textMain,
                          side: BorderSide(color: isDark ? AppDarkColors.border : AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppDarkColors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppDarkColors.border : AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _replyController,
                            style: TextStyle(color: isDark ? AppDarkColors.textMain : AppColors.textMain),
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Tulis balasan Anda...',
                              hintStyle: TextStyle(
                                color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _toggleReply,
                                child: Text(
                                  'Batal',
                                  style: TextStyle(color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isSending ? null : _sendReply,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: _isSending
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Kirim', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateDetailed(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }
}
