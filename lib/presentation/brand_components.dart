import 'package:flutter/material.dart';

import 'theme.dart';

class BrandSectionHeader extends StatelessWidget {
  const BrandSectionHeader(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext c) {
    final scheme = Theme.of(c).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Brand.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(c).textTheme.headlineMedium),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .35),
              ),
            ),
            child: ExcludeSemantics(
              child: Image.asset(Brand.logo, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

class RoadDivider extends StatelessWidget {
  const RoadDivider({super.key});
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 19),
    child: SizedBox(
      height: 4,
      width: double.infinity,
      child: CustomPaint(
        painter: _RoadPainter(Theme.of(c).colorScheme.outlineVariant),
      ),
    ),
  );
}

class _RoadPainter extends CustomPainter {
  _RoadPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 14) {
      canvas.drawLine(
        Offset(x, 2),
        Offset((x + 5).clamp(0, size.width), 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.color != color;
}

class BrandNavGlyph extends StatelessWidget {
  const BrandNavGlyph(this.section, {super.key, required this.color});
  final int section;
  final Color color;
  @override
  Widget build(BuildContext c) => Center(
    child: SizedBox(
      width: 25,
      height: 25,
      child: CustomPaint(painter: _GlyphPainter(section, color)),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.section, this.color);
  final int section;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    void road() {
      canvas.drawLine(const Offset(12, 13), const Offset(12, 15), p);
      canvas.drawLine(const Offset(12, 18), const Offset(12, 20), p);
    }

    switch (section) {
      case 0:
        canvas.drawPath(
          Path()
            ..moveTo(3, 10)
            ..lineTo(12, 3)
            ..lineTo(21, 10)
            ..moveTo(5, 9)
            ..lineTo(5, 21)
            ..lineTo(19, 21)
            ..lineTo(19, 9),
          p,
        );
        road();
      case 1:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 5, 18, 16),
            const Radius.circular(4),
          ),
          p,
        );
        canvas.drawLine(const Offset(3, 10), const Offset(21, 10), p);
        canvas.drawLine(const Offset(8, 3), const Offset(8, 7), p);
        canvas.drawLine(const Offset(16, 3), const Offset(16, 7), p);
        canvas.drawCircle(const Offset(8, 15), 1.2, fill);
        canvas.drawPath(
          Path()
            ..moveTo(13, 16)
            ..lineTo(15, 18)
            ..lineTo(19, 14),
          p,
        );
      case 2:
        canvas.drawCircle(const Offset(12, 12), 9, p);
        canvas.drawArc(const Rect.fromLTWH(6, 6, 12, 12), 3.5, 2.4, false, p);
        canvas.drawLine(const Offset(4, 13), const Offset(9, 15), p);
        canvas.drawLine(const Offset(20, 13), const Offset(15, 15), p);
        canvas.drawLine(const Offset(12, 12), const Offset(12, 14), p);
        canvas.drawLine(const Offset(12, 17), const Offset(12, 20), p);
      case 3:
        canvas.drawPath(
          Path()
            ..moveTo(5, 17)
            ..lineTo(7, 14)
            ..lineTo(7, 9)
            ..cubicTo(7, 3, 17, 3, 17, 9)
            ..lineTo(17, 14)
            ..lineTo(19, 17)
            ..close(),
          p,
        );
        canvas.drawArc(const Rect.fromLTWH(9, 17, 6, 5), 0, 3.14, false, p);
        canvas.drawCircle(
          const Offset(18, 5),
          2,
          Paint()..color = Brand.orange,
        );
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 18),
            const Radius.circular(4),
          ),
          p,
        );
        canvas.drawLine(const Offset(3, 8), const Offset(21, 8), p);
        canvas.drawOval(const Rect.fromLTWH(6, 11, 4, 7), p);
        canvas.drawOval(const Rect.fromLTWH(14, 11, 4, 7), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      section != oldDelegate.section || color != oldDelegate.color;
}
