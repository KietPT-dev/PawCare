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
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: Theme.of(c).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(c).colorScheme.onSurface))),
        if (action != null)
          TextButton(
              onPressed: onAction,
              child: Text(action!,
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.w800)))
      ]));
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) => Card(
      child: Semantics(
          button: onTap != null,
          child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child:
                  Padding(padding: const EdgeInsets.all(18), child: child))));
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
          borderRadius: BorderRadius.circular(99)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)));
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
          borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(visual.icon, size: 14, color: visual.color),
        const SizedBox(width: 5),
        Text(visual.label,
            style: TextStyle(
                color: visual.color, fontWeight: FontWeight.w700, fontSize: 12))
      ]),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 260 + (index.clamp(0, 6) * 55)),
      tween: Tween(begin: 0, end: 1),
      builder: (_, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)), child: child)),
      child: child);
}
