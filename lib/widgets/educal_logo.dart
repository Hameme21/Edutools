import 'package:flutter/material.dart';

class EduCalLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;

  const EduCalLogo({
    super.key,
    this.size = 36,
    this.showText = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * 0.28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: size * 0.75,
                ),
                Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: size * 0.52,
                ),
              ],
            ),
          ),
          if (showText) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Edu',
                      style: TextStyle(
                        fontSize: size * 0.52,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Tools',
                      style: TextStyle(
                        fontSize: size * 0.52,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3B82F6),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  'ACADEMIC TOOLS',
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
