# Selection Mode Feature Guide

## Overview

The Selection Mode feature allows you to toggle between two interaction modes:
- **Drawing Mode** (default): Drawing is enabled, canvas pan/zoom is disabled
- **Selection Mode**: Canvas pan/zoom is enabled, drawing is disabled

This provides better control over canvas interaction, especially useful when you want to:
1. Navigate and zoom the canvas without accidentally drawing
2. Separate drawing and viewing workflows

## Implementation Status

### ✅ Phase 1: Basic Selection Mode (Completed)

**Features:**
- Toggle between selection mode and drawing mode
- Selection mode enables canvas pan/zoom
- Drawing mode enables drawing tools
- Visual indicator (icon + color) shows current mode

**Modified Files:**
- `lib/src/drawing_controller.dart` - Added `isSelectionMode` field and `setSelectionMode()` method
- `lib/src/drawing_board.dart` - Dynamic pan/scale control based on selection mode
- `lib/src/painter.dart` - Disabled drawing in selection mode
- `example/lib/main.dart` - Added selection mode toggle button

## Usage

### Basic Usage

```dart
// Get the drawing controller
final DrawingController controller = DrawingController();

// Enable selection mode (canvas pan/zoom enabled, drawing disabled)
controller.setSelectionMode(true);

// Enable drawing mode (drawing enabled, canvas pan/zoom disabled)
controller.setSelectionMode(false);

// Check current mode
if (controller.isSelectionMode) {
  print('Currently in selection mode');
}
```

### UI Integration

Add a toggle button to your toolbar:

```dart
DrawingBar(
  controller: _drawingController,
  tools: [
    // ... other tools ...
    
    // Selection mode toggle button
    DefaultActionItem(
      onTap: (controller) {
        controller.setSelectionMode(!controller.isSelectionMode);
      },
      childBuilder: (context, controller) {
        return Icon(
          controller.isSelectionMode ? Icons.pan_tool : Icons.edit,
          size: 24,
          color: controller.isSelectionMode ? Colors.blue : Colors.grey,
        );
      },
    ),
  ],
)
```

### Icon States

- 🖐️ **Blue hand icon (`Icons.pan_tool`)**: Selection mode active - You can pan and zoom the canvas
- ✏️ **Grey pen icon (`Icons.edit`)**: Drawing mode active - You can draw on the canvas

## Testing

Run the example app to test the feature:

```bash
cd example
flutter run
```

**Test Steps:**
1. Launch the app
2. Try drawing on the canvas (should work in default mode)
3. Click the selection mode toggle button (rightmost button in top toolbar)
4. Try drawing (should not work)
5. Try pinch-to-zoom or pan gestures (should work)
6. Click the toggle button again to switch back to drawing mode
7. Try drawing again (should work)

## Future Enhancements (Phase 2)

The following features are planned for future implementation:

### Object Selection and Manipulation
- Tap on drawn objects to select them
- Show bounding box with corner handles around selected objects
- Resize objects by dragging corner handles (maintaining aspect ratio)
- Move objects by dragging them
- Rotate objects using a rotation handle at the top of the bounding box

### Implementation Plan
1. Create a `SelectionPaintContent` class to represent selection state
2. Add hit-testing logic to detect taps on paint contents
3. Implement transform handles (resize, rotate, move)
4. Add gesture recognizers for manipulation
5. Update rendering to show selection UI overlay

## API Reference

### DrawingController Methods

#### `setSelectionMode(bool enabled)`
Enable or disable selection mode.

**Parameters:**
- `enabled`: `true` for selection mode, `false` for drawing mode

**Example:**
```dart
controller.setSelectionMode(true);  // Enable selection mode
```

#### `isSelectionMode`
Get the current mode status.

**Returns:** `bool` - `true` if in selection mode, `false` if in drawing mode

**Example:**
```dart
bool isSelection = controller.isSelectionMode;
```

### DrawConfig Properties

#### `isSelectionMode`
A boolean field in `DrawConfig` that tracks the current mode state.

This field is automatically updated when calling `setSelectionMode()` and triggers rebuild of components listening to `drawConfig`.

## Technical Details

### Architecture

The selection mode is implemented using Flutter's reactive pattern:

1. **State Management**: `DrawConfig` class holds the `isSelectionMode` state
2. **Controller**: `DrawingController` provides `setSelectionMode()` method to update state
3. **Reactive UI**: `ExValueBuilder` listens to `drawConfig` changes and rebuilds affected widgets
4. **Conditional Logic**: 
   - `DrawingBoard`: Controls `InteractiveViewer`'s `panEnabled` and `scaleEnabled`
   - `Painter`: Blocks touch events from triggering drawing operations

### Performance

- No performance impact when switching modes
- Uses Flutter's efficient rebuild mechanism (only affected widgets rebuild)
- No additional memory overhead

### Compatibility

- ✅ Fully backward compatible with existing code
- ✅ Default mode is drawing mode (same as before)
- ✅ No breaking changes to existing APIs

## Troubleshooting

### Issue: Selection mode button doesn't work

**Solution:** Make sure you're using the correct controller instance and the `DrawingBar` is properly wrapped with the controller provider.

### Issue: Drawing still works in selection mode

**Solution:** Check that your `Painter` widget is using the latest version with selection mode checks in the pointer event handlers.

### Issue: Can't pan/zoom in selection mode

**Solution:** Verify that `boardPanEnabled` and `boardScaleEnabled` are set to `true` in your `DrawingBoard` widget (they are `true` by default).

## Contributing

If you find any issues or have suggestions for improvements, please open an issue on the GitHub repository.

## License

This feature is part of the flutter_drawing_board package and is licensed under the MIT License.

