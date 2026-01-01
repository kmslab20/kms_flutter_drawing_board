import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

/// 绘制内容抽象基类
///
/// 所有绘制内容（线条、形状等）的基类
/// 定义了绘制的生命周期方法和序列化接口
///
/// Paint Content Abstract Base Class
///
/// Base class for all drawing content (lines, shapes, etc.)
/// Defines the lifecycle methods and serialization interface for drawing
abstract class PaintContent {
  PaintContent();

  PaintContent.paint(this.paint);

  /// 画笔配置
  ///
  /// Paint configuration for drawing
  late Paint paint;

  /// 旋转角度（弧度）
  ///
  /// Rotation angle in radians
  double rotation = 0.0;

  /// 复制实例，避免对象引用传递
  ///
  /// Copy instance to avoid object reference passing
  PaintContent copy();

  /// 绘制核心方法
  /// [canvas] 画布对象
  /// [size] 画布尺寸
  /// [deeper] 当前是否为底层绘制（true为历史记录层，false为实时绘制层）
  ///
  /// Core drawing method
  /// [canvas] Canvas object
  /// [size] Canvas size
  /// [deeper] Whether this is deep layer drawing (true for history layer, false for real-time layer)
  void draw(Canvas canvas, Size size, bool deeper);

  /// 绘制过程中调用（手指移动时）
  ///
  /// Called during drawing (when finger is moving)
  void drawing(Offset nowPoint);

  /// 开始绘制（手指按下时）
  ///
  /// Start drawing (when finger is pressed down)
  void startDraw(Offset startPoint);

  /// 检测点是否与绘制内容相交（用于对象选择和删除）
  /// [point] 检测点的坐标
  /// [tolerance] 容差范围（像素）
  ///
  /// Check if a point intersects with the drawn content (for object selection and deletion)
  /// [point] The point to test
  /// [tolerance] Tolerance range in pixels
  bool hitTest(Offset point, {double tolerance = 10.0}) {
    return false; // 默认实现，子类应重写
  }

  /// 获取绘制内容的边界矩形
  ///
  /// Get the bounding rectangle of the drawn content
  Rect? getBounds() {
    return null; // 默认实现，子类应重写
  }

  /// 获取未旋转时的原始边界矩形（用于选择框显示）
  ///
  /// Get the original bounding rectangle before rotation (for selection box display)
  Rect? getOriginalBounds() {
    return getBounds(); // 默认实现，子类可以重写以优化
  }

  /// 移动对象
  /// [offset] 移动的偏移量
  ///
  /// Move the object
  /// [offset] The offset to move by
  void translate(Offset offset) {
    // 默认实现，子类应重写
  }

  /// 缩放对象（保持宽高比）
  /// [scale] 缩放比例
  /// [anchor] 缩放中心点
  ///
  /// Scale the object (maintaining aspect ratio)
  /// [scale] Scale factor
  /// [anchor] Center point for scaling
  void scale(double scale, Offset anchor) {
    // 默认实现，子类应重写
  }

  /// 旋转对象
  /// [angle] 旋转角度（弧度）
  /// [anchor] 旋转中心点（不再使用，保留以兼容接口）
  ///
  /// Rotate the object
  /// [angle] Rotation angle in radians
  /// [anchor] Center point for rotation (no longer used, kept for interface compatibility)
  void rotate(double angle, Offset anchor) {
    rotation = angle; // 直接设置旋转角度而不是变换点
  }

  /// 转换为JSON内容（子类实现）
  ///
  /// Convert to JSON content (implemented by subclasses)
  Map<String, dynamic> toContentJson();

  /// 内容类型标识（用于JSON序列化）
  ///
  /// Content type identifier (for JSON serialization)
  String get contentType => runtimeType.toString();

  /// 转换为JSON对象
  ///
  /// Convert to JSON object
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': contentType,
      ...toContentJson(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
