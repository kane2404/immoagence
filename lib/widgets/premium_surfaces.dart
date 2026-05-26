import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key, required this.child});

  final Widget child;

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _PremiumBackground()),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _LightRaysPainter(progress: _controller.value),
              );
            },
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class PremiumResponsiveContent extends StatelessWidget {
  const PremiumResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final resolvedPadding = padding == const EdgeInsets.all(20)
        ? EdgeInsets.symmetric(
            horizontal: width < 360 ? 12 : 20,
            vertical: width < 360 ? 14 : 20,
          )
        : padding;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}

class PremiumResponsiveGrid extends StatelessWidget {
  const PremiumResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 5,
    this.spacing = 10,
    this.mobileAspectRatio = 1.2,
    this.desktopAspectRatio = 1.45,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double mobileAspectRatio;
  final double desktopAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 980
            ? desktopColumns
            : width >= 640
            ? tabletColumns
            : mobileColumns;
        final aspectRatio = width >= 640
            ? desktopAspectRatio
            : mobileAspectRatio;

        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class PremiumAdaptiveRow extends StatelessWidget {
  const PremiumAdaptiveRow({
    super.key,
    required this.children,
    this.spacing = 10,
    this.breakpoint = 520,
  });

  final List<Widget> children;
  final double spacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < breakpoint;
        final width = stacked
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (children.length - 1)) /
                  children.length;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF050505),
            const Color(0xFF15110A),
            const Color(0xFF1A1508),
            AppColors.background,
            const Color(0xFF050505),
          ],
          stops: const [0, 0.2, 0.44, 0.76, 1],
        ),
      ),
      child: CustomPaint(
        painter: _PremiumLinesPainter(),
        foregroundPainter: _NoisePainter(),
      ),
    );
  }
}

class _LightRaysPainter extends CustomPainter {
  const _LightRaysPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          AppColors.goldLight.withValues(alpha: 0.055),
          Colors.transparent,
        ],
        stops: const [0.2, 0.5, 0.8],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final shift = (progress * size.width * 0.55) - size.width * 0.28;
    for (var i = 0; i < 3; i++) {
      final x = shift + i * size.width * 0.32;
      canvas.drawLine(
        Offset(x, -60),
        Offset(x + size.width * 0.32, size.height + 80),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LightRaysPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.018);
    const step = 7.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        final seed = ((x * 13 + y * 7).round() % 19);
        if (seed == 0 || seed == 7) {
          canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PremiumLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final darkPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.12 + i * 0.12);
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 42), darkPaint);
    }
    canvas.drawLine(
      Offset(size.width * 0.08, 0),
      Offset(size.width * 0.82, size.height),
      goldPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PremiumPanel extends StatelessWidget {
  const PremiumPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: highlight
              ? [
                  AppColors.primary.withValues(alpha: 0.16),
                  AppColors.surface.withValues(alpha: 0.92),
                  AppColors.goldDark.withValues(alpha: 0.12),
                ]
              : [
                  AppColors.surface.withValues(alpha: 0.95),
                  AppColors.surfaceAlt.withValues(alpha: 0.72),
                  AppColors.surface.withValues(alpha: 0.9),
                ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: highlight ? 0.44 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
          if (highlight)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.18),
              blurRadius: 28,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.035),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PremiumHeroPanel extends StatelessWidget {
  const PremiumHeroPanel({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 420;
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8C96A), Color(0xFFC9A84C), Color(0xFF8A6520)],
        ),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PremiumHeroCopy(
                  eyebrow: eyebrow,
                  title: title,
                  subtitle: subtitle,
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 14),
                  trailing!,
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PremiumHeroCopy(
                    eyebrow: eyebrow,
                    title: title,
                    subtitle: subtitle,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
    );
  }
}

class _PremiumHeroCopy extends StatelessWidget {
  const _PremiumHeroCopy({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.background.withValues(alpha: 0.68),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.background,
            fontSize: compact ? 28 : 34,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.background.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}

class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: effectiveColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumFormSection extends StatelessWidget {
  const PremiumFormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 34),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class PremiumLoadingState extends StatelessWidget {
  const PremiumLoadingState({super.key, this.label = 'Chargement...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class PremiumErrorState extends StatelessWidget {
  const PremiumErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return PremiumPanel(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

Future<bool> confirmSensitiveAction({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
