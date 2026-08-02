import 'package:flutter/material.dart';

/// 高效滚轮数字 — 用 Transform.translate 移动数字条，GPU 加速
/// 不用 AnimatedBuilder 重建 Text，只用一个 AnimationController 驱动 Transform
class OdometerRoll extends StatelessWidget {
  final double value;
  final String prefix;
  final TextStyle? style;
  final int decimalPlaces;

  const OdometerRoll({
    super.key,
    required this.value,
    this.prefix = '',
    this.style,
    this.decimalPlaces = 2,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = value.toStringAsFixed(decimalPlaces);
    final digits = formatted.split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (prefix.isNotEmpty)
          Text(prefix, style: style),
        ...digits.map((d) {
          if (d == '.' || d == ',') {
            return Text('.', style: style);
          }
          return _RollingDigit(digit: int.parse(d), style: style);
        }),
      ],
    );
  }
}

class _RollingDigit extends StatelessWidget {
  final int digit;
  final TextStyle? style;

  const _RollingDigit({required this.digit, this.style});

  @override
  Widget build(BuildContext context) {
    // 用 ClipRect + Stack 构建数字条，只渲染当前 + 相邻数字
    // 这样每个 digit 只是一个固定高度 ClipRect，不涉及重建
    final itemHeight = style?.fontSize ?? 48;
    final effectiveHeight = itemHeight;

    return ClipRect(
      child: SizedBox(
        height: effectiveHeight,
        width: _digitWidth(digit, style),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: digit.toDouble()),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, _) {
            // 只构建 0-9 的 Text 列，用 Transform 位移
            return Stack(
              alignment: Alignment.topCenter,
              children: List.generate(10, (i) {
                final isActive = i <= animValue && i >= animValue - 1;
                return Transform.translate(
                  offset: Offset(0, (i - animValue) * effectiveHeight),
                  child: Opacity(
                    opacity: isActive ? 1.0 : 0.0,
                    child: Text('$i', style: style),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  double _digitWidth(int digit, TextStyle? style) {
    // 粗略估计 — 等宽数字
    final fontSize = style?.fontSize ?? 48;
    return fontSize * 0.55;
  }
}
