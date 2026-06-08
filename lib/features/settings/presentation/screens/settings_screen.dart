import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/storage/cache_keys.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/section_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool vibrationEnabled = true;
  String language = 'English';

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);

    return AppPageScaffold(
      title: 'Settings',
      subtitle: 'Mobile experience preferences',
      body: Column(
        children: [
          SectionCard(
            title: 'Appearance',
            child: _CustomSwitchTile(
              title: 'Dark mode',
              subtitle: isDarkMode
                  ? 'Dark theme enabled'
                  : 'Light theme enabled',
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Notifications & feedback',
            child: Column(
              children: [
                _CustomSwitchTile(
                  title: 'Notifications',
                  value: notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => notificationsEnabled = value),
                ),
                const SizedBox(height: 12),
                _CustomSwitchTile(
                  title: 'Sound',
                  value: soundEnabled,
                  onChanged: (value) => setState(() => soundEnabled = value),
                ),
                const SizedBox(height: 12),
                _CustomSwitchTile(
                  title: 'Vibration',
                  value: vibrationEnabled,
                  onChanged: (value) =>
                      setState(() => vibrationEnabled = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Language',
            subtitle: 'Placeholder localization selector',
            child: DropdownButtonFormField<String>(
              initialValue: language,
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'French', child: Text('French')),
                DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => language = value);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Account',
            child: InkWell(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(CacheKeys.rememberMe, false);
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                context.go(RouteNames.loginPath);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: theme.colorScheme.primary),
                    const SizedBox(width: 16),
                    Text(
                      'Logout',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        inherit: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomSwitchTile extends StatelessWidget {
  const _CustomSwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  inherit: false,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                    inherit: false,
                  ),
                ),
              ],
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
