import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/settings_cubit.dart';
import '../data/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _obscureApiKey = true;
  late final TextEditingController _apiController;
  late final TextEditingController _customModelController;

  static const List<String> _baseModels = [
    'Default (Backend)',
    'google/gemini-2.5-flash-preview-05-20',
    'google/gemini-2.5-pro',
    'anthropic/claude-sonnet-4-5',
    'openai/gpt-4o',
    'deepseek/deepseek-r1',
    'Custom...',
  ];

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController();
    _customModelController = TextEditingController();

    // Initialize controller with current state
    final settings = context.read<SettingsCubit>().state.settings;
    if (settings.openRouterApiKey != null) {
      _apiController.text = settings.openRouterApiKey!;
    }
    if (!_baseModels.contains(settings.aiModel) &&
        settings.aiModel.isNotEmpty) {
      _customModelController.text = settings.aiModel;
    }
  }

  @override
  void dispose() {
    _apiController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: cs.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(
                  width: 40,
                ), // Balance the flex for centering title
                Text(
                  'System Preferences',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: cs.onSurface,
                  ),
                ),
                _PressableIcon(
                  onTap: () {},
                  child: Icon(
                    Symbols.more_vert_rounded,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final settings = state.settings;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            child: Column(
              children: [
                _buildProfileSection(cs),
                const SizedBox(height: 32),
                _buildEngineConfigSection(settings, cs),
                const SizedBox(height: 24),
                _buildQuickStartGuide(cs),
                const SizedBox(height: 32),
                _buildStudyPreferences(cs),
                const SizedBox(height: 32),
                _buildSystemSection(settings, cs),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Section A: Account & AI Identity ───────────────────────────────────────
  Widget _buildProfileSection(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHighest,
                  border: Border.all(
                    color: cs.surfaceContainerLowest,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Icon(
                    Symbols.person_rounded,
                    size: 36,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alex',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scholar Tier',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section B: AI Engine Config ────────────────────────────────────────────
  Widget _buildEngineConfigSection(UserSettings settings, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Symbols.memory_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'AI Engine Configuration',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // RadialGradient glow — avoids rectangular BoxShadow Skia artifacts
        Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.4,
                    colors: [cs.primary.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Model Configuration',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.15),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _baseModels.contains(settings.aiModel)
                            ? settings.aiModel
                            : 'Custom...',
                        isExpanded: true,
                        dropdownColor: cs.surfaceContainerHigh,
                        icon: Icon(
                          Symbols.expand_more_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            if (newValue != 'Custom...') {
                              context.read<SettingsCubit>().updateAiModel(
                                newValue,
                              );
                            } else {
                              context.read<SettingsCubit>().updateAiModel(
                                _customModelController.text.isNotEmpty
                                    ? _customModelController.text
                                    : '',
                              );
                            }
                          }
                        },
                        items: _baseModels.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (!_baseModels.contains(settings.aiModel) ||
                      settings.aiModel.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: cs.outlineVariant.withOpacity(0.15),
                          ),
                        ),
                        child: TextField(
                          controller: _customModelController,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. your/custom-model-id',
                            hintStyle: TextStyle(color: cs.onSurfaceVariant),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (val) =>
                              context.read<SettingsCubit>().updateAiModel(val),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Divider(color: cs.surfaceContainerHighest),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use Persona-Owned API',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bypass standard limits using OpenRouter',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.75,
                        alignment: Alignment.centerRight,
                        child: Switch(
                          value: settings.useCustomApi,
                          onChanged: (val) => context
                              .read<SettingsCubit>()
                              .toggleUseCustomApi(val),
                          activeColor: Colors.white,
                          activeTrackColor: cs.primaryContainer,
                          inactiveThumbColor: cs.onSurface,
                          inactiveTrackColor: cs.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'OpenRouter API Key',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _apiController,
                            obscureText: _obscureApiKey,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: cs.onSurface,
                              letterSpacing: 2.0,
                            ),
                            decoration: InputDecoration(
                              hintText: 'sk-or-v1-...',
                              hintStyle: TextStyle(
                                color: cs.onSurfaceVariant,
                                letterSpacing: 0,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            onChanged: (val) => context
                                .read<SettingsCubit>()
                                .updateOpenRouterApiKey(val),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _obscureApiKey
                                ? Symbols.visibility_rounded
                                : Symbols.visibility_off_rounded,
                            color: cs.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureApiKey = !_obscureApiKey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      final isActive =
                          settings.useCustomApi &&
                          (settings.openRouterApiKey?.isNotEmpty ?? false);
                      final statusColor = isActive
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFF59E0B);
                      final statusText = isActive
                          ? 'CONNECTION ESTABLISHED'
                          : 'DEFAULT ENGINE';
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            isActive ? 'Custom Key Active' : 'Server Default',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Usage Meter',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '85% Approaching Limit',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cs.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: 0.85,
                      minHeight: 6,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.tertiary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStartGuide(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.explore_rounded, color: cs.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Quick Start Guide',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GuideStep(
            numTitle: '1',
            text: 'Visit',
            activeText: 'OpenRouter.ai',
            cs: cs,
          ),
          _GuideStep(
            numTitle: '2',
            text: 'Authenticate via GitHub or Google.',
            cs: cs,
          ),
          _GuideStep(
            numTitle: '3',
            text: 'Generate a new secret API key.',
            cs: cs,
          ),
          _GuideStep(
            numTitle: '4',
            text: 'Deposit credits to activate premium models.',
            cs: cs,
          ),
          _GuideStep(
            numTitle: '5',
            text: 'Paste key above and',
            activeText: 'Ignite.',
            isLast: true,
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _buildStudyPreferences(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Symbols.schedule_rounded, color: cs.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Study Preferences',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
            children: [
              _SettingsTile(
                icon: Symbols.notifications_active_rounded,
                title: 'Notification Windows',
                subtitle: '08:00 - 20:00',
                cs: cs,
                trailing: Icon(
                  Symbols.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              _SettingsTile(
                icon: Symbols.hourglass_empty_rounded,
                title: 'Deep Focus Duration',
                subtitle: '45 Minutes',
                cs: cs,
                trailing: Icon(
                  Symbols.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildSystemSection(UserSettings settings, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Symbols.settings_system_daydream_rounded,
              color: cs.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'System',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
            children: [
              _SettingsTile(
                icon: Symbols.dark_mode_rounded,
                title: 'Midnight Precision Theme',
                subtitle: 'Force Dark UI Elements',
                cs: cs,
                trailing: Switch(
                  value: settings.darkModeEnabled,
                  onChanged: (val) =>
                      context.read<SettingsCubit>().toggleDarkMode(),
                  activeColor: Colors.white,
                  activeTrackColor: cs.primary,
                ),
              ),
              const SizedBox(height: 1),
              _SettingsTile(
                icon: Symbols.cloud_sync_rounded,
                title: 'Cloud Backup',
                subtitle: 'Last synced 2h ago',
                cs: cs,
                trailing: TextButton(
                  onPressed: () {},
                  child: Text(
                    'SYNC NOW',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              _SettingsTile(
                icon: Symbols.delete_rounded,
                title: 'Clear Cache',
                subtitle: '142 MB Used',
                cs: cs,
                trailing: Icon(
                  Symbols.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          ),
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String numTitle;
  final String text;
  final String? activeText;
  final bool isLast;
  final ColorScheme cs;

  const _GuideStep({
    required this.numTitle,
    required this.text,
    required this.cs,
    this.activeText,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    InlineSpan? activeSpan;
    if (activeText != null) {
      activeSpan = TextSpan(
        text: activeText,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w600,
          decoration: numTitle == '1' ? TextDecoration.underline : null,
          decorationColor: cs.primary,
        ),
        recognizer: numTitle == '1'
            ? (TapGestureRecognizer()
                ..onTap = () async {
                  final uri = Uri.parse(
                    'https://openrouter.ai/workspaces/default/keys',
                  );
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                })
            : null,
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  numTitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: cs.outlineVariant.withOpacity(0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text.rich(
                TextSpan(
                  text: '$text ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                  children: [if (activeSpan != null) activeSpan],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final ColorScheme cs;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.cs,
  });

  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurfaceVariant, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _PressableIcon extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableIcon({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Padding(padding: const EdgeInsets.all(8.0), child: child),
    );
  }
}
