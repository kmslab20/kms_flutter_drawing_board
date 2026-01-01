import 'package:flutter/material.dart';

import '../draw_path/draw_path.dart';
import '../paint_extension/ex_paint.dart';
import 'paint_content.dart';

/// 橡皮擦绘制内容
///
/// 通过触摸检测删除完整对象的橡皮擦
/// 类似于三星笔记的UX：触摸到对象时删除整个对象
///
/// Eraser Drawing Content
///
/// Eraser that deletes complete objects by touch detection
/// Similar to Samsung Notes UX: deletes entire object when touched
class Eraser extends PaintContent {
  Eraser() : deletedIndices = <int>[];

  Eraser.data({
    required this.drawPath,
    required Paint paint,
    this.deletedIndices = const <int>[],
  }) : super.paint(paint);

  factory Eraser.fromJson(Map<String, dynamic> data) {
    final dynamic deletedData = data['deletedIndices'];
    final List<int> deleted =
        deletedData != null ? List<int>.from(deletedData as List<dynamic>) : <int>[];

    return Eraser.data(
      drawPath: DrawPath.fromJson(data['path'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
      deletedIndices: deleted,
    );
  }

  /// 擦除路径（用于显示擦除轨迹）
  ///
  /// Eraser path (for showing eraser trail)
  DrawPath drawPath = DrawPath();

  /// 被删除的对象索引列表
  ///
  /// List of deleted object indices
  List<int> deletedIndices;

  @override
  String get contentType => 'Eraser';

  @override
  void startDraw(Offset startPoint) {
    drawPath.moveTo(startPoint.dx, startPoint.dy);
  }

  @override
  void drawing(Offset nowPoint) => drawPath.lineTo(nowPoint.dx, nowPoint.dy);

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    // 橡皮擦本身不绘制任何内容，只标记要删除的对象
    // The eraser itself doesn't draw anything, just marks objects for deletion

    // 可以选择绘制擦除轨迹用于视觉反馈（可选）
    // Optionally draw eraser trail for visual feedback
    if (!deeper) {
      final Paint eraserPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = paint.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(drawPath.path, eraserPaint);
    }
  }

  @override
  Eraser copy() => Eraser();

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'path': drawPath.toJson(),
      'paint': paint.toJson(),
      'deletedIndices': deletedIndices,
    };
  }
}
