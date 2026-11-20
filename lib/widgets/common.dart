import 'package:flutter/material.dart';

import '../theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/logo.png',
        width: size, height: size, semanticLabel: 'Logo AYOSEHAT');
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 20, this.light = false});
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: 'AYO',
            style: TextStyle(color: light ? Colors.white : AppColors.navy)),
        TextSpan(
            text: 'SEHAT',
            style: TextStyle(color: light ? AppColors.mint : AppColors.green)),
      ]),
      style: TextStyle(
          fontSize: size, fontWeight: FontWeight.w900, letterSpacing: -.3),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.navy)),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text,
      {super.key,
      this.fg = AppColors.green,
      this.bg = AppColors.softGreen,
      this.icon});
  final String text;
  final Color fg;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
        ],
        Text(text,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor = AppColors.line,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.softGrey,
      borderColor: AppColors.softGrey,
      child: Row(children: [
        Icon(icon, color: AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: AppColors.muted, height: 1.4))),
      ]),
    );
  }
}
