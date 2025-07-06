# Marker Slide Feature Implementation Plan

## Overview
Add a marker slide feature that allows users to long-press and drag markers to new locations, automatically updating the corresponding PointModel in the global state provider upon release.

## Current Behavior (Preserved)
- **Tap on marker**: Shows info panel with point details
- **Move mode**: Existing point movement functionality
- **Marker styling**: Current visual appearance and state-based colors

## New Feature: Marker Slide
- **Long press**: Initiates slide mode
- **Drag**: Moves marker to new position with visual feedback
- **Release**: Updates point coordinates in global state

## Implementation Strategy

### 1. Gesture Detection Strategy
- **Tap**: Shows info panel (existing behavior)
- **Long Press**: Initiates slide mode
- **Drag during slide**: Moves marker to new position
- **Release**: Updates point coordinates in global state

### 2. State Management Updates

#### MapStateManager Additions
```dart
// New properties
bool isSlidingMarker = false;
String? slidingPointId;
LatLng? originalPosition;
LatLng? currentSlidePosition;

// New methods
void startSlidingMarker(PointModel point, LatLng originalPos);
void updateSlidePosition(LatLng newPosition);
void endSlidingMarker(BuildContext context);
```

### 3. Visual Feedback During Slide
- **Ghost marker**: Show original position marker
- **Sliding marker**: Different color/glow effect
- **Distance indicator**: Show distance from original position
- **Interaction blocking**: Disable other map interactions during slide

### 4. Implementation Steps

#### Step 1: Update MapMarkers Class
**File**: `lib/ui/tabs/map/markers/map_markers.dart`

Add new callback parameters to `buildAllMapMarkers()`:
```dart
static List<Marker> buildAllMapMarkers({
  // ... existing parameters
  required Function(PointModel, LongPressStartDetails) onLongPressStart,
  required Function(PointModel, LongPressMoveUpdateDetails) onLongPressMoveUpdate,
  required Function(PointModel, LongPressEndDetails) onLongPressEnd,
  required bool isSlidingMarker,
  required String? slidingPointId,
}) {
  // Update marker building logic
}
```

Update `_buildProjectPointMarker()` to handle slide state:
```dart
// Add slide mode styling
if (isSlidingMarker && point.id == slidingPointId) {
  // Apply slide mode visual effects
  markerColor = Colors.purple; // or other slide indicator color
  // Add glow effect
}
```

#### Step 2: Update FlutterMapWidget
**File**: `lib/ui/tabs/map/widgets/flutter_map_widget.dart`

Add gesture handlers to marker creation:
```dart
onLongPressStart: (point, details) => _handleLongPressStart(point, details),
onLongPressMoveUpdate: (point, details) => _handleLongPressMoveUpdate(point, details),
onLongPressEnd: (point, details) => _handleLongPressEnd(point, details),
```

#### Step 3: Update MapStateManager
**File**: `lib/ui/tabs/map/state/map_state_manager.dart`

Add slide state management:
```dart
// Add slide state properties
bool isSlidingMarker = false;
String? slidingPointId;
LatLng? originalPosition;
LatLng? currentSlidePosition;

// Add slide methods
void startSlidingMarker(PointModel point, LatLng originalPos);
void updateSlidePosition(LatLng newPosition);
void endSlidingMarker(BuildContext context);
```

#### Step 4: Coordinate Conversion
Use existing MapController for screen-to-map coordinate conversion:
```dart
// Convert screen coordinates to map coordinates
LatLng mapPosition = mapController.camera.pointToLatLng(screenPosition);
```

### 5. User Experience Flow

1. **Long Press**: 
   - Marker starts glowing
   - Enters slide mode
   - Shows visual feedback

2. **Drag**: 
   - Marker follows finger
   - Shows distance from original position
   - Updates position in real-time

3. **Visual Feedback**: 
   - Ghost marker at original position
   - Distance indicator
   - Different marker styling for sliding marker

4. **Release**: 
   - Show confirmation dialog
   - Update point coordinates in global state
   - Exit slide mode

### 6. Technical Considerations

#### Coordinate System
- Handle screen-to-map coordinate conversion
- Account for map rotation and zoom
- Validate coordinates (within bounds)
- Use existing `MapController.camera.pointToLatLng()`

#### Performance
- Throttle position updates during drag
- Use efficient coordinate conversion
- Minimize rebuilds during slide
- Optimize marker rendering during slide mode

#### Error Handling
- Handle invalid coordinates
- Cancel slide on errors
- Provide user feedback for failed operations
- Graceful fallback to original position

#### Haptic Feedback
- Add haptic feedback on long press start
- Provide feedback on successful slide completion
- Error feedback for failed operations

### 7. Integration with Existing Code

#### Preserve Current Behavior
- Keep tap functionality unchanged
- Maintain info panel behavior
- Preserve move mode functionality
- Maintain existing marker styling for non-slide states

#### Global State Updates
- Use existing `ProjectStateManager` for updates
- Follow current state management patterns
- Trigger appropriate UI updates
- Maintain data consistency

#### Map Controller Integration
- Use existing `MapController` for coordinate conversion
- Integrate with current map event handling
- Maintain map state consistency
- Leverage existing map bounds validation

### 8. Testing Strategy

#### Unit Tests
- Test coordinate conversion logic
- Test slide state management
- Test error handling scenarios

#### Integration Tests
- Test slide-to-update flow
- Test interaction with existing features
- Test state management integration

#### UI Tests
- Test gesture recognition
- Test visual feedback
- Test slide completion flow

#### Edge Cases
- Test boundary conditions
- Test invalid coordinates
- Test rapid gesture sequences
- Test map zoom/rotation during slide

### 9. Files to Modify

1. **`lib/ui/tabs/map/markers/map_markers.dart`**
   - Add gesture handlers
   - Update marker styling for slide mode
   - Add slide state parameters

2. **`lib/ui/tabs/map/widgets/flutter_map_widget.dart`**
   - Add gesture callback handling
   - Integrate slide state with marker creation

3. **`lib/ui/tabs/map/state/map_state_manager.dart`**
   - Add slide state properties
   - Add slide management methods
   - Integrate with existing state management

4. **`lib/ui/tabs/map/map_tool_view.dart`**
   - Pass slide state to FlutterMapWidget
   - Handle slide callbacks

### 10. Success Criteria

- [ ] Long press on marker initiates slide mode
- [ ] Marker follows finger during drag
- [ ] Visual feedback shows slide state
- [ ] Release updates point coordinates in global state
- [ ] Existing tap functionality preserved
- [ ] Error handling for invalid coordinates
- [ ] Haptic feedback provided
- [ ] Performance optimized for smooth sliding
- [ ] Integration with existing state management
- [ ] Comprehensive test coverage

## Notes
- Screen reader support and keyboard navigation alternatives are intentionally excluded from this implementation
- Focus on touch-based interaction for mobile devices
- Maintain existing accessibility features where applicable 