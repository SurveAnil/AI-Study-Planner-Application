import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Top-level metric card for consistency, streak, and efficiency.
/// Styled according to "The Intellectual Nocturne" design system.
class ProgressStatisticsCard extends StatefulWidget {
  final double consistencyIndex;
  final int streak;
  final double efficiency;

  const ProgressStatisticsCard({
    super.key,
    required this.consistencyIndex,
    required this.streak,
    required this.efficiency,
  });

  @override
  State<ProgressStatisticsCard> createState() => _ProgressStatisticsCardState();
}

class _ProgressStatisticsCardState extends State<ProgressStatisticsCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _Stat(
                  label: "Consistency",
                  value: "${widget.consistencyIndex.toInt()}%",
                  icon: Symbols.speed_rounded,
                  color: cs.primary,
                ),
              ),
              _GhostDivider(),
              Expanded(
                child: _Stat(
                  label: "Streak",
                  value: "${widget.streak}",
                  unit: "Days",
                  icon: Symbols.local_fire_department_rounded,
                  color: cs.tertiary,
                ),
              ),
              _GhostDivider(),
              Expanded(
                child: _Stat(
                  label: "Efficiency",
                  value: widget.efficiency.toStringAsFixed(1),
                  unit: "Idx",
                  icon: Symbols.bolt_rounded,
                  color: cs.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ghost divider: outlineVariant at 20% opacity per spec
class _GhostDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 64,
      color: cs.outlineVariant.withOpacity(0.20),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color color;

  const _Stat({
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Ambient glow icon (RadialGradient, not BoxShadow) ──────────
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 18, fill: 1),
                  const SizedBox(width: 5),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── Numeric value ──────────────────────────────────────────────
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 3),
                Text(
                  unit!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
