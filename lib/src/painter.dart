import 'package:flutter/material.dart';

import '../paint_contents.dart';
import 'drawing_controller.dart';
import 'helper/ex_value_builder.dart';

/// 绘图板组件
///
/// 负责处理用户触摸交互并将绘制请求传递给DrawingController
/// 内置手掌拒绝功能，支持实时绘制和历史记录分层渲染
///
/// Painter Widget
///
/// Handles user touch interactions and passes drawing requests to DrawingController
/// Built-in palm rejection, supports real-time drawing and layered rendering of history
class Painter extends StatefulWidget {
  const Painter({
    super.key,
    required this.drawingController,
    this.clipBehavior = Clip.antiAlias,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.enablePalmRejection = false,
  });

  /// 绘制控制器
  ///
  /// Drawing controller
  final DrawingController drawingController;

  /// 手指按下回调
  ///
  /// Callback when pointer is pressed down
  final void Function(PointerDownEvent pde)? onPointerDown;

  /// 手指移动回调
  ///
  /// Callback when pointer is moving
  final void Function(PointerMoveEvent pme)? onPointerMove;

  /// 手指抬起回调
  ///
  /// Callback when pointer is released
  final void Function(PointerUpEvent pue)? onPointerUp;

  /// 边缘裁剪方式
  ///
  /// Clip behavior
  final Clip clipBehavior;

  /// 启用手掌拒绝功能，防止手掌误触
  ///
  /// Enable palm rejection to prevent accidental palm touches
  final bool enablePalmRejection;

  @override
  State<Painter> createState() => _PainterState();
}

class _PainterState extends State<Painter> {
  /// 最近一次触摸的时间戳，用于手掌拒绝检测
  ///
  /// Timestamp of the last touch, used for palm rejection detection
  DateTime? _lastTouchTime;

  /// 选择模式：记录按下位置用于检测tap
  ///
  /// Selection mode: record down position for tap detection
  Offset? _selectionModeDownPosition;

  /// 多点触控跟踪（用于双指缩放）
  ///
  /// Multi-touch tracking (for pinch gestures)
  final Map<int, Offset> _pointers = <int, Offset>{};

  /// 处理手指按下事件
  ///
  /// Handle pointer down event
  void _onPointerDown(PointerDownEvent pde) {
    // 선택 모드에서 멀티터치 처리
    if (widget.drawingController.isSelectionMode) {
      _pointers[pde.pointer] = pde.localPosition;

      if (_pointers.length == 1) {
        // 단일 터치: 탭 감지 또는 드래그 시작
        _selectionModeDownPosition = pde.localPosition;
        if (widget.drawingController.selectedObjectIndex >= 0) {
          widget.drawingController.startObjectDrag(pde.localPosition);
        }
      } else if (_pointers.length == 2) {
        // 두 손가락: 핀치 시작
        _selectionModeDownPosition = null; // 탭 취소
        final List<Offset> points = _pointers.values.toList();
        widget.drawingController.startObjectScale(points[0], points[1]);
      }
      return;
    }

    if (!widget.drawingController.couldStartDraw) {
      return;
    }

    // 手掌拒绝检测
    if (widget.enablePalmRejection) {
      // 检测触摸面积过大（可能是手掌）
      // size 值通常在 0-20 之间，手掌通常 > 15
      if (pde.size > 15.0) {
        return;
      }

      // 检测是否在短时间内有多个触摸点（可能是手掌和手指同时触摸）
      final DateTime now = DateTime.now();
      if (_lastTouchTime != null) {
        final Duration difference = now.difference(_lastTouchTime!);
        if (difference.inMilliseconds < 100) {
          // 100ms 内有多次触摸，可能是手掌，拒绝
          return;
        }
      }
      _lastTouchTime = now;
    }

    widget.drawingController.startDraw(pde.localPosition);
    widget.onPointerDown?.call(pde);
  }

  /// 处理手指移动事件
  ///
  /// Handle pointer move event
  void _onPointerMove(PointerMoveEvent pme) {
    // 선택 모드에서 멀티터치 처리
    if (widget.drawingController.isSelectionMode) {
      _pointers[pme.pointer] = pme.localPosition;

      if (_pointers.length == 1) {
        // 단일 터치: 드래그 업데이트
        if (_selectionModeDownPosition != null) {
          final double distance = (pme.localPosition - _selectionModeDownPosition!).distance;
          if (distance > 10.0) {
            _selectionModeDownPosition = null; // 탭 취소
          }
        }
        widget.drawingController.updateObjectDrag(pme.localPosition);
      } else if (_pointers.length == 2) {
        // 두 손가락: 핀치 업데이트
        final List<Offset> points = _pointers.values.toList();
        widget.drawingController.updateObjectScale(points[0], points[1]);
      }
      return;
    }

    if (!widget.drawingController.couldDrawing) {
      if (widget.drawingController.hasPaintingContent) {
        widget.drawingController.endDraw();
      }

      return;
    }

    if (!widget.drawingController.hasPaintingContent) {
      return;
    }

    widget.drawingController.drawing(pme.localPosition);
    widget.onPointerMove?.call(pme);
  }

