import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match3_game/core/di/providers.dart';
import 'package:match3_game/core/localization/app_strings.dart';
import 'package:match3_game/core/theme/design_tokens.dart';
import 'package:match3_game/core/theme/gem_palette.dart';
import 'package:match3_game/features/game/domain/models/piece.dart';
import 'package:match3_game/features/levels/presentation/providers/level_providers.dart';
import 'package:match3_game/features/settings/domain/models/settings_model.dart';

// Full configuration screen managing audio, haptics, color-blind mode,
// appearance themes, languages, and transaction restoration.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value ?? const AppSettings();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF16152B),
      appBar: AppBar(
        title: Text(
          strings.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E38),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // AUDIO & HAPTICS
          _buildSectionHeader(
            icon: Icons.volume_up,
            title: strings.audioSection,
            color: Colors.cyanAccent,
          ),
          _buildCard(
            children: [
              SwitchListTile(
                title: Text(
                  strings.soundEffects,
                  style: const TextStyle(color: Colors.white),
                ),
                secondary: const Icon(Icons.music_note, color: Colors.cyanAccent),
                value: settings.soundEnabled,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).updateSound(val);
                  // Preview: play tap sound through service (which now has the new state).
                  if (val) ref.read(audioServiceProvider).playButtonTap();
                },
              ),
              const Divider(color: Colors.white12),
              SwitchListTile(
                title: Text(
                  strings.backgroundMusic,
                  style: const TextStyle(color: Colors.white),
                ),
                secondary: const Icon(Icons.surround_sound, color: Colors.cyanAccent),
                value: settings.musicEnabled,
                onChanged: (val) =>
                    ref.read(settingsProvider.notifier).updateMusic(val),
              ),
              const Divider(color: Colors.white12),
              SwitchListTile(
                title: Text(
                  strings.hapticFeedback,
                  style: const TextStyle(color: Colors.white),
                ),
                secondary: const Icon(Icons.vibration, color: Colors.cyanAccent),
                value: settings.hapticsEnabled,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).updateHaptics(val);
                  // Preview: button tap goes through service (haptic guard now updated).
                  if (val) ref.read(audioServiceProvider).playButtonTap();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ACCESSIBILITY & COLOR-BLIND MODE
          _buildSectionHeader(
            icon: Icons.accessibility_new,
            title: strings.accessibilitySection,
            color: Colors.amberAccent,
          ),
          _buildCard(
            children: [
              SwitchListTile(
                title: Text(
                  strings.colorBlindMode,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  strings.colorBlindDesc,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                secondary: const Icon(Icons.visibility, color: Colors.amberAccent),
                value: settings.colorBlindMode,
                onChanged: (val) => ref
                    .read(settingsProvider.notifier)
                    .updateColorBlindMode(val),
              ),
              // Live Swatch Preview
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final piece in PieceType.values)
                      _buildGemPreview(piece, settings.colorBlindMode),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        //  const SizedBox(height: AppSpacing.lg),

          // APPEARANCE & THEME
/*          _buildSectionHeader(
            icon: Icons.palette,
            title: strings.appearanceSection,
            color: Colors.purpleAccent,
          ),
          _buildCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.themeMode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AppThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: AppThemeMode.system,
                          label: Text(strings.themeSystem),
                          icon: const Icon(Icons.brightness_auto),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.light,
                          label: Text(strings.themeLight),
                          icon: const Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: AppThemeMode.dark,
                          label: Text(strings.themeDark),
                          icon: const Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {settings.theme},
                      onSelectionChanged: (Set<AppThemeMode> newSelection) {
                        ref
                            .read(settingsProvider.notifier)
                            .updateTheme(newSelection.first);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // LANGUAGE (RTL SAFE)
          _buildSectionHeader(
            icon: Icons.language,
            title: strings.languageSection,
            color: Colors.greenAccent,
          ),
          _buildCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(
                      value: AppLanguage.english,
                      label: Text('English (US)'),
                    ),
                    ButtonSegment(
                      value: AppLanguage.urdu,
                      label: Text('اردو (Urdu)'),
                    ),
                  ],
                  selected: {settings.language},
                  onSelectionChanged: (Set<AppLanguage> newSelection) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateLanguage(newSelection.first);
                  },
                ),
              ),
            ],
          ),*/
          const SizedBox(height: AppSpacing.lg),

          // TRANSACTIONS & SYSTEM
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.blueAccent),
                title: Text(
                  strings.restorePurchases,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () async {
                  await ref.read(iapServiceProvider).restorePurchases();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.purchasesRestoredSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: Text(
                  strings.resetProgress,
                  style: const TextStyle(color: Colors.redAccent),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => _confirmResetProgress(context, ref, strings),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ABOUT
          Center(
            child: Column(
              children: [
                Text(
                  strings.appTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.appVersion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildGemPreview(PieceType piece, bool colorBlindMode) {
    final color = GemPalette.gemColor(piece, colorBlindMode: colorBlindMode);
    final shape = GemPalette.gemShape(piece);

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(
              shape == GemShape.circle ? 18 : 6,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              shape.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          shape.name,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  void _confirmResetProgress(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: Text(
          strings.resetProgressConfirmTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          strings.resetProgressConfirmDesc,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final storage = ref.read(storageServiceProvider);
              await storage.clear();
              await ref.read(levelProgressProvider.notifier).refresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.progressResetSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222040),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

