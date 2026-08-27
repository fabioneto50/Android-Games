extends CitySimulationEconomy
class_name CitySimulationGameplay

# Mobile-first interaction layer for the economy simulation.
# It keeps the existing gameplay/economy rules but makes taps, pinch zoom and
# map movement substantially more forgiving on phones and tablets.

const BUILDING_TAP_RADIUS := 25.0
const MIN_GAMEPLAY_ZOOM := 0.55
const MAX_GAMEPLAY_ZOOM := 3.0

var _touch_points: Dictionary = {}
var _primary_touch_index: int = -1
var _touch_started_position := Vector2.ZERO
var _touch_moved: bool = false
var _pinch_last_distance: float = 0.0
var _pinch_last_center := Vector2.ZERO
var _selected_building_cell := INVALID_CELL

func zoom_by(factor: float, screen_center: Vector2 = Vector2(640.0, 360.0)) -> void:
    var old_zoom: float = view_zoom
    var new_zoom: float = clampf(old_zoom * factor, MIN_GAMEPLAY_ZOOM, MAX_GAMEPLAY_ZOOM)
    if is_equal_approx(old_zoom, new_zoom):
        return

    var world_anchor: Vector2 = (screen_center - position) / old_zoom
    view_zoom = new_zoom
    scale = Vector2.ONE * view_zoom
    position = screen_center - world_anchor * view_zoom
    _clamp_view_position()
    queue_redraw()
    _emit_hud()

func reset_view() -> void:
    view_zoom = 1.0
    scale = Vector2.ONE
    position = Vector2.ZERO
    queue_redraw()
    _emit_hud()

func _pan_by(screen_delta: Vector2) -> void:
    position += screen_delta
    _clamp_view_position()

func _clamp_view_position() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    var scaled_world: Vector2 = WORLD_SIZE * view_zoom

    if scaled_world.x <= viewport_size.x:
        position.x = (viewport_size.x - scaled_world.x) * 0.5
    else:
        position.x = clampf(position.x, viewport_size.x - scaled_world.x, 0.0)

    if scaled_world.y <= viewport_size.y:
        position.y = (viewport_size.y - scaled_world.y) * 0.5
    else:
        position.y = clampf(position.y, viewport_size.y - scaled_world.y, 0.0)

func _begin_interaction(world_position: Vector2) -> void:
    var building: CityBuilding = _building_near_world_position(world_position)
    if building != null:
        _selected_building_cell = building.cell
        building_selected.emit(building.cell)
        queue_redraw()
        return
    super._begin_interaction(world_position)

func _building_near_world_position(world_position: Vector2) -> CityBuilding:
    var nearest: CityBuilding = null
    var best_distance_sq: float = BUILDING_TAP_RADIUS * BUILDING_TAP_RADIUS

    for building: CityBuilding in buildings:
        var center: Vector2 = cell_to_world(building.cell)
        var distance_sq: float = center.distance_squared_to(world_position)
        if distance_sq <= best_distance_sq:
            best_distance_sq = distance_sq
            nearest = building

    return nearest

func clear_building_selection() -> void:
    _selected_building_cell = INVALID_CELL
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if is_game_over or awaiting_upgrade:
        return

    # Godot's InputEventMagnifyGesture does not cover the normal two-finger
    # touchscreen gesture on every mobile platform. Track touches explicitly.
    if event is InputEventScreenTouch:
        _handle_screen_touch(event)
        return

    if event is InputEventScreenDrag:
        _handle_screen_drag(event)
        return

    # Keep mouse wheel, mouse drag and trackpad magnify support from the base game.
    super._unhandled_input(event)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
    if event.pressed:
        _touch_points[event.index] = event.position

        if _touch_points.size() == 1:
            _primary_touch_index = event.index
            _touch_started_position = event.position
            _touch_moved = false
            _pinch_last_distance = 0.0
            _pinch_last_center = event.position
        elif _touch_points.size() == 2:
            _dragging = false
            _panning = false
            _last_drag_cell = INVALID_CELL
            _touch_moved = true
            _reset_pinch_reference()
        return

    var was_single_primary: bool = _touch_points.size() == 1 and event.index == _primary_touch_index
    var should_tap: bool = was_single_primary and not _touch_moved

    if should_tap:
        _begin_screen_interaction(event.position)
        _end_interaction()
    else:
        _end_interaction()

    _touch_points.erase(event.index)

    if _touch_points.is_empty():
        _primary_touch_index = -1
        _touch_moved = false
        _pinch_last_distance = 0.0
        _pinch_last_center = Vector2.ZERO
    elif _touch_points.size() == 1:
        var remaining_keys: Array = _touch_points.keys()
        _primary_touch_index = int(remaining_keys[0])
        _touch_started_position = _touch_points[_primary_touch_index]
        # A finger left after a pinch must never turn into an accidental tap.
        _touch_moved = true
        _pinch_last_distance = 0.0
        _pinch_last_center = _touch_started_position

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
    _touch_points[event.index] = event.position

    if _touch_points.size() >= 2:
        _touch_moved = true
        var keys: Array = _touch_points.keys()
        var first: Vector2 = _touch_points[keys[0]]
        var second: Vector2 = _touch_points[keys[1]]
        var center: Vector2 = (first + second) * 0.5
        var distance: float = first.distance_to(second)

        if _pinch_last_distance > 1.0:
            var center_delta: Vector2 = center - _pinch_last_center
            if center_delta.length_squared() > 0.01:
                _pan_by(center_delta)

            var factor: float = clampf(distance / _pinch_last_distance, 0.82, 1.22)
            zoom_by(factor, center)

        _pinch_last_distance = maxf(distance, 1.0)
        _pinch_last_center = center
        return

    if event.index != _primary_touch_index:
        _primary_touch_index = event.index
        _touch_started_position = event.position - event.relative

    if not _touch_moved:
        _touch_moved = true
        if interaction_mode == "pan":
            _panning = true
        else:
            _begin_interaction(screen_to_world(_touch_started_position))

    if interaction_mode == "pan":
        _panning = true
        _pan_by(event.relative)
    elif _dragging:
        _continue_interaction(screen_to_world(event.position))

func _reset_pinch_reference() -> void:
    if _touch_points.size() < 2:
        _pinch_last_distance = 0.0
        return

    var keys: Array = _touch_points.keys()
    var first: Vector2 = _touch_points[keys[0]]
    var second: Vector2 = _touch_points[keys[1]]
    _pinch_last_distance = maxf(first.distance_to(second), 1.0)
    _pinch_last_center = (first + second) * 0.5

func _draw() -> void:
    super._draw()

    if _selected_building_cell == INVALID_CELL:
        return

    var building: CityBuilding = _building_at_cell(_selected_building_cell)
    if building == null:
        _selected_building_cell = INVALID_CELL
        return

    var center: Vector2 = cell_to_world(building.cell)
    draw_arc(center, 23.0, 0.0, TAU, 32, Color("#F6E27A"), 3.0, true)
    draw_circle(center + Vector2(17.0, -17.0), 5.0, Color("#F6E27A"))
