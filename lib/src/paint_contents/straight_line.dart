import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 直线绘制内容
///
/// 连接起点和终点的直线
///
/// Straight Line Drawing Content
///
/// A straight line connecting start and end points
class StraightLine extends PaintContent {
  StraightLine();

  StraightLine.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory StraightLine.fromJson(Map<String, dynamic> data) {
    return StraightLine.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  /// 起始点坐标
  ///
  /// Start point coordinates
  Offset? startPoint;

  /// 结束点坐标
  ///
  /// End point coordinates
  Offset? endPoint;

  @override
  String get contentType => 'StraightLine';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) {
      return;
    }

    canvas.drawLine(startPoint!, endPoint!, paint);
  }

  @override
  StraightLine copy() => StraightLine();

  @override
  bool hitTest(Offset point, {double tolerance = 10.0}) {
    if (startPoint == null || endPoint == null) {
      return false;
    }

    // 计算点到线段的距离
    // Calculate distance from point to line segment
    final double dx = endPoint!.dx - startPoint!.dx;
    final double dy = endPoint!.dy - startPoint!.dy;

    if (dx == 0 && dy == 0) {
      // 起点和终点相同，检查点到起点的距离
      return (point - startPoint!).distance <= tolerance;
    }

    final double t =
        ((point.dx - startPoint!.dx) * dx + (point.dy - startPoint!.dy) * dy) / (dx * dx + dy * dy);

    // 限制 t 在 [0, 1] 范围内，确保投影点在线段上
    final double tClamped = t.clamp(0.0, 1.0);

    // 计算投影点
    final Offset projection = Offset(
      startPoint!.dx + tClamped * dx,
      startPoint!.dy + tClamped * dy,
    );

    // 检查点到投影点的距离
    return (point - projection).distance <= tolerance;
  }

  @override
  Rect? getBounds() {
    if (startPoint == null || endPoint == null) {
      return null;
    }

    final double minX = startPoint!.dx < endPoint!.dx ? startPoint!.dx : endPoint!.dx;
    final double minY = startPoint!.dy < endPoint!.dy ? startPoint!.dy : endPoint!.dy;
    final double maxX = startPoint!.dx > endPoint!.dx ? startPoint!.dx : endPoint!.dx;
    final double maxY = startPoint!.dy > endPoint!.dy ? startPoint!.dy : endPoint!.dy;

    final double padding = paint.strokeWidth / 2;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  @override
  void translate(Offset offset) {
    if (startPoint != null) startPoint = startPoint! + offset;
    if (endPoint != null) endPoint = endPoint! + offset;
  }

  @override
  void scale(double scale, Offset anchor) {
    if (startPoint != null) {
      final Offset relative = startPoint! - anchor;
      startPoint = anchor + relative * scale;
    }
    if (endPoint != null) {
      final Offset relative = endPoint! - anchor;
      endPoint = anchor + relative * scale;
    }
  }

  @override
  void rotate(double angle, Offset anchor) {
    if (startPoint != null) {
      final Offset relative = startPoint! - anchor;
      final double cos = math.cos(angle);
      final double sin = math.sin(angle);
      startPoint = anchor +
          Offset(
            relative.dx * cos - relative.dy * sin,
            relative.dx * sin + relative.dy * cos,
          );
    }
    if (endPoint != null) {
      final Offset relative = endPoint! - anchor;
      final double cos = math.cos(angle);
      final double sin = math.sin(angle);
      endPoint = anchor +
          Offset(
            relative.dx * cos - relative.dy * sin,
            relative.dx * sin + relative.dy * cos,
          );
    }
  }

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint?.toJson(),
      'endPoint': endPoint?.toJson(),
      'paint': paint.toJson(),
    };
  }
}
