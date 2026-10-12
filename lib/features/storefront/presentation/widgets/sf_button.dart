import 'package:flutter/material.dart';
import '../theme/sf_inherited_theme.dart';

class SfButton extends StatelessWidget {
  final String       label;
  final VoidCallback? onPressed;
  final bool         outlined;
  final bool         inverted; // white bg, primary text — for use on colored backgrounds
  final bool         small;
  final Widget?      icon;

  const SfButton({
    super.key,
    required this.label,
    this.onPressed,
    this.outlined  = false,
    this.inverted  = false,
    this.small     = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final t      = StorefrontTheme.of(context);
    final radius = BorderRadius.circular(t.buttonRadius);
    final vPad   = small ? 10.0 : 14.0;
    final hPad   = small ? 18.0 : 28.0;
    final fSize  = small ? 13.0 : 15.0;

    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          inverted ? Colors.white
          : outlined ? Colors.transparent
          : states.contains(WidgetState.disabled)
            ? t.primary.withAlpha(102)
            : t.primary),
      foregroundColor: WidgetStateProperty.all(
          inverted ? t.primary
          : outlined ? t.primary : t.primaryFg),
      overlayColor: WidgetStateProperty.all(
          (outlined ? t.primary : t.primaryFg).withAlpha(20)),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(
        borderRadius: radius,
        side: outlined
            ? BorderSide(color: t.primary, width: 1.5)
            : BorderSide.none,
      )),
      padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: hPad, vertical: vPad)),
      textStyle: WidgetStateProperty.all(TextStyle(
        fontSize:      fSize,
        fontWeight:    t.headingWeight,
        letterSpacing: t.uppercaseLabels ? 0.8 : 0,
      )),
      elevation: WidgetStateProperty.all(0),
    );

    final labelWidget = t.uppercaseLabels
        ? Text(label.toUpperCase()) : Text(label);

    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style:     style,
        icon:      icon!,
        label:     labelWidget,
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style:     style,
      child:     labelWidget,
    );
  }
}
