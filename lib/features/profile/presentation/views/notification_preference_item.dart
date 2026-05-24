import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/colors.dart';

class NotificationPreferenceItem extends StatefulWidget {
  final bool isDark;

  const NotificationPreferenceItem({super.key, required this.isDark});

  @override
  State<NotificationPreferenceItem> createState() => _NotificationPreferenceItemState();
}

class _NotificationPreferenceItemState extends State<NotificationPreferenceItem> {
  bool _isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = prefs.getBool('enable_notifications') ?? true;
    });
  }

  Future<void> _togglePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enable_notifications', value);
    setState(() {
      _isNotificationEnabled = value;
    });

    if (mounted) {
      if (value) {
        // Simulasi membunyikan notifikasi dengan package (misal audioplayers)
        // Di sini kita cuma memberi tahu pengguna
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikasi suara diaktifkan. Akan berbunyi sesuai bawaan HP.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifikasi suara dinonaktifkan.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: widget.isDark ? AppDarkColors.background : AppColors.inputBackground,
            child: Icon(Icons.notifications_active, color: widget.isDark ? AppDarkColors.textMain : AppColors.textMain, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifikasi Suara', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14, 
                    color: widget.isDark ? AppDarkColors.textMain : AppColors.textMain
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  'Beri tahu saya saat ada pesan baru', 
                  style: TextStyle(
                    fontSize: 12, 
                    color: widget.isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                  )
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isNotificationEnabled,
            onChanged: _togglePreference,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
