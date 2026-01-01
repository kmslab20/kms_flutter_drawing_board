import 'dart:math';

import 'package:flutter/painting.dart';

import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 矩形绘制内容
///
/// 通过起点和终点定义对角线来绘制矩形
///
/// Rectangle Drawing Content
///
/// Draws a rectangle by defining diagonal through start and end points
class Rectangle extends PaintContent {
  Rectangle();

  Rectangle.data({
    required this.startPoint,
    required this.endPoint,
    required Paint paint,
  }) : super.paint(paint);

  factory Rectangle.fromJson(Map<String, dynamic> data) {
    final rect = Rectangle.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      endPoint: jsonToOffset(data['endPoint'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
    rect.rotation = (data['rotation'] ?? 0.0) as double;
    return rect;
  }

  /// 起始点坐标（矩形对角线的一个端点）
  ///
  /// Start point coordinates (one endpoint of the rectangle diagonal)
  Offset? startPoint;

  /// 结束点坐标（矩形对角线的另一个端点）
  ///
  /// End point coordinates (the other endpoint of the rectangle diagonal)
  Offset? endPoint;

  @override
  String get contentType => 'Rectangle';

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  void drawing(Offset nowPoint) => endPoint = nowPoint;

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (startPoint == null || endPoint == null) {
      return;
    }

    if (rotation != 0.0) {
      final Rect? bounds = getOriginalBounds(); // 使用原始边界保持一致
      if (bounds != null) {
        canvas.save();
        canvas.translate(bounds.center.dx, bounds.center.dy);
        canvas.rotate(rotation);
        canvas.translate(-bounds.center.dx, -bounds.center.dy);
      }
    }

    canvas.drawRect(Rect.fromPoints(startPoint!, endPoint!), paint);

    if (rotation != 0.0) {
      canvas.restore();
    }
  }

  @override
  Rectangle copy() => Rectangle();

  @override
  bool hitTest(Offset point, {double tolerance = 10.0}) {
    if (startPoint == null || endPoint == null) {
      return false;
    }

    final Rect rect = Rect.fromPoints(startPoint!, endPoint!);

    // 如果有旋转，需要将测试点进行反向旋转
    // If rotated, need to inverse-rotate the test point
    Offset testPoint = point;
    if (rotation != 0.0) {
      final Rect? bounds = getOriginalBounds(); // 使用原始边界保持一致
      if (bounds != null) {
        final Offset center = bounds.center;
        // 将点转换到以中心为原点的坐标系
        final Offset relative = point - center;
        // 反向旋转
        final double cosAngle = cos(-rotation);
        final double sinAngle = sin(-rotation);
        testPoint = center +
            Offset(
              relative.dx * cosAngle - relative.dy * sinAngle,
              relative.dx * sinAngle + relative.dy * cosAngle,
            );
      }
    }

    final Rect expandedRect = rect.inflate(tolerance);
    return expandedRect.contains(testPoint);
  }

  @override
  Rect? getBounds() {
    if (startPoint == null || endPoint == null) {
      return null;
    }

    final Rect rect = Rect.fromPoints(startPoint!, endPoint!);
    final double padding = paint.strokeWidth / 2;
    final Rect paddedRect = rect.inflate(padding);

    // 如果有旋转，需要计算旋转后的包围盒
    // If rotated, need to calculate rotated bounding box
    if (rotation != 0.0) {
      final Offset center = paddedRect.center;
      final List<Offset> corners = <Offset>[
        paddedRect.topLeft,
        paddedRect.topRight,
        paddedRect.bottomLeft,
        paddedRect.bottomRight,
      ];

      // 旋转所有角点
      final double cosAngle = cos(rotation);
      final double sinAngle = sin(rotation);
      final List<Offset> rotatedCorners = corners.map((Offset corner) {
        final Offset relative = corner - center;
        return center +
            Offset(
              relative.dx * cosAngle - relative.dy * sinAngle,
              relative.dx * sinAngle + relative.dy * cosAngle,
            );
      }).toList();

      // 找到新的边界
      double minX = rotatedCorners[0].dx;
      double minY = rotatedCorners[0].dy;
      double maxX = rotatedCorners[0].dx;
      double maxY = rotatedCorners[0].dy;

      for (final Offset corner in rotatedCorners) {
        if (corner.dx < minX) minX = corner.dx;
        if (corner.dy < minY) minY = corner.dy;
        if (corner.dx > maxX) maxX = corner.dx;
        if (corner.dy > maxY) maxY = corner.dy;
      }

      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }

    return paddedRect;
  }

  @override
  Rect? getOriginalBounds() {
    // 返回未旋转的原始边界（用于选择框）
    // Return original bounds without rotation (for selection box)
    if (startPoint == null || endPoint == null) {
      return null;
    }

    final Rect rect = Rect.fromPoints(startPoint!, endPoint!);
    final double padding = paint.strokeWidth / 2;
    return rect.inflate(padding);
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
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint?.toJson(),
      'endPoint': endPoint?.toJson(),
      'paint': paint.toJson(),
      'rotation': rotation,
    };
  }
}
