import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BlindAccessibleButton extends StatelessWidget {
  const BlindAccessibleButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.child,
    this.hint,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final String? hint;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        hint: hint,
        onTap: enabled ? onPressed : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onPressed : null,
          child: AbsorbPointer(child: ExcludeSemantics(child: child)),
        ),
      ),
    );
  }
}

class LargeActionButton extends StatelessWidget {
  const LargeActionButton({
    super.key,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.semanticsLabel,
    this.semanticsHint,
  });

  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget icon;
  final String title;
  final String? subtitle;
  final bool enabled;
  final String? semanticsLabel;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    return BlindAccessibleButton(
      onPressed: onPressed,
      enabled: enabled,
      label: semanticsLabel ?? title,
      hint: semanticsHint,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? () {} : null,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            disabledBackgroundColor: backgroundColor.withValues(alpha: 0.45),
            disabledForegroundColor: foregroundColor.withValues(alpha: 0.8),
            minimumSize: const Size.fromHeight(240),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            padding: const EdgeInsets.all(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    required this.height,
    required this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 18,
  });

  final String imageUrl;
  final double height;
  final double width;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width,
            color: AppTheme.softGray,
            alignment: Alignment.center,
            child: const Icon(Icons.image_outlined, color: Colors.black38),
          );
        },
      ),
    );
  }
}
