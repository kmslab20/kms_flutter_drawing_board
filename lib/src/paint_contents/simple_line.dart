import 'dart:math';

import 'package:flutter/painting.dart';

import '../draw_path/draw_path.dart';
import '../paint_extension/ex_offset.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 自由线条绘制内容
///
/// 支持两种绘制模式：
/// 1. 传统路径模式：直接连接绘制点
/// 2. 贝塞尔曲线模式：使用二次贝塞尔曲线平滑连接，提供更流畅的线条效果
///
/// Simple Line Drawing Content
///
/// Supports two drawing modes:
/// 1. Traditional path mode: directly connects drawing points
/// 2. Bezier curve mode: uses quadratic bezier curves for smooth connection, providing smoother line effects
class SimpleLine extends PaintContent {
  SimpleLine({
    /// 最小点距离，用于过滤过近的点，减少数据量
    ///
    /// Minimum point distance for filtering points that are too close, reducing data volume
    this.minPointDistance = 2.0,

    /// 是否使用贝塞尔曲线平滑，默认 true
    /// 设置为 true 可以解决快速绘制时的折线感问题
    ///
    /// Whether to use bezier curve smoothing, default true
    /// Setting to true resolves the jagged line issue when drawing quickly
    this.useBezierCurve = true,
  });

  SimpleLine.data({
    this.minPointDistance = 2.0,
    this.useBezierCurve = false,
    this.points,
    DrawPath? path,
    required Paint paint,
  })  : path = path ?? DrawPath(),
        super.paint(paint);

  factory SimpleLine.fromJson(Map<String, dynamic> data) {
    // 兼容旧版本：如果有 points 就用新方式，否则用旧方式
    final bool hasPoints = data.containsKey('points');

    final SimpleLine line;
    if (hasPoints) {
      line = SimpleLine.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        useBezierCurve: (data['useBezierCurve'] ?? false) as bool,
        points: (data['points'] as List<dynamic>)
            .map((dynamic e) => jsonToOffset(e as Map<String, dynamic>))
            .toList(),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );
    } else {
      // 旧版本兼容
      line = SimpleLine.data(
        minPointDistance: (data['minPointDistance'] ?? 2.0) as double,
        path: DrawPath.fromJson(data['path'] as Map<String, dynamic>),
        paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      );
    }