  /// 处理手指抬起事件
  ///
  /// Handle pointer up event
  void _onPointerUp(PointerUpEvent pue) {
    // 선택 모드에서 멀티터치 처리
    if (widget.drawingController.isSelectionMode) {
      _pointers.remove(pue.pointer);

      if (_pointers.isEmpty) {
        // 모든 손가락이 떼어짐
        widget.drawingController.endObjectDrag();
        widget.drawingController.endObjectScale();

        // 탭 감지
        if (_selectionModeDownPosition != null) {
          final double distance = (pue.localPosition - _selectionModeDownPosition!).distance;
          if (distance <= 10.0) {
            widget.drawingController.selectObjectByPosition(pue.localPosition);
          }
        }
        _selectionModeDownPosition = null;
      } else if (_pointers.length == 1) {
        // 두 손가락 중 하나만 떼어짐 - 스케일 종료
        widget.drawingController.endObjectScale();
      }
      return;
    }

    if (!widget.drawingController.couldDrawing || !widget.drawingController.hasPaintingContent) {
      return;
    }

    if (widget.drawingController.startPoint == pue.localPosition) {
      widget.drawingController.drawing(pue.localPosition);
    }

    widget.drawingController.endDraw();
    widget.onPointerUp?.call(pue);
  }

  /// 处理手指取消事件
  ///
  /// Handle pointer cancel event
  void _onPointerCancel(PointerCancelEvent pce) {
    // 선택 모드에서 멀티터치 처리
    if (widget.drawingController.isSelectionMode) {
      _pointers.remove(pce.pointer);
      if (_pointers.isEmpty) {
        widget.drawingController.endObjectDrag();
        widget.drawingController.endObjectScale();
        _selectionModeDownPosition = null;
      }
      return;
    }

    if (!widget.drawingController.couldDrawing) {
      return;
    }

    widget.drawingController.endDraw();
  }

  /// GestureDetector 占位方法（防止单指绘制时触发画布平移）
  ///
  /// GestureDetector placeholder methods (prevent canvas panning during single-finger drawing)
  void _onPanDown(DragDownDetails ddd) {}

  void _onPanUpdate(DragUpdateDetails dud) {}

  void _onPanEnd(DragEndDetails ded) {}

