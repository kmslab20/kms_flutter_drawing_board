import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'helper/safe_value_notifier.dart';
import 'paint_contents/circle.dart';
import 'paint_contents/eraser.dart';
import 'paint_contents/paint_content.dart';
import 'paint_contents/rectangle.dart';
import 'paint_contents/simple_line.dart';
import 'paint_contents/smooth_line.dart';
import 'paint_contents/straight_line.dart';
import 'paint_extension/ex_paint.dart';

/// 绘制配置类
///
/// 包含绘制相关的所有配置参数，如画笔样式、颜色、粗细、画板旋转角度等
///
/// Drawing Configuration Class
///
/// Contains all configuration parameters related to drawing, such as brush style,
/// color, thickness, board rotation angle, etc.
class DrawConfig {
  DrawConfig({
    required this.contentType,
    this.angle = 0,
    this.fingerCount = 0,
    this.size,
    this.isSelectionMode = false,
    this.blendMode = BlendMode.srcOver,
    this.color = Colors.red,
    this.colorFilter,
    this.filterQuality = FilterQuality.high,
    this.imageFilter,
    this.invertColors = false,
    this.isAntiAlias = false,
    this.maskFilter,
    this.shader,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.strokeWidth = 4,
    this.style = PaintingStyle.stroke,
  });

  DrawConfig.def({
    required this.contentType,
    this.angle = 0,
    this.fingerCount = 0,
    this.size,
    this.isSelectionMode = false,
    this.blendMode = BlendMode.srcOver,
    this.color = Colors.red,
    this.colorFilter,
    this.filterQuality = FilterQuality.high,
    this.imageFilter,
    this.invertColors = false,
    this.isAntiAlias = false,
    this.maskFilter,
    this.shader,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.strokeWidth = 4,
    this.style = PaintingStyle.stroke,
  });

  /// 旋转的角度（0:0°, 1:90°, 2:180°, 3:270°）
  ///
  /// Rotation angle (0:0°, 1:90°, 2:180°, 3:270°)
  final int angle;

  /// 绘制内容类型
  ///
  /// Type of drawing content
  final Type contentType;

  /// 当前触摸的手指数量
  ///
  /// Number of fingers currently touching
  final int fingerCount;

  /// 화판 尺寸
  ///
  /// Board size
  final Size? size;

  /// 선택 모드 여부 (true: 캔버스 확대/축소/이동 가능, false: 그리기 모드)
  ///
  /// Whether selection mode is enabled (true: canvas zoom/pan enabled, false: drawing mode)
  final bool isSelectionMode;

  /// 혼합 모드
  ///
  /// Blend mode for painting
  final BlendMode blendMode;

  /// 画笔颜色
  ///
  /// Brush color
  final Color color;

  /// 颜色滤镜
  ///
  /// Color filter
  final ColorFilter? colorFilter;

  /// 滤镜质量
  ///
  /// Filter quality
  final FilterQuality filterQuality;

  /// 图像滤镜
  ///
  /// Image filter
  final ui.ImageFilter? imageFilter;

  /// 是否反转颜色
  ///
  /// Whether to invert colors
  final bool invertColors;

  /// 是否启用抗锯齿
  ///
  /// Whether anti-aliasing is enabled
  final bool isAntiAlias;

  /// 遮罩滤镜
  ///
  /// Mask filter
  final MaskFilter? maskFilter;

  /// 着色器
  ///
  /// Shader
  final Shader? shader;

  /// 线帽样式
  ///
  /// Stroke cap style
  final StrokeCap strokeCap;

  /// 线条连接样式
  ///
  /// Stroke join style
  final StrokeJoin strokeJoin;

  /// 线条粗细
  ///
  /// Stroke width
  final double strokeWidth;

  /// 绘制样式（填充或描边）
  ///
  /// Painting style (fill or stroke)
  final PaintingStyle style;

