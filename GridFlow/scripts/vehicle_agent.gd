extends Node2D
class_name VehicleAgent

var path_points: Array[Vector2] = []
var path_index: int = 1
var destination_building_cell: Vector2i = Vector2i.ZERO
var simulation: Node
var base_speed: float = 86.0
var waiting: bool = false
var completed: bool = false
var vehicle_color: Color = Color("#415A77")
var is_emergency: bool = false
var emergency_elapsed: float = 0.0
var emergency_deadline: float = 0.0

func setup(
    points: Array[Vector2],
    destination_cell: Vector2i,
    p_simulation: Node,
    p_color: Color = Color("#415A77"),
    p_is_emergency: bool = false,
    p_emergency_deadline: float = 0.0
) -> void:
    path_points = points.duplicate()
    destination_building_cell = destination_cell
    simulation = p_simulation
    vehicle_color = p_color
    is_emergency = p_is_emergency
    emergency_deadline = p_emergency_deadline
    base_speed = 118.0 if is_emergency else 86.0
    if path_points.is_empty():
        completed = true
        return
    position = path_points[0]
    path_index = 1
    queue_redraw()

func replace_path(points: Array[Vector2]) -> void:
    var replacement: Array[Vector2] = [position]
    for point: Vector2 in points:
        if replacement[-1].distance_to(point) > 1.0:
            replacement.append(point)
    path_points = replacement
    path_index = 1

func _process(delta: float) -> void:
    if completed or simulation == null:
        return
    if simulation.paused or simulation.awaiting_upgrade:
        waiting = false
        return

    if is_emergency and emergency_deadline > 0.0:
        emergency_elapsed += delta * simulation.time_scale
        if emergency_elapsed >= emergency_deadline:
            completed = true
            simulation.emergency_vehicle_timed_out(self)
            return

    if path_index >= path_points.size():
        _finish_trip()
        return

    var target: Vector2 = path_points[path_index]
    var target_cell: Vector2i = simulation.world_to_cell(target)

    if not simulation.is_road_cell(target_cell):
        simulation.reroute_vehicle(self)
        return

    var allowed: bool = simulation.can_vehicle_enter(self, position, target)
    var density: int = simulation.get_occupancy(target_cell)
    var capacity: int = simulation.get_cell_capacity(target_cell)
    var speed_factor: float = simulation.get_speed_factor(target_cell, density)
    if is_emergency:
        speed_factor = minf(1.28, speed_factor + 0.16)

    var hard_limit: int = capacity + (4 if is_emergency else 2)
    if not allowed or density >= hard_limit:
        waiting = true
        queue_redraw()
        return

    waiting = false
    var direction: Vector2 = (target - position).normalized()
    if direction.length_squared() > 0.0:
        rotation = direction.angle()

    var travel: float = base_speed * speed_factor * delta * simulation.time_scale
    position = position.move_toward(target, travel)

    if position.distance_to(target) <= 1.0:
        position = target
        path_index += 1
        if path_index >= path_points.size():
            _finish_trip()

    if is_emergency:
        queue_redraw()

func _finish_trip() -> void:
    if completed:
        return
    completed = true
    if simulation != null:
        simulation.vehicle_completed(self)

func _draw() -> void:
    var length: float = 17.0 if is_emergency else 15.0
    var width: float = 9.5 if is_emergency else 8.2

    # Soft shadow creates separation from the road surface.
    draw_rect(Rect2(Vector2(-length * 0.5 + 1.6, -width * 0.5 + 2.0), Vector2(length, width)), Color(0.0, 0.0, 0.0, 0.22), true)

    # Wheels.
    var wheel_color := Color("#161D20")
    draw_rect(Rect2(Vector2(-5.2, -width * 0.5 - 1.1), Vector2(4.0, 2.0)), wheel_color, true)
    draw_rect(Rect2(Vector2(2.0, -width * 0.5 - 1.1), Vector2(4.0, 2.0)), wheel_color, true)
    draw_rect(Rect2(Vector2(-5.2, width * 0.5 - 0.9), Vector2(4.0, 2.0)), wheel_color, true)
    draw_rect(Rect2(Vector2(2.0, width * 0.5 - 0.9), Vector2(4.0, 2.0)), wheel_color, true)

    # Main body and subtle highlight.
    var body_rect := Rect2(Vector2(-length * 0.5, -width * 0.5), Vector2(length, width))
    draw_rect(body_rect, vehicle_color, true)
    draw_rect(Rect2(Vector2(-length * 0.5 + 1.0, -width * 0.5 + 0.8), Vector2(length - 2.0, 1.2)), vehicle_color.lightened(0.28), true)

    # Cabin / glass.
    var glass := Color(0.70, 0.86, 0.90, 0.92)
    draw_colored_polygon(PackedVector2Array([
        Vector2(-1.5, -width * 0.5 + 1.4),
        Vector2(4.8, -width * 0.5 + 1.4),
        Vector2(5.6, width * 0.5 - 1.4),
        Vector2(-1.5, width * 0.5 - 1.4)
    ]), glass)
    draw_line(Vector2(1.0, -width * 0.5 + 1.4), Vector2(1.0, width * 0.5 - 1.4), Color(0.15, 0.25, 0.28, 0.35), 1.0, true)

    # Head/tail lights make movement direction immediately legible.
    draw_circle(Vector2(length * 0.5 - 0.7, -2.3), 1.0, Color("#FFF0B0"))
    draw_circle(Vector2(length * 0.5 - 0.7, 2.3), 1.0, Color("#FFF0B0"))
    draw_circle(Vector2(-length * 0.5 + 0.6, -2.2), 0.85, Color("#E45A58"))
    draw_circle(Vector2(-length * 0.5 + 0.6, 2.2), 0.85, Color("#E45A58"))

    if waiting and not is_emergency:
        draw_circle(Vector2(-length * 0.5 - 2.0, 0.0), 1.6, Color("#F0C46B"))

    if is_emergency:
        # Ambulance identity and animated emergency lights.
        draw_rect(Rect2(Vector2(-3.2, -1.0), Vector2(6.4, 2.0)), Color.WHITE, true)
        draw_rect(Rect2(Vector2(-1.0, -3.2), Vector2(2.0, 6.4)), Color.WHITE, true)
        var flash: bool = int(emergency_elapsed * 5.5) % 2 == 0
        var left_light := Color("#4F8CFF") if flash else Color("#FF5F61")
        var right_light := Color("#FF5F61") if flash else Color("#4F8CFF")
        draw_circle(Vector2(-3.1, -width * 0.5 - 2.0), 1.8, left_light)
        draw_circle(Vector2(3.1, -width * 0.5 - 2.0), 1.8, right_light)
        draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 20, Color(0.38, 0.78, 0.64, 0.22), 2.0, true)