  @override
  Widget build(BuildContext context) {
    // 선택 모드일 때도 Listener가 이벤트를 받도록 함 (tap 감지 위해)
    final bool isSelectionMode = widget.drawingController.isSelectionMode;

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: isSelectionMode ? null : _onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: ExValueBuilder<DrawConfig>(
        valueListenable: widget.drawingController.drawConfig,
        shouldRebuild: (DrawConfig p, DrawConfig n) =>
            p.fingerCount != n.fingerCount || p.isSelectionMode != n.isSelectionMode,
        builder: (_, DrawConfig config, Widget? child) {
          // 선택 모드가 아니고, 손가락이 1개일 때만 GestureDetector 활성화
          final bool isPanEnabled = config.fingerCount > 1;
          final bool useGestureDetector = !config.isSelectionMode;

          return GestureDetector(
            onPanDown: (useGestureDetector && !isPanEnabled) ? _onPanDown : null,
            onPanUpdate: (useGestureDetector && !isPanEnabled) ? _onPanUpdate : null,
            onPanEnd: (useGestureDetector && !isPanEnabled) ? _onPanEnd : null,
            child: child,
          );
        },
        child: ClipRect(
          clipBehavior: widget.clipBehavior,
          child: RepaintBoundary(
            child: CustomPaint(
              isComplex: true,
              painter: _DeepPainter(controller: widget.drawingController),
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  painter: _UpPainter(controller: widget.drawingController),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _SelectionPainter(controller: widget.drawingController),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 表层画板绘制器
///
/// 负责绘制当前正在进行的实时绘制内容
/// 对于橡皮擦模式，还会显示底层内容叠加橡皮擦效果
///
/// Surface Layer Painter
///
/// Responsible for drawing the current real-time drawing content
/// For eraser mode, also displays the base content with eraser effect applied
class _UpPainter extends CustomPainter {
  _UpPainter({required this.controller}) : super(repaint: controller.painter);

  final DrawingController controller;

  @override
  void paint(Canvas canvas, Size size) {
    if (!controller.hasPaintingContent) {
      return;
    }

    if (controller.eraserContent != null) {
      // 橡皮擦模式：收集所有删除的对象索引（包括历史中的橡皮擦）
      // Eraser mode: collect all deleted object indices (including from history erasers)
      final Eraser currentEraser = controller.eraserContent as Eraser;
      final List<PaintContent> history = controller.getHistory;

      // 收集历史中所有橡皮擦已删除的对象索引
      // Collect all deleted indices from all erasers in history
      final Set<int> allDeletedIndices = <int>{};
      for (int i = 0; i < controller.currentIndex; i++) {
        if (history[i] is Eraser) {
          allDeletedIndices.addAll((history[i] as Eraser).deletedIndices);
        }
      }
      // 添加当前橡皮擦标记的删除对象
      // Add currently marked deletions
      allDeletedIndices.addAll(currentEraser.deletedIndices);

      // 绘制未被删除的对象，跳过所有橡皮擦本身
      // Draw objects that are not deleted, skip all erasers
      for (int i = 0; i < controller.currentIndex; i++) {
        if (i < history.length && !allDeletedIndices.contains(i) && history[i] is! Eraser) {
          history[i].draw(canvas, size, false);
        }
      }

      // 绘制当前橡皮擦轨迹以提供视觉反馈
      // Draw current eraser trail for visual feedback
      controller.eraserContent?.draw(canvas, size, false);
    } else {
      controller.drawingContent?.draw(canvas, size, false);
    }
  }

  @override
  bool shouldRepaint(covariant _UpPainter oldDelegate) => false;
}

/// 底层画板绘制器
///
/// 负责绘制所有历史记录内容，并生成缓存图片
/// 使用缓存机制优化性能，避免重复绘制
///
/// Deep Layer Painter
///
/// Responsible for drawing all historical content and generating cached images
/// Uses caching mechanism to optimize performance and avoid redundant drawing
class _DeepPainter extends CustomPainter {
  _DeepPainter({required this.controller}) : super(repaint: controller.realPainter);
  final DrawingController controller;

  /// 上次渲染的索引，用于缓存版本控制
  ///
  /// Last rendered index for cache version control
  static int _lastRenderedIndex = -1;

  /// 上次渲染的尺寸，用于缓存版本控制
  ///
  /// Last rendered size for cache version control
  static Size? _lastRenderedSize;

  @override
  void paint(Canvas canvas, Size size) {
    // 橡皮擦绘制时，屏蔽底层画板的绘制，由顶层画板负责显示
    if (controller.eraserContent != null) {
      return;
    }

    final List<PaintContent> contents = <PaintContent>[
      ...controller.getHistory,
    ];

    if (contents.isEmpty) {
      return;
    }

    // 收集所有被删除的对象索引
    // Collect all deleted object indices from Eraser objects
    final Set<int> deletedIndices = <int>{};
    for (int i = 0; i < controller.currentIndex; i++) {
      if (contents[i] is Eraser) {
        deletedIndices.addAll((contents[i] as Eraser).deletedIndices);
      }
    }

    // 直接绘制矢量内容以保持清晰度，跳过被删除的对象
    // Draw vector content directly for sharpness, skip deleted objects
    for (int i = 0; i < controller.currentIndex; i++) {
      // 跳过已被删除的对象和橡皮擦本身
      // Skip deleted objects and eraser itself
      if (!deletedIndices.contains(i) && contents[i] is! Eraser) {
        contents[i].draw(canvas, size, true);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DeepPainter oldDelegate) => false;
}

/// 选择框绘制器
///
/// 在选中的对象周围绘制蓝色选择框
///
/// Selection Box Painter
///
/// Draws blue selection box around selected object
class _SelectionPainter extends CustomPainter {
  _SelectionPainter({required this.controller}) : super(repaint: controller);

  final DrawingController controller;

  @override
  void paint(Canvas canvas, Size size) {
    // 只在选择模式且有选中对象时绘制
    // Only draw when in selection mode and an object is selected
    if (!controller.isSelectionMode || controller.selectedObjectIndex < 0) {
      return;
    }

    final int selectedIndex = controller.selectedObjectIndex;
    final List<PaintContent> history = controller.getHistory;

    if (selectedIndex >= history.length) {
      return;
    }

    final PaintContent selectedContent = history[selectedIndex];
    final Rect? bounds = selectedContent.getBounds();

    if (bounds == null) {
      return;
    }

    // 获取当前画布缩放比例，用于调整选择框大小
    // Get current canvas scale to adjust selection box size
    final double scale = controller.canvasScale;

    // 绘制蓝色选择框（线宽根据缩放调整，保持视觉大小恒定）
    // Draw blue selection box (stroke width adjusted by scale to maintain constant visual size)
    final Paint selectionPaint = Paint()
      ..color = const Color(0xFF2196F3) // 蓝色
      ..strokeWidth = 2.0 / scale // 除以scale使线宽在视觉上保持2.0
      ..style = PaintingStyle.stroke;

    // 添加一些padding使选择框更明显（padding也根据缩放调整）
    // Add padding to make selection box more visible (padding also adjusted by scale)
    final double padding = 4.0 / scale;
    final Rect paddedBounds = bounds.inflate(padding);
    canvas.drawRect(paddedBounds, selectionPaint);

    // 绘制四个角的小方块（大小根据缩放调整）
    // Draw small squares at corners (size adjusted by scale)
    final double handleSize = 8.0 / scale;
    final Paint handlePaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;

    final List<Offset> corners = <Offset>[
      paddedBounds.topLeft,
      paddedBounds.topRight,
      paddedBounds.bottomLeft,
      paddedBounds.bottomRight,
    ];

    for (final Offset corner in corners) {
      canvas.drawRect(
        Rect.fromCenter(center: corner, width: handleSize, height: handleSize),
        handlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) => true;
}
