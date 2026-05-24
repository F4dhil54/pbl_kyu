import 'package:flutter/material.dart';
import 'package:pbl_kyu/shared/widgets/profile_avatar.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/theme_mode.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

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
              icon: Icon(
                Icons.close, 
                color: isDark ? AppDarkColors.textMain : AppColors.textMain
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Buat Pembaruan',
              style: TextStyle(
                color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Post action
                  Navigator.pop(context);
                },
                child: Text(
                  'Posting',
                  style: TextStyle(
                    color: isDark ? Colors.amberAccent : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ProfileAvatar(radius: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        maxLines: 5,
                        style: TextStyle(
                          color: isDark ? AppDarkColors.textMain : AppColors.textMain,
                          fontFamily: 'Inter',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tulis ide atau pembaruan proyek...',
                          hintStyle: TextStyle(
                            color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Toolbar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark ? AppDarkColors.border : AppColors.border, 
                        width: 0.5
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.image_outlined, 
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.attach_file, 
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.link, 
                          color: isDark ? AppDarkColors.textSecondary : AppColors.textSecondary
                        ),
                        onPressed: () {},
                      ),
                    ],
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
