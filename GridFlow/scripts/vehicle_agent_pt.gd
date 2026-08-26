extends VehicleAgent
class_name VehicleAgentPT

const ROUNDABOUT_DRIVE_RADIUS := 21.5
const ROUNDABOUT_MIN_STEPS := 8
const NO_HOME := Vector2i(-999, -999)

# Um veículo civil pertence sempre a uma casa e regressa a ela após servir o destino.
var home_building_cell: Vector2i = NO_HOME
var returning_home: bool = false

func setup(
    points: Array[Vector2],
    destination_cell: Vector2i,
    p_simulation: Node,
    p_color: Color = Color("#415A77"),
    p_is_emergency: bool = false,
    p_emergency_deadline: float = 0.0
) -> void:
    var expanded := _expand_roundabouts(points, p_simulation)
    super.setup(expanded, destination_cell, p_simulation, p_color, p_is_emergency, p_emergency_deadline)

func setup_commute(
    points: Array[Vector2],
    destination_cell: Vector2i,
    p_simulation: Node,
    p_color: Color,
    p_home_cell: Vector2i
) -> void:
    home_building_cell = p_home_cell
    returning_home = false
    setup(points, destination_cell, p_simulation, p_color, false, 0.0)

func begin_return_trip(points: Array[Vector2]) -> void:
    returning_home = true
    destination_building_cell = home_building_cell
    completed = false
    replace_path(points)

func replace_path(points: Array[Vector2]) -> void:
    var expanded := _expand_roundabouts(points, simulation)
    var replacement: Array[Vector2] = [position]
    for point: Vector2 in expanded:
        if replacement[-1].distance_to(point) > 1.0:
            replacement.append(point)
    path_points = replacement
    path_index = 1

func _expand_roundabouts(points: Array[Vector2], p_simulation: Node) -> Array[Vector2]:
    if p_simulation == null or points.size() < 3:
        return points.duplicate()

    var result: Array[Vector2] = [points[0]]

    for index: int in range(1, points.size() - 1):
        var point: Vector2 = points[index]
        var cell: Vector2i = p_simulation.world_to_cell(point)

        if not p_simulation.roundabouts.has(cell):
            result.append(point)
            continue

        var center: Vector2 = point
        var previous_point: Vector2 = points[index - 1]
        var next_point: Vector2 = points[index + 1]
        var entry_direction: Vector2 = (previous_point - center).normalized()
        var exit_direction: Vector2 = (next_point - center).normalized()

        if entry_direction.length_squared() <= 0.0 or exit_direction.length_squared() <= 0.0:
            result.append(point)
            continue

        var entry_angle: float = entry_direction.angle()
        var exit_angle: float = exit_direction.angle()

        # Em Portugal circula-se pela direita; visualmente seguimos a pista da rotunda
        # sem atravessar o centro do cruzamento.
        while exit_angle >= entry_angle:
            exit_angle -= TAU

        var arc_size: float = absf(exit_angle - entry_angle)
        var steps: int = maxi(ROUNDABOUT_MIN_STEPS, int(ceil(arc_size / 0.22)))

        for step: int in range(steps + 1):
            var t: float = float(step) / float(steps)
            var angle: float = lerpf(entry_angle, exit_angle, t)
            result.append(center + Vector2(cos(angle), sin(angle)) * ROUNDABOUT_DRIVE_RADIUS)

    result.append(points[-1])
    return result

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
    var final_driveway: bool = path_index == path_points.size() - 1 and target_cell == destination_building_cell
    var target_is_road: bool = simulation.is_road_cell(target_cell)

    if not target_is_road and not final_driveway:
        var nearest_cell: Vector2i = simulation.world_to_cell(target)
        if not simulation.roundabouts.has(nearest_cell):
            simulation.reroute_vehicle(self)
            return

    var allowed: bool = true
    var density: int = 0
    var capacity: int = 999
    var speed_factor: float = 1.0

    if target_is_road:
        allowed = simulation.can_vehicle_enter(self, position, target)
        density = simulation.get_occupancy(target_cell)
        capacity = simulation.get_cell_capacity(target_cell)
        speed_factor = simulation.get_speed_factor(target_cell, density)

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