    // 加载旋转角度
    line.rotation = (data['rotation'] ?? 0.0) as double;
    return line;
  }

  /// 最小点距离
  ///
  /// Minimum point distance
  final double minPointDistance;

  /// 是否使用贝塞尔曲线
  ///
  /// Whether to use bezier curve
  final bool useBezierCurve;

  /// 绘制路径（为了向后兼容保留，用于传统路径模式）
  ///
  /// Drawing path (retained for backward compatibility, used in traditional path mode)
  DrawPath path = DrawPath();

  /// 绘制点列表（用于贝塞尔曲线模式）
  ///
  /// Drawing points list (used in bezier curve mode)
  List<Offset>? points;

  /// 上一个点的位置，用于点过滤优化
  ///
  /// Last point position for point filtering optimization
  Offset? _lastPoint;

  @override
  String get contentType => 'SimpleLine';

  @override
  void startDraw(Offset startPoint) {
    _lastPoint = startPoint;

    if (useBezierCurve) {
      // 使用点列表模式
      points = <Offset>[startPoint];
    } else {
      // 使用传统路径模式
      path.moveTo(startPoint.dx, startPoint.dy);
    }
  }

  @override
  void drawing(Offset nowPoint) {
    // 点过滤优化：跳过距离过近的点
    if (_lastPoint != null) {
      final double distance = (nowPoint - _lastPoint!).distance;

      // 如果距离小于最小点距离，跳过此点
      if (distance < minPointDistance) {
        return;
      }
    }

    if (useBezierCurve) {
      // 添加到点列表
      points?.add(nowPoint);
    } else {
      // 添加到路径
      path.lineTo(nowPoint.dx, nowPoint.dy);
    }

    _lastPoint = nowPoint;
  }

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    if (useBezierCurve && points != null && points!.isNotEmpty) {
      // 应用旋转
      if (rotation != 0.0) {
        final Rect? bounds = getOriginalBounds(); // 使用原始边界保持一致
        if (bounds != null) {
          canvas.save();
          canvas.translate(bounds.center.dx, bounds.center.dy);
          canvas.rotate(rotation);
          canvas.translate(-bounds.center.dx, -bounds.center.dy);
        }
      }

      // 使用贝塞尔曲线绘制
      _drawWithBezierCurve(canvas);

      if (rotation != 0.0) {
        canvas.restore();
      }
    } else {
      // 使用传统路径绘制
      if (rotation != 0.0) {
        final Rect pathBounds = path.path.getBounds();
        if (!pathBounds.isEmpty) {
          canvas.save();
          canvas.translate(pathBounds.center.dx, pathBounds.center.dy);
          canvas.rotate(rotation);
          canvas.translate(-pathBounds.center.dx, -pathBounds.center.dy);
        }
      }

      canvas.drawPath(path.path, paint);

      if (rotation != 0.0) {
        canvas.restore();
      }
    }
  }

  /// 使用贝塞尔曲线绘制平滑线条
  ///
  /// Draw smooth lines using bezier curves
  void _drawWithBezierCurve(Canvas canvas) {
    if (points == null || points!.isEmpty) {
      return;
    }

    if (points!.length == 1) {
      // 单点绘制为小圆点
      canvas.drawCircle(points![0], paint.strokeWidth / 8, paint);
      return;
    }

    final Path bezierPath = Path();
    bezierPath.moveTo(points![0].dx, points![0].dy);

    if (points!.length == 2) {
      // 两点直接连线
      bezierPath.lineTo(points![1].dx, points![1].dy);
    } else {
      // 使用二次贝塞尔曲线连接点
      for (int i = 1; i < points!.length - 1; i++) {
        final Offset p0 = points![i];
        final Offset p1 = points![i + 1];

        // 计算中点作为终点
        final Offset midPoint = Offset(
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );

        // 使用当前点作为控制点，中点作为终点
        bezierPath.quadraticBezierTo(p0.dx, p0.dy, midPoint.dx, midPoint.dy);
      }

      // 绘制最后一段 - 使用贝塞尔曲线避免折角
      final Offset lastPoint = points!.last;
      final Offset secondLastPoint = points![points!.length - 2];

      bezierPath.quadraticBezierTo(
        secondLastPoint.dx,
        secondLastPoint.dy,
        lastPoint.dx,
        lastPoint.dy,
      );
    }

    canvas.drawPath(bezierPath, paint);
  }

  @override
  SimpleLine copy() => SimpleLine(
        minPointDistance: minPointDistance,
        useBezierCurve: useBezierCurve,
      );

  @override
  bool hitTest(Offset point, {double tolerance = 10.0}) {
    if (useBezierCurve && points != null && points!.isNotEmpty) {
      // 如果有旋转，需要将测试点进行反向旋转
      Offset testPoint = point;
      if (rotation != 0.0) {
        final Rect? bounds = getOriginalBounds(); // 使用原始边界保持一致
        if (bounds != null) {
          final Offset center = bounds.center;
          final Offset relative = point - center;
          final double cosAngle = cos(-rotation);
          final double sinAngle = sin(-rotation);
          testPoint = center +
              Offset(
                relative.dx * cosAngle - relative.dy * sinAngle,
                relative.dx * sinAngle + relative.dy * cosAngle,
              );
        }
      }

      // 检查点是否靠近线段上的任何点
      // Check if the point is near any point on the line
      for (final Offset p in points!) {
        if ((p - testPoint).distance <= tolerance) {
          return true;
        }
      }
      return false;
    } else {
      // 对于传统路径，检查点是否在路径附近
      // For traditional path, check if point is near the path
      Offset testPoint = point;
      if (rotation != 0.0) {
        final Rect pathBounds = path.path.getBounds();
        if (!pathBounds.isEmpty) {
          final Offset center = pathBounds.center;
          final Offset relative = point - center;
          final double cosAngle = cos(-rotation);
          final double sinAngle = sin(-rotation);
          testPoint = center +
              Offset(
                relative.dx * cosAngle - relative.dy * sinAngle,
                relative.dx * sinAngle + relative.dy * cosAngle,
              );
        }
      }

      final Path expandedPath = Path()
        ..addPath(path.path, Offset.zero)
        ..close();

      // 使用扩展的边界进行粗略检测
      final Rect bounds = expandedPath.getBounds().inflate(tolerance);
      return bounds.contains(testPoint);
    }
  }

  @override
  Rect? getBounds() {
    Rect? baseRect;

    if (useBezierCurve && points != null && points!.isNotEmpty) {
      double minX = points![0].dx;
      double minY = points![0].dy;
      double maxX = points![0].dx;
      double maxY = points![0].dy;

      for (final Offset p in points!) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }

      // 添加strokeWidth的padding
      final double padding = paint.strokeWidth / 2;
      baseRect = Rect.fromLTRB(
        minX - padding,
        minY - padding,
        maxX + padding,
        maxY + padding,
      );
    } else {
      final Rect pathBounds = path.path.getBounds();
      if (pathBounds.isEmpty) return null;

      final double padding = paint.strokeWidth / 2;
      baseRect = pathBounds.inflate(padding);
    }

    // 如果有旋转，需要计算旋转后的包围盒
    // If rotated, need to calculate rotated bounding box
    if (rotation != 0.0) {
      final Offset center = baseRect.center;
      final List<Offset> corners = <Offset>[
        baseRect.topLeft,
        baseRect.topRight,
        baseRect.bottomLeft,
        baseRect.bottomRight,
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

    return baseRect;
  }

  @override
  Rect? getOriginalBounds() {
    // 返回未旋转的原始边界（用于选择框）
    // Return original bounds without rotation (for selection box)
    if (useBezierCurve && points != null && points!.isNotEmpty) {
      double minX = points![0].dx;
      double minY = points![0].dy;
      double maxX = points![0].dx;
      double maxY = points![0].dy;

      for (final Offset p in points!) {
        if (p.dx < minX) minX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy > maxY) maxY = p.dy;
      }

      final double padding = paint.strokeWidth / 2;
      return Rect.fromLTRB(
        minX - padding,
        minY - padding,
        maxX + padding,
        maxY + padding,
      );
    } else {
      final Rect pathBounds = path.path.getBounds();
      if (pathBounds.isEmpty) return null;

      final double padding = paint.strokeWidth / 2;
      return pathBounds.inflate(padding);
    }
  }

  @override
  void translate(Offset offset) {
    if (useBezierCurve && points != null) {
      points = points!.map((Offset p) => p + offset).toList();
    }
  }

  @override
  void scale(double scale, Offset anchor) {
    if (useBezierCurve && points != null) {
      points = points!.map((Offset p) {
        final Offset relative = p - anchor;
        return anchor + relative * scale;
      }).toList();
    }
  }

  @override
  Map<String, dynamic> toContentJson() {
    if (useBezierCurve && points != null) {
      // 新格式：保存点列表
      return <String, dynamic>{
        'minPointDistance': minPointDistance,
        'useBezierCurve': useBezierCurve,
        'points': points!.map((Offset e) => e.toJson()).toList(),
        'paint': paint.toJson(),
        'rotation': rotation,
      };
    } else {
      // 旧格式：保存路径（向后兼容）
      return <String, dynamic>{
        'minPointDistance': minPointDistance,
        'useBezierCurve': useBezierCurve,
        'path': path.toJson(),
        'paint': paint.toJson(),
        'rotation': rotation,
      };
    }
  }
}