  /// 根据当前配置生成Paint对象
  ///
  /// Generate Paint object based on current configuration
  Paint get paint => Paint()
    ..blendMode = blendMode
    ..color = color
    ..colorFilter = colorFilter
    ..filterQuality = filterQuality
    ..imageFilter = imageFilter
    ..invertColors = invertColors
    ..isAntiAlias = isAntiAlias
    ..maskFilter = maskFilter
    ..shader = shader
    ..strokeCap = strokeCap
    ..strokeJoin = strokeJoin
    ..strokeWidth = strokeWidth
    ..style = style;

  DrawConfig copyWith({
    Type? contentType,
    BlendMode? blendMode,
    Color? color,
    ColorFilter? colorFilter,
    FilterQuality? filterQuality,
    ui.ImageFilter? imageFilter,
    bool? invertColors,
    bool? isAntiAlias,
    MaskFilter? maskFilter,
    Shader? shader,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? strokeWidth,
    PaintingStyle? style,
    int? angle,
    int? fingerCount,
    Size? size,
    bool? isSelectionMode,
  }) {
    return DrawConfig(
      contentType: contentType ?? this.contentType,
      angle: angle ?? this.angle,
      blendMode: blendMode ?? this.blendMode,
      color: color ?? this.color,
      colorFilter: colorFilter ?? this.colorFilter,
      filterQuality: filterQuality ?? this.filterQuality,
      imageFilter: imageFilter ?? this.imageFilter,
      invertColors: invertColors ?? this.invertColors,
      isAntiAlias: isAntiAlias ?? this.isAntiAlias,
      maskFilter: maskFilter ?? this.maskFilter,
      shader: shader ?? this.shader,
      strokeCap: strokeCap ?? this.strokeCap,
      strokeJoin: strokeJoin ?? this.strokeJoin,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      style: style ?? this.style,
      fingerCount: fingerCount ?? this.fingerCount,
      size: size ?? this.size,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }
}

/// 绘制控制器
///
/// 管理画板的所有状态和操作，包括绘制内容、历史记录、撤销/重做等功能
/// 提供完整的绘图生命周期管理，支持图片导出、JSON序列化等高级功能
///
/// Drawing Controller
///
/// Manages all states and operations of the drawing board, including drawing content,
/// history, undo/redo functions. Provides complete drawing lifecycle management,
/// supports image export, JSON serialization and other advanced features.
class DrawingController extends ChangeNotifier {
  DrawingController({
    DrawConfig? config,
    PaintContent? content,
    this.maxHistorySteps = 100,
  }) {
    _history = <PaintContent>[];
    _currentIndex = 0;
    realPainter = RePaintNotifier();
    painter = RePaintNotifier();
    drawConfig = SafeValueNotifier<DrawConfig>(config ?? DrawConfig.def(contentType: SimpleLine));
    setPaintContent(content ?? SimpleLine());
  }

  /// 历史记录最大步数，防止内存无限增长
  /// 默认 100 步，可根据需求调整
  ///
  /// Maximum number of history steps to prevent unlimited memory growth
  /// Default is 100 steps, adjustable based on needs
  final int maxHistorySteps;

  /// 绘制开始点
  ///
  /// Starting point of drawing
  Offset? _startPoint;

  /// 画板数据Key，用于获取RenderObject导出图片
  ///
  /// Board data key for getting RenderObject to export images
  late GlobalKey painterKey = GlobalKey();

  /// 变换控制器（用于获取当前缩放比例）
  ///
  /// Transformation controller (for getting current scale)
  TransformationController? _transformationController;

  /// 获取或设置变换控制器
  /// 设置时会添加监听器以便在缩放变化时更新选择框
  ///
  /// Get or set transformation controller
  /// When set, adds listener to update selection box on scale changes
  TransformationController? get transformationController => _transformationController;
  set transformationController(TransformationController? controller) {
    // 移除旧的监听器
    _transformationController?.removeListener(_onTransformationChanged);

    _transformationController = controller;

    // 添加新的监听器
    _transformationController?.addListener(_onTransformationChanged);
  }

