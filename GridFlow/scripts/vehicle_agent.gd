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

func _finish_trip() -> void:
    if completed:
        return
    completed = true
    if simulation != null:
        simulation.vehicle_completed(self)

func _draw() -> void:
    var body_size: Vector2 = Vector2(16.0, 9.0) if is_emergency else Vector2(14.0, 8.0)
    draw_rect(Rect2(-body_size * 0.5, body_size), vehicle_color, true)
    draw_rect(Rect2(Vector2(0.0, -3.0), Vector2(4.0, 6.0)), Color(0.88, 0.93, 0.95, 0.85), true)

    if is_emergency:
        draw_rect(Rect2(Vector2(-3.0, -1.0), Vector2(6.0, 2.0)), Color.WHITE, true)
        draw_rect(Rect2(Vector2(-1.0, -3.0), Vector2(2.0, 6.0)), Color.WHITE, true)
        draw_circle(Vector2(-3.0, -5.2), 1.7, Color("#3C7DFF"))
        draw_circle(Vector2(3.0, -5.2), 1.7, Color("#FF5D5D"))
