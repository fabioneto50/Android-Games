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
var visual_variant: int = 0

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
    visual_variant = abs(destination_cell.x * 13 + destination_cell.y * 29 + int(p_color.r * 255.0)) % 4
    z_index = 20
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

    queue_redraw()

func _finish_trip() -> void:
    if completed:
        return
    completed = true
    if simulation != null:
        simulation.vehicle_completed(self)

func _night_factor() -> float:
    var city_sim := simulation as CitySimulation
    if city_sim == null:
        return 0.0
    var hour: float = city_sim.city_minutes / 60.0
    if hour >= 21.0 or hour < 5.0:
        return 1.0
    if hour >= 19.0 and hour < 21.0:
        return smoothstep(19.0, 21.0, hour)
    if hour >= 5.0 and hour < 7.0:
        return 1.0 - smoothstep(5.0, 7.0, hour)
    return 0.0

func _draw() -> void:
    if is_emergency:
        _draw_ambulance()
        return

    match visual_variant:
        1:
            _draw_hatchback()
        2:
            _draw_van()
        3:
            _draw_taxi()
        _:
            _draw_sedan()

func _draw_vehicle_shadow(length: float, width: float) -> void:
    draw_rect(Rect2(Vector2(-length * 0.5 + 1.8, -width * 0.5 + 2.2), Vector2(length, width)), Color(0.0, 0.0, 0.0, 0.22), true)

func _draw_wheels(length: float, width: float) -> void:
    var wheel_color := Color("#161D20")
    var front_x := length * 0.26
    var rear_x := -length * 0.28
    draw_rect(Rect2(Vector2(rear_x - 1.7, -width * 0.5 - 1.0), Vector2(3.5, 2.0)), wheel_color, true)
    draw_rect(Rect2(Vector2(front_x - 1.7, -width * 0.5 - 1.0), Vector2(3.5, 2.0)), wheel_color, true)
    draw_rect(Rect2(Vector2(rear_x - 1.7, width * 0.5 - 1.0), Vector2(3.5, 2.0)), wheel_color, true)
    draw_rect(Rect2(Vector2(front_x - 1.7, width * 0.5 - 1.0), Vector2(3.5, 2.0)), wheel_color, true)

func _draw_lights(length: float, width: float) -> void:
    var night := _night_factor()
    var headlight := Color("#FFF1B8")
    draw_circle(Vector2(length * 0.5 - 0.6, -width * 0.27), 0.95, headlight)
    draw_circle(Vector2(length * 0.5 - 0.6, width * 0.27), 0.95, headlight)
    draw_circle(Vector2(-length * 0.5 + 0.6, -width * 0.27), 0.8, Color("#E45A58"))
    draw_circle(Vector2(-length * 0.5 + 0.6, width * 0.27), 0.8, Color("#E45A58"))

    if night > 0.15:
        var beam_alpha := 0.025 + night * 0.055
        draw_colored_polygon(PackedVector2Array([
            Vector2(length * 0.5, -width * 0.32),
            Vector2(length * 0.5 + 13.0, -5.0),
            Vector2(length * 0.5 + 13.0, 5.0),
            Vector2(length * 0.5, width * 0.32)
        ]), Color(1.0, 0.92, 0.62, beam_alpha))

func _draw_wait_indicator(length: float) -> void:
    if waiting:
        draw_circle(Vector2(-length * 0.5 - 2.0, 0.0), 1.7, Color("#F0C46B"))

func _draw_sedan() -> void:
    var length := 15.5
    var width := 8.2
    _draw_vehicle_shadow(length, width)
    _draw_wheels(length, width)
    draw_rect(Rect2(Vector2(-length * 0.5, -width * 0.5), Vector2(length, width)), vehicle_color, true)
    draw_rect(Rect2(Vector2(-6.0, -width * 0.5 + 0.7), Vector2(11.0, 1.1)), vehicle_color.lightened(0.25), true)
    var glass := Color(0.68, 0.84, 0.88, 0.93)
    draw_colored_polygon(PackedVector2Array([Vector2(-2.5, -3.0), Vector2(4.4, -3.0), Vector2(5.0, 3.0), Vector2(-2.5, 3.0)]), glass)
    draw_line(Vector2(0.6, -3.0), Vector2(0.6, 3.0), Color(0.12, 0.22, 0.25, 0.30), 0.9, true)
    _draw_lights(length, width)
    _draw_wait_indicator(length)