  /// 变换变化时的回调（用于更新选择框显示）
  ///
  /// Callback when transformation changes (to update selection box display)
  void _onTransformationChanged() {
    // 只在选择模式且有选中对象时才需要通知重绘
    // Only notify repaint when in selection mode and an object is selected
    if (isSelectionMode && _selectedObjectIndex >= 0) {
      notifyListeners();
    }
  }

  /// 绘制配置通知器
  ///
  /// Drawing configuration notifier
  late SafeValueNotifier<DrawConfig> drawConfig;

  /// 最后一次设置的绘制内容模板
  ///
  /// Last set drawing content template
  late PaintContent _paintContent;

  /// 获取当前绘制内容模板
  ///
  /// Get current drawing content template
  PaintContent get currentContent => _paintContent;

  /// 当前正在绘制的内容（实时）
  ///
  /// Currently drawing content (real-time)
  PaintContent? drawingContent;

  /// 橡皮擦绘制内容
  ///
  /// Eraser drawing content
  PaintContent? eraserContent;

  /// 缓存的图片数据，用于优化橡皮擦性能
  ///
  /// Cached image data for optimizing eraser performance
  ui.Image? cachedImage;

  /// 底层绘制内容历史记录
  ///
  /// Historical records of drawing content
  late List<PaintContent> _history;

  /// 当前controller是否已挂载
  ///
  /// Whether the controller is currently mounted
  bool _mounted = true;

  /// 获取绘制历史记录
  ///
  /// Get drawing history
  List<PaintContent> get getHistory => _history;

  /// 当前历史记录指针位置
  ///
  /// Current position of history pointer
  late int _currentIndex;

  /// 表层画布刷新通知器
  ///
  /// Surface canvas repaint notifier
  RePaintNotifier? painter;

  /// 底层画布刷新通知器
  ///
  /// Deep layer canvas repaint notifier
  RePaintNotifier? realPainter;

  /// 是否绘制了有效内容（用于判断点击与绘制）
  ///
  /// Whether valid content has been drawn (for distinguishing click from drawing)
  bool _isDrawingValidContent = false;

  /// 当前选中的对象索引（-1 表示无选中）
  ///
  /// Currently selected object index (-1 means no selection)
  int _selectedObjectIndex = -1;

  /// 是否正在操作选中的对象（拖拽或缩放）
  ///
  /// Whether manipulating selected object (drag or scale)
  bool _isManipulatingObject = false;

  /// 单指拖拽开始位置
  ///
  /// Single finger drag start position
  Offset? _dragStartPosition;

  /// 双指缩放的初始状态
  ///
  /// Initial state for pinch scaling
  double? _scaleStartDistance;
  Offset? _scaleStartCenter;
  double? _scaleStartFactor = 1.0;

  /// 缩放开始时的对象状态（JSON序列化保存）
  ///
  /// Object state at scale start (saved as JSON)
  Map<String, dynamic>? _scaleStartContentJson;

  /// 旋转状态
  ///
  /// Rotation state
  double? _rotationStartAngle;
  Offset? _rotationAnchor; // 회전 앵커 저장
  double? _rotationStartValue; // 회전 시작 시 객체의 rotation 값

  /// 获取当前步骤索引
  ///
  /// Get current step index
  int get currentIndex => _currentIndex;

  /// 获取当前选中的对象索引
  ///
  /// Get currently selected object index
  int get selectedObjectIndex => _selectedObjectIndex;

  /// 是否正在操作对象（拖拽或缩放中）
  /// 操作中时应禁用画布的pan/scale
  ///
  /// Whether object is being manipulated (dragging or scaling)
  /// Canvas pan/scale should be disabled during manipulation
  bool get isManipulatingObject => _isManipulatingObject;

  /// 获取当前画布缩放比例
  ///
  /// Get current canvas scale
  double get canvasScale {
    if (transformationController == null) {
      return 1.0;
    }
    final Matrix4 matrix = transformationController!.value;
    // Extract scale from transformation matrix
    return matrix.getMaxScaleOnAxis();
  }

  /// 获取当前画笔颜色
  ///
  /// Get current brush color
  Color get getColor => drawConfig.value.color;

