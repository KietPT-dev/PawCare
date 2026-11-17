import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_formatters.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: Theme.of(c).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Theme.of(c).colorScheme.onSurface))),
        if (action != null)
          TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: Text(action!,
                  style: const TextStyle(
                      color: AppColors.teal,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)))
      ]));
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) => Semantics(
      button: onTap != null,
      child: LiquidGlassCard(onTap: onTap, child: child));
}

class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.blur = 20,
    this.tintColor,
    this.borderWidth = 1.2,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? tintColor;
  final double borderWidth;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = tintColor ??
        (isDark
            ? AppColors.darkSurface.withValues(alpha: .72)
            : Colors.white.withValues(alpha: .78));
    final borderColor = isDark
        ? Colors.white.withValues(alpha: .14)
        : Colors.white.withValues(alpha: .92);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: baseColor,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: gradient ??
                    LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.09 : 0.28),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                border: Border.all(color: borderColor, width: borderWidth),
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFF163832))
                        .withValues(alpha: isDark ? .28 : .06),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? .04 : .22),
                    blurRadius: 1,
                    spreadRadius: -1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidAmbientBackground extends StatelessWidget {
  const LiquidAmbientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: isDark ? AppColors.darkCanvas : AppColors.canvas,
          ),
        ),
        // Ambient color bloom - Top Right (Cyan/Teal)
        Positioned(
          top: -60,
          right: -60,
          width: 300,
          height: 300,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppColors.teal : AppColors.cyan)
                        .withValues(alpha: isDark ? .18 : .24),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Ambient color bloom - Mid Left (Mint / Light Teal)
        Positioned(
          top: 220,
          left: -80,
          width: 280,
          height: 280,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppColors.cyan : AppColors.mint)
                        .withValues(alpha: isDark ? .14 : .45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Ambient color bloom - Bottom Right (Coral / Peach highlight)
        Positioned(
          bottom: 100,
          right: -50,
          width: 250,
          height: 250,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.coral.withValues(alpha: isDark ? .08 : .12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.badge,
    this.tooltip,
  });
  final Widget icon;
  final VoidCallback onPressed;
  final double size;
  final Widget? badge;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = LiquidGlassCard(
      padding: EdgeInsets.zero,
      radius: size / 2,
      blur: 16,
      child: SizedBox(
        width: size,
        height: size,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Center(child: icon),
        ),
      ),
    );
    if (badge != null) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(right: 0, top: 0, child: badge!),
        ],
      );
    }
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.color = AppColors.teal});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2)));
}

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final visual = AppFormatters.status(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: visual.color.withValues(alpha: .10),
          border: Border.all(color: visual.color.withValues(alpha: .28)),
          borderRadius: BorderRadius.circular(10)),
      child: Text(visual.label,
          style: TextStyle(
              color: visual.color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.2)),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 220 + (index.clamp(0, 6) * 45)),
      tween: Tween(begin: 0, end: 1),
      builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)), child: child)),
      child: child);
}

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({super.key, this.title, this.actions});
  final String? title;
  final List<Widget>? actions;
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext c) => AppBar(
        title: title != null
            ? Text(title!,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 18))
            : null,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: actions,
      );
}

class LiquidModalSheet extends StatelessWidget {
  const LiquidModalSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.headerAction,
    this.maxHeightFraction = 0.85,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? headerAction;
  final double maxHeightFraction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final height = MediaQuery.sizeOf(context).height * maxHeightFraction;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: height + keyboard),
      margin: EdgeInsets.only(bottom: keyboard),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: onSurface,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (headerAction != null) headerAction!,
                  ],
                ),
              ),
            Flexible(
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

