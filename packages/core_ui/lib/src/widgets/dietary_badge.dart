import 'package:flutter/material.dart';
import 'package:models/models.dart';

/// Renders an FSSAI-standard dietary indicator for the given [DietaryType].
///
/// Visual rules (FSSAI square-border convention):
/// - [DietaryType.veg]    → green square border + green filled dot
/// - [DietaryType.nonVeg] → red square border + red filled dot
/// - [DietaryType.vegan]  → green square border + green leaf icon
/// - [DietaryType.egg]    → yellow square border + yellow filled dot
class DietaryBadge extends StatelessWidget {
  const DietaryBadge({required this.type, super.key});

  final DietaryType type;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel(type),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CustomPaint(
          painter: _FssaiPainter(type: type),
        ),
      ),
    );
  }

  String _semanticLabel(DietaryType type) {
    switch (type) {
      case DietaryType.veg:
        return 'Vegetarian';
      case DietaryType.nonVeg:
        return 'Non-vegetarian';
      case DietaryType.vegan:
        return 'Vegan';
      case DietaryType.egg:
        return 'Contains egg';
    }
  }
}

class _FssaiPainter extends CustomPainter {
  const _FssaiPainter({required this.type});

  final DietaryType type;

  // Canonical FSSAI colors
  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFD32F2F);
  static const _yellow = Color(0xFFF9A825);

  Color get _color {
    switch (type) {
      case DietaryType.veg:
        return _green;
      case DietaryType.nonVeg:
        return _red;
      case DietaryType.vegan:
        return _green;
      case DietaryType.egg:
        return _yellow;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final color = _color;
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Square border with slight rounding
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, borderPaint);

    if (type == DietaryType.vegan) {
      // Small leaf shape for vegan — draw two arcs
      final leafPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final cx = size.width / 2;
      final cy = size.height / 2;
      final path = Path()
        ..moveTo(cx, cy + size.height * 0.22)
        ..quadraticBezierTo(
            cx - size.width * 0.22, cy, cx, cy - size.height * 0.22)
        ..quadraticBezierTo(
            cx + size.width * 0.22, cy, cx, cy + size.height * 0.22)
        ..close();
      canvas.drawPath(path, leafPaint);
    } else {
      // Filled circle dot in the centre
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width * 0.28,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_FssaiPainter old) => old.type != type;
}