  /// 能否开始绘制（无手指触摸时）
  ///
  /// Whether drawing can start (when no finger is touching)
  bool get couldStartDraw => drawConfig.value.fingerCount == 0;

  /// 能否进行绘制（单指触摸时）
  ///
  /// Whether drawing is allowed (when single finger is touching)
  bool get couldDrawing => drawConfig.value.fingerCount == 1;

  /// 是否处于选择模式
  ///
  /// Whether in selection mode
  bool get isSelectionMode => drawConfig.value.isSelectionMode;

  /// 是否有正在绘制的内容
  ///
  /// Whether there is content being drawn
  bool get hasPaintingContent => drawingContent != null || eraserContent != null;

  /// 获取绘制开始点
  ///
  /// Get drawing start point
  Offset? get startPoint => _startPoint;

  /// 设置画板大小
  ///
  /// Set board size
  void setBoardSize(Size? size) {
    drawConfig.value = drawConfig.value.copyWith(size: size);
  }

  /// 设置选择模式
  ///
  /// Set selection mode
  void setSelectionMode(bool enabled) {
    drawConfig.value = drawConfig.value.copyWith(isSelectionMode: enabled);
    // 退出选择模式时清除选中状态
    // Clear selection when exiting selection mode
    if (!enabled) {
      _selectedObjectIndex = -1;
      notifyListeners();
    }
  }

  /// 选择对象
  ///
  /// Select an object by index
  void selectObject(int index) {
    if (index >= 0 && index < _currentIndex) {
      _selectedObjectIndex = index;
      notifyListeners();
    }
  }

  /// 取消选择
  ///
  /// Deselect current object
  void deselectObject() {
    if (_selectedObjectIndex != -1) {
      _selectedObjectIndex = -1;
      notifyListeners();
    }
  }

  /// 通过点击位置选择对象
  ///
  /// Select object by tap position
  void selectObjectByPosition(Offset position) {
    if (!isSelectionMode) {
      return;
    }

    final double tolerance = drawConfig.value.strokeWidth * 2;

    // 从后往前检查（最新的对象优先）
    // Check from back to front (newest objects first)
    for (int i = _currentIndex - 1; i >= 0; i--) {
      // 跳过橡皮擦对象
      // Skip eraser objects
      if (_history[i] is Eraser) {
        continue;
      }

      if (_history[i].hitTest(position, tolerance: tolerance)) {
        selectObject(i);
        return;
      }
    }

    // 没有命中任何对象，取消选择
    // No object hit, deselect
    deselectObject();
  }

