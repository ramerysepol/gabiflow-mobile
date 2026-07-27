import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';

enum PrimaryButtonVariant { primary, secondary, danger }

/// Botão primário com estados loading/disabled, haptic e scale press.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = PrimaryButtonVariant.primary,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final PrimaryButtonVariant variant;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool disabled = onPressed == null || isLoading;

    return _ScaleOnPress(
      onPressed: disabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: 52,
        child: _buildButton(context, cs, disabled),
      ),
    );
  }

  Widget _buildButton(BuildContext context, ColorScheme cs, bool disabled) {
    final content = _buildContent(context, cs);

    switch (variant) {
      case PrimaryButtonVariant.primary:
        return FilledButton(
          onPressed: disabled ? null : () { HapticFeedback.lightImpact(); onPressed!(); },
          child: content,
        );
      case PrimaryButtonVariant.secondary:
        return OutlinedButton(
          onPressed: disabled ? null : () { HapticFeedback.lightImpact(); onPressed!(); },
          child: content,
        );
      case PrimaryButtonVariant.danger:
        return FilledButton(
          onPressed: disabled ? null : () { HapticFeedback.lightImpact(); onPressed!(); },
          style: FilledButton.styleFrom(
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dangerDark
                    : AppColors.dangerLight,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dangerDark
                        : AppColors.dangerLight)
                    .withValues(alpha: 0.5),
          ),
          child: content,
        );
    }
  }

  Widget _buildContent(BuildContext context, ColorScheme cs) {
    if (isLoading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Label invisível para manter largura
          Opacity(
            opacity: 0,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == PrimaryButtonVariant.secondary
                  ? cs.primary
                  : Colors.white,
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}

/// Aplica scale 0.97 ao ser pressionado.
class _ScaleOnPress extends StatefulWidget {
  const _ScaleOnPress({required this.child, this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  State<_ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<_ScaleOnPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.accelerate,
    lowerBound: 0.97,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed != null
          ? (_) => _controller.reverse()
          : null,
      onTapUp: widget.onPressed != null
          ? (_) => _controller.forward()
          : null,
      onTapCancel: widget.onPressed != null
          ? () => _controller.forward()
          : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) =>
            Transform.scale(scale: _controller.value, child: child),
        child: widget.child,
      ),
    );
  }
}