func _draw_hatchback() -> void:
    var length := 13.8
    var width := 8.6
    _draw_vehicle_shadow(length, width)
    _draw_wheels(length, width)
    draw_rect(Rect2(Vector2(-length * 0.5, -width * 0.5), Vector2(length, width)), vehicle_color.lightened(0.04), true)
    var glass := Color(0.70, 0.86, 0.90, 0.93)
    draw_colored_polygon(PackedVector2Array([Vector2(-3.8, -3.2), Vector2(3.7, -3.2), Vector2(4.6, 3.2), Vector2(-3.8, 3.2)]), glass)
    draw_line(Vector2(-0.2, -3.2), Vector2(-0.2, 3.2), Color(0.12, 0.22, 0.25, 0.32), 0.9, true)
    _draw_lights(length, width)
    _draw_wait_indicator(length)

func _draw_van() -> void:
    var length := 18.4
    var width := 9.2
    _draw_vehicle_shadow(length, width)
    _draw_wheels(length, width)
    draw_rect(Rect2(Vector2(-length * 0.5, -width * 0.5), Vector2(length, width)), vehicle_color.darkened(0.02), true)
    draw_rect(Rect2(Vector2(2.1, -3.5), Vector2(5.0, 7.0)), Color(0.68, 0.84, 0.88, 0.93), true)
    draw_line(Vector2(-1.8, -3.2), Vector2(-1.8, 3.2), vehicle_color.darkened(0.18), 1.0, true)
    draw_line(Vector2(-5.6, -3.2), Vector2(-5.6, 3.2), vehicle_color.darkened(0.18), 1.0, true)
    _draw_lights(length, width)
    _draw_wait_indicator(length)

func _draw_taxi() -> void:
    var length := 15.8
    var width := 8.2
    _draw_vehicle_shadow(length, width)
    _draw_wheels(length, width)
    var taxi_color := Color("#E6C45C").lerp(vehicle_color, 0.18)
    draw_rect(Rect2(Vector2(-length * 0.5, -width * 0.5), Vector2(length, width)), taxi_color, true)
    draw_colored_polygon(PackedVector2Array([Vector2(-2.4, -3.0), Vector2(4.4, -3.0), Vector2(5.0, 3.0), Vector2(-2.4, 3.0)]), Color(0.67, 0.83, 0.87, 0.93))
    draw_rect(Rect2(Vector2(-1.5, -width * 0.5 - 1.8), Vector2(5.0, 1.6)), Color("#F2E7B3"), true)
    _draw_lights(length, width)
    _draw_wait_indicator(length)

func _draw_ambulance() -> void:
    var length := 18.2
    var width := 10.0
    _draw_vehicle_shadow(length, width)
    _draw_wheels(length, width)
    draw_rect(Rect2(Vector2(-length * 0.5, -width * 0.5), Vector2(length, width)), Color("#F3F5F2"), true)
    draw_rect(Rect2(Vector2(-length * 0.5, width * 0.5 - 2.5), Vector2(length, 2.5)), Color("#E65D5F"), true)
    draw_rect(Rect2(Vector2(2.0, -3.7), Vector2(5.5, 7.4)), Color(0.66, 0.82, 0.86, 0.94), true)
    draw_rect(Rect2(Vector2(-4.0, -1.1), Vector2(7.0, 2.2)), Color("#E65D5F"), true)
    draw_rect(Rect2(Vector2(-1.6, -3.5), Vector2(2.2, 7.0)), Color("#E65D5F"), true)

    var flash: bool = int(emergency_elapsed * 6.0) % 2 == 0
    var left_light := Color("#4F8CFF") if flash else Color("#FF5F61")
    var right_light := Color("#FF5F61") if flash else Color("#4F8CFF")
    draw_circle(Vector2(-3.2, -width * 0.5 - 2.0), 1.9, left_light)
    draw_circle(Vector2(3.2, -width * 0.5 - 2.0), 1.9, right_light)
    draw_circle(Vector2(-3.2, -width * 0.5 - 2.0), 5.0, Color(left_light, 0.08))
    draw_circle(Vector2(3.2, -width * 0.5 - 2.0), 5.0, Color(right_light, 0.08))
    draw_arc(Vector2.ZERO, 12.5 + sin(emergency_elapsed * 5.0), 0.0, TAU, 22, Color(0.38, 0.78, 0.64, 0.25), 2.0, true)
    _draw_lights(length, width)