  /// 开始单指拖拽对象
  ///
  /// Start single finger drag of object
  bool startObjectDrag(Offset position) {
    if (!isSelectionMode || _selectedObjectIndex < 0) {
      return false;
    }

    final PaintContent selectedContent = _history[_selectedObjectIndex];
    final Rect? bounds = selectedContent.getBounds();

    if (bounds == null) {
      return false;
    }

    // 检查是否点击了对象
    // Check if object was clicked
    if (bounds.contains(position)) {
      _isManipulatingObject = true;
      _dragStartPosition = position;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// 更新单指拖拽
  ///
  /// Update single finger drag
  void updateObjectDrag(Offset position) {
    if (!_isManipulatingObject || _dragStartPosition == null) {
      return;
    }

    // 移动对象
    final Offset delta = position - _dragStartPosition!;
    _history[_selectedObjectIndex].translate(delta);
    _dragStartPosition = position;
    _refreshDeep(); // 确保底层画板重绘
    notifyListeners();
  }

  /// 结束单指拖拽
  ///
  /// End single finger drag
  void endObjectDrag() {
    if (_isManipulatingObject) {
      _isManipulatingObject = false;
      _dragStartPosition = null;
      notifyListeners();
    }
  }

  /// 开始双指缩放对象
  ///
  /// Start pinch scaling of object
  bool startObjectScale(Offset point1, Offset point2) {
    if (!isSelectionMode || _selectedObjectIndex < 0) {
      return false;
    }

    final PaintContent selectedContent = _history[_selectedObjectIndex];
    final Rect? bounds = selectedContent.getBounds();

    if (bounds == null) {
      return false;
    }

    // 개체가 선택되어 있으면 어디서든 핀치 제스처를 개체에 적용
    // If object is selected, apply pinch gesture to object from anywhere
    _isManipulatingObject = true;
    _scaleStartDistance = (point2 - point1).distance;
    _scaleStartCenter = (point1 + point2) / 2;
    _scaleStartFactor = 1.0;
    // 保存原始对象状态
    _scaleStartContentJson = _history[_selectedObjectIndex].toJson();

    // 개체의 중심점을 앵커로 사용
    // Use object center as anchor
    final Offset objectCenter = bounds.center;
    _scaleStartCenter = objectCenter;

    notifyListeners();
    return true;
  }

  /// 更新双指缩放
  ///
  /// Update pinch scaling
  void updateObjectScale(Offset point1, Offset point2) {
    if (!_isManipulatingObject ||
        _scaleStartDistance == null ||
        _scaleStartCenter == null ||
        _scaleStartContentJson == null) {
      return;
    }

    // 计算当前缩放比例
    final double currentDistance = (point2 - point1).distance;

    if (_scaleStartDistance! > 0) {
      final double scaleFactor = currentDistance / _scaleStartDistance!;
      // 限制缩放范围
      final double clampedScale = scaleFactor.clamp(0.1, 10.0);

      // 从原始状态重新创建对象
      final PaintContent originalContent = _createContentFromJson(_scaleStartContentJson!);

      // 应用缩放（使用对象中心点作为锚点，保持对象位置）
      originalContent.scale(clampedScale, _scaleStartCenter!);

      // 替换历史记录中的对象
      _history[_selectedObjectIndex] = originalContent;
      _refreshDeep(); // 确保底层画板重绘
      notifyListeners();
    }
  }

  /// 结束双指缩放
  ///
  /// End pinch scaling
  void endObjectScale() {
    if (_isManipulatingObject) {
      _isManipulatingObject = false;
      _scaleStartDistance = null;
      _scaleStartCenter = null;
      _scaleStartFactor = null;
      _scaleStartContentJson = null;
      notifyListeners();
    }
  }

  /// 开始旋转对象
  ///
  /// Start rotating object
  bool startObjectRotation(Offset position) {
    if (!isSelectionMode || _selectedObjectIndex < 0) {
      return false;
    }

    final PaintContent selectedContent = _history[_selectedObjectIndex];
    final Rect? bounds = selectedContent.getOriginalBounds(); // 使用未旋转的原始边界

    if (bounds == null) {
      return false;
    }

    _isManipulatingObject = true;
    final Offset center = bounds.center;

    // 保存旋转锚点（对象中心）
    // Save rotation anchor (object center)
    _rotationAnchor = center;

    // 保存旋转开始时对象已有的旋转角度
    // Save the object's existing rotation angle at start
    _rotationStartValue = selectedContent.rotation;

    // 计算初始角度
    _rotationStartAngle = atan2(
      position.dy - center.dy,
      position.dx - center.dx,
    );

    notifyListeners();
    return true;
  }

  /// 更新旋转
  ///
  /// Update rotation
  void updateObjectRotation(Offset position) {
    if (!_isManipulatingObject ||
        _rotationStartAngle == null ||
        _rotationAnchor == null ||
        _rotationStartValue == null) {
      return;
    }

    // 使用保存的锚点而不是重新计算
    // Use saved anchor instead of recalculating
    final Offset center = _rotationAnchor!;

    // 计算当前角度
    final double currentAngle = atan2(
      position.dy - center.dy,
      position.dx - center.dx,
    );

    // 计算角度差
    final double deltaAngle = currentAngle - _rotationStartAngle!;

    // 将角度差添加到初始旋转角度上
    // Add delta angle to initial rotation angle
    _history[_selectedObjectIndex].rotation = _rotationStartValue! + deltaAngle;

    _refreshDeep();
    notifyListeners();
  }

  /// 结束旋转
  ///
  /// End rotation
  void endObjectRotation() {
    if (_isManipulatingObject) {
      _isManipulatingObject = false;
      _rotationStartAngle = null;
      _rotationAnchor = null;
      _rotationStartValue = null;
      notifyListeners();
    }
  }

  /// 获取当前旋转角度（度数）
  ///
  /// Get current rotation angle in degrees
  double? getCurrentRotationAngle() {
    if (!_isManipulatingObject || _rotationStartAngle == null || _selectedObjectIndex < 0) {
      return null;
    }

    final PaintContent selectedContent = _history[_selectedObjectIndex];
    final Rect? bounds = selectedContent.getBounds();

    if (bounds == null) {
      return null;
    }

    return null; // 각도는 updateObjectRotation에서 계산, UI에서 표시
  }

  /// 从JSON创建PaintContent对象
  ///
  /// Create PaintContent from JSON
  PaintContent _createContentFromJson(Map<String, dynamic> json) {
    final String type = json['type'] as String;

    switch (type) {
      case 'SimpleLine':
        return SimpleLine.fromJson(json);
      case 'SmoothLine':
        return SmoothLine.fromJson(json);
      case 'StraightLine':
        return StraightLine.fromJson(json);
      case 'Rectangle':
        return Rectangle.fromJson(json);
      case 'Circle':
        return Circle.fromJson(json);
      case 'Eraser':
        return Eraser.fromJson(json);
      default:
        throw Exception('Unknown content type: $type');
    }
  }

  /// 增加手指计数（手指按下时调用）
  ///
  /// Increment finger count (called when finger is pressed down)
  void addFingerCount(Offset offset) {
    drawConfig.value = drawConfig.value.copyWith(fingerCount: drawConfig.value.fingerCount + 1);
  }

  /// 减少手指计数（手指抬起时调用）
  ///
  /// Decrement finger count (called when finger is released)
  void reduceFingerCount(Offset offset) {
    if (drawConfig.value.fingerCount <= 0) {
      return;
    }

    drawConfig.value = drawConfig.value.copyWith(fingerCount: drawConfig.value.fingerCount - 1);
  }

  /// 设置绘制样式
  ///
  /// Set drawing style
  void setStyle({
    BlendMode? blendMode,
    Color? color,
    ColorFilter? colorFilter,
    FilterQuality? filterQuality,
    ui.ImageFilter? imageFilter,
    bool? invertColors,
    bool? isAntiAlias,
    MaskFilter? maskFilter,
    Shader? shader,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    double? strokeMiterLimit,
    double? strokeWidth,
    PaintingStyle? style,
  }) {
    drawConfig.value = drawConfig.value.copyWith(
      blendMode: blendMode,
      color: color,
      colorFilter: colorFilter,
      filterQuality: filterQuality,
      imageFilter: imageFilter,
      invertColors: invertColors,
      isAntiAlias: isAntiAlias,
      maskFilter: maskFilter,
      shader: shader,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
      strokeWidth: strokeWidth,
      style: style,
    );
  }

  /// 设置绘制内容类型（如SimpleLine、Eraser等）
  ///
  /// Set drawing content type (such as SimpleLine, Eraser, etc.)
  void setPaintContent(PaintContent content) {
    content.paint = drawConfig.value.paint;
    _paintContent = content;
    drawConfig.value = drawConfig.value.copyWith(contentType: content.runtimeType);
  }

  /// 添加一条绘制内容到历史记录
  ///
  /// Add a drawing content to history
  void addContent(PaintContent content) {
    _history.add(content);
    _currentIndex++;
    cachedImage = null;
    _refreshDeep();
  }

  /// 批量添加多条绘制内容
  ///
  /// Add multiple drawing contents in batch
  void addContents(List<PaintContent> contents) {
    _history.addAll(contents);
    _currentIndex += contents.length;
    cachedImage = null;
    _refreshDeep();
  }

  /// 旋转画布（每次旋转90度）
  ///
  /// Rotate canvas (rotate 90 degrees each time)
  void turn() {
    drawConfig.value = drawConfig.value.copyWith(angle: (drawConfig.value.angle + 1) % 4);
  }

  /// 开始绘制
  ///
  /// Start drawing
  void startDraw(Offset startPoint) {
    if (_currentIndex == 0 && _paintContent is Eraser) {
      return;
    }

    _startPoint = startPoint;

    if (_paintContent is Eraser) {
      eraserContent = _paintContent.copy();
      eraserContent?.paint = drawConfig.value.paint.copyWith();
      eraserContent?.startDraw(startPoint);
    } else {
      drawingContent = _paintContent.copy();
      drawingContent?.paint = drawConfig.value.paint;
      drawingContent?.startDraw(startPoint);
    }
  }

  /// 取消绘制（不保存当前绘制内容）
  ///
  /// Cancel drawing (do not save current drawing content)
  void cancelDraw() {
    _startPoint = null;
    drawingContent = null;
    eraserContent = null;
  }

  /// 正在绘制（手指移动过程）
  ///
  /// Drawing in progress (finger moving process)
  void drawing(Offset nowPaint) {
    if (!hasPaintingContent) {
      return;
    }

    _isDrawingValidContent = true;

    if (_paintContent is Eraser && eraserContent != null) {
      eraserContent?.drawing(nowPaint);

      // 检测并标记被擦除的对象
      // Check and mark objects to be deleted
      final double tolerance = drawConfig.value.strokeWidth;
      final Eraser eraser = eraserContent as Eraser;

      for (int i = 0; i < _currentIndex; i++) {
        if (!eraser.deletedIndices.contains(i)) {
          // 检查当前点是否与该对象相交
          if (_history[i].hitTest(nowPaint, tolerance: tolerance)) {
            eraser.deletedIndices = [...eraser.deletedIndices, i];
            // 触发重绘以显示删除效果
            _refreshDeep();
          }
        }
      }

      _refresh();
    } else {
      drawingContent?.drawing(nowPaint);
      _refresh();
    }
  }

  /// 结束绘制（手指抬起，保存绘制内容）
  ///
  /// End drawing (finger released, save drawing content)
  void endDraw() {
    if (!hasPaintingContent) {
      return;
    }

    if (!_isDrawingValidContent) {
      // 清理绘制内容
      _startPoint = null;
      drawingContent = null;
      eraserContent = null;
      return;
    }

    _isDrawingValidContent = false;

    _startPoint = null;
    final int hisLen = _history.length;

    if (hisLen > _currentIndex) {
      _history.removeRange(_currentIndex, hisLen);
    }

    if (eraserContent != null) {
      // 只有当橡皮擦删除了对象时才添加到历史记录
      // Only add eraser to history if it deleted any objects
      final Eraser eraser = eraserContent as Eraser;
      if (eraser.deletedIndices.isNotEmpty) {
        _history.add(eraserContent!);
        _currentIndex = _history.length;
      }
      eraserContent = null;
    }

    if (drawingContent != null) {
      _history.add(drawingContent!);
      _currentIndex = _history.length;
      drawingContent = null;
    }

    // 修剪历史记录，防止内存无限增长
    _trimHistoryIfNeeded();

    _refresh();
    _refreshDeep();
    notifyListeners();
  }

  /// 修剪历史记录，保持在最大步数限制内
  ///
  /// Trim history to keep it within the maximum step limit
  void _trimHistoryIfNeeded() {
    if (_history.length > maxHistorySteps) {
      final int removeCount = _history.length - maxHistorySteps;
      _history.removeRange(0, removeCount);
      _currentIndex = _history.length;
      cachedImage = null; // 清除缓存，因为历史已改变 / Clear cache as history has changed
    }
  }

  /// 撤销上一步操作
  ///
  /// Undo the last operation
  void undo() {
    cachedImage = null;
    if (_currentIndex > 0) {
      _currentIndex = _currentIndex - 1;
      _refreshDeep();
      notifyListeners();
    }
  }

  /// 检查是否可以撤销
  ///
  /// Check if undo is available
  /// Returns true if possible
  bool canUndo() {
    return _currentIndex > 0;
  }

  /// 重做上一步撤销的操作
  ///
  /// Redo the last undone operation
  void redo() {
    cachedImage = null;
    if (_currentIndex < _history.length) {
      _currentIndex = _currentIndex + 1;
      _refreshDeep();
      notifyListeners();
    }
  }

  /// 检查是否可以重做
  ///
  /// Check if redo is available
  /// Returns true if possible
  bool canRedo() {
    return _currentIndex < _history.length;
  }

  /// 清空画布所有内容
  ///
  /// Clear all content on the canvas
  void clear() {
    cachedImage = null;
    _history.clear();
    _currentIndex = 0;
    _refreshDeep();
    notifyListeners();
  }

  /// 检查是否可以清空
  ///
  /// Check if clear is available
  /// Returns true if possible
  bool canClear() {
    return _history.isNotEmpty;
  }

  /// 获取完整的画板图片数据（包含背景）
  ///
  /// Get complete board image data (including background)
  Future<ByteData?> getImageData({
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
    double? pixelRatio,
  }) async {
    try {
      final BuildContext? context = painterKey.currentContext;
      if (context == null) {
        debugPrint('画板未挂载，无法获取图片数据');
        return null;
      }

      final RenderObject? renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        debugPrint('渲染对象类型错误，期望 RenderRepaintBoundary');
        return null;
      }

      final double ratio = pixelRatio ?? View.of(context).devicePixelRatio;
      final ui.Image image = await renderObject.toImage(pixelRatio: ratio);

      return await image.toByteData(format: format);
    } catch (e, stack) {
      debugPrint('获取图片数据失败: $e\n$stack');
      return null;
    }
  }

  /// 获取表层图片数据（仅绘制内容，不含背景）
  /// 更快速，使用缓存的图片数据
  ///
  /// Get surface image data (drawing content only, no background)
  /// Faster, uses cached image data
  Future<ByteData?> getSurfaceImageData({
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
  }) async {
    try {
      final ui.Image? image = cachedImage;
      if (image == null) {
        debugPrint('缓存图片不存在，请先进行绘制或使用 getImageData()');
        return null;
      }
      return await image.toByteData(format: format);
    } catch (e, stack) {
      debugPrint('获取表层图片数据失败: $e\n$stack');
      return null;
    }
  }

  /// 获取画板内容的JSON列表
  ///
  /// Get JSON list of board content
  List<Map<String, dynamic>> getJsonList() {
    return _history.map((PaintContent e) => e.toJson()).toList();
  }

  /// 刷新表层画板（实时绘制层）
  ///
  /// Refresh surface board (real-time drawing layer)
  void _refresh() {
    painter?._refresh();
  }

  /// 刷新底层画板（历史记录层）
  ///
  /// Refresh deep layer board (history layer)
  void _refreshDeep() {
    realPainter?._refresh();
  }

  /// 销毁控制器，释放资源
  ///
  /// Dispose controller and release resources
  @override
  void dispose() {
    if (!_mounted) {
      return;
    }

    // 移除变换控制器监听器
    // Remove transformation controller listener
    _transformationController?.removeListener(_onTransformationChanged);

    drawConfig.dispose();
    realPainter?.dispose();
    painter?.dispose();

    _mounted = false;

    super.dispose();
  }
}

/// 画布刷新通知器
///
/// 用于控制CustomPainter的重绘
///
/// Canvas Repaint Notifier
///
/// Used to control repainting of CustomPainter
class RePaintNotifier extends ChangeNotifier {
  void _refresh() {
    notifyListeners();
  }
}

/// 绘制控制器提供者
///
/// 通过InheritedWidget共享DrawingController到子组件树
///
/// Drawing Controller Provider
///
/// Shares DrawingController to the widget tree via InheritedWidget
class DrawingControllerProvider extends InheritedWidget {
  const DrawingControllerProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  final DrawingController controller;

  static DrawingController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DrawingControllerProvider>()?.controller;
  }

  @override
  bool updateShouldNotify(DrawingControllerProvider oldWidget) => false;
}
