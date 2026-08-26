extends Node2D
class_name CitySimulation

signal hud_updated(snapshot: Dictionary)
signal toast_requested(message: String)
signal game_over(snapshot: Dictionary)

const GRID_SIZE := 48.0
const GRID_ORIGIN := Vector2(24.0, 24.0)
const WORLD_SIZE := Vector2(1280.0, 720.0)
const MIN_CELL := Vector2i(0, 2)
const MAX_CELL := Vector2i(26, 14)
const INVALID_CELL := Vector2i(-999, -999)

const BACKGROUND := Color("#F4F0E6")
const GRID_DOT := Color("#DED9CE")
const ROAD_COLOR := Color("#36454F")
const ROAD_MARKING := Color("#BBC4C7")
const RESIDENTIAL_COLOR := Color("#E88D67")
const OFFICE_COLOR := Color("#6C91C2")
const SHOP_COLOR := Color("#E9C46A")
const HOSPITAL_COLOR := Color("#D85D5D")

var graph := RoadGraph.new()
var road_cells: Dictionary = {}
var traffic_lights: Dictionary = {}
var buildings: Array[CityBuilding] = []
var vehicles: Array[VehicleAgent] = []
var occupancy: Dictionary = {}
var rng := RandomNumberGenerator.new()

var interaction_mode: String = "road"
var paused: bool = false
var time_scale: float = 1.0
var is_game_over: bool = false

var road_budget: int = 120
var week: int = 1
var completed_trips: int = 0
var pending_demand: int = 0
var flow_score: float = 100.0
var critical_time: float = 0.0
var sim_time: float = 0.0

var _dragging: bool = false
var _last_drag_cell := INVALID_CELL
var _growth_timer: float = 0.0
var _demand_timer: float = 0.0
var _week_timer: float = 0.0
var _hud_timer: float = 0.0

func _ready() -> void:
    rng.randomize()
    _create_starter_city()
    queue_redraw()
    _emit_hud()

func _process(delta: float) -> void:
    if paused or is_game_over:
        return

    var sim_delta := delta * time_scale
    sim_time += sim_delta
    _growth_timer += sim_delta
    _demand_timer += sim_delta
    _week_timer += sim_delta
    _hud_timer += delta

    _rebuild_occupancy()

    if _growth_timer >= 9.0:
        _growth_timer = 0.0
        _spawn_building()

    if _demand_timer >= 1.7:
        _demand_timer = 0.0
        _generate_trip()

    if _week_timer >= 60.0:
        _week_timer = 0.0
        week += 1
        road_budget += 20
        toast_requested.emit("Week %d: +20 road segments" % week)

    _update_flow(sim_delta)

    if _hud_timer >= 0.15:
        _hud_timer = 0.0
        _emit_hud()

    queue_redraw()

func set_mode(mode: String) -> void:
    interaction_mode = mode
    _dragging = false
    _last_drag_cell = INVALID_CELL

func set_paused(value: bool) -> void:
    paused = value
    _emit_hud()

func cycle_speed() -> void:
    if time_scale < 1.5:
        time_scale = 2.0
    elif time_scale < 2.5:
        time_scale = 3.0
    else:
        time_scale = 1.0
    _emit_hud()

func get_snapshot() -> Dictionary:
    return {
        "flow": int(round(flow_score)),
        "week": week,
        "roads": road_budget,
        "trips": completed_trips,
        "pending": pending_demand,
        "vehicles": vehicles.size(),
        "population": _estimate_population(),
        "speed": int(time_scale),
        "paused": paused,
        "mode": interaction_mode,
        "score": completed_trips * 10 + (week - 1) * 100
    }

func world_to_cell(world_position: Vector2) -> Vector2i:
    return Vector2i(
        int(round((world_position.x - GRID_ORIGIN.x) / GRID_SIZE)),
        int(round((world_position.y - GRID_ORIGIN.y) / GRID_SIZE))
    )

func cell_to_world(cell: Vector2i) -> Vector2:
    return GRID_ORIGIN + Vector2(cell.x * GRID_SIZE, cell.y * GRID_SIZE)

func is_road_cell(cell: Vector2i) -> bool:
    return road_cells.has(cell)

func get_occupancy(cell: Vector2i) -> int:
    return int(occupancy.get(cell, 0))

func can_vehicle_enter(from_world: Vector2, to_world: Vector2) -> bool:
    var target_cell := world_to_cell(to_world)
    if not traffic_lights.has(target_cell):
        return true

    var from_cell := world_to_cell(from_world)
    var delta := target_cell - from_cell
    if delta == Vector2i.ZERO:
        return true

    var vertical_move: bool = abs(delta.y) >= abs(delta.x)
    var vertical_green: bool = _vertical_signal_green(target_cell)
    return vertical_green if vertical_move else not vertical_green

func vehicle_completed(vehicle: VehicleAgent) -> void:
    completed_trips += 1
    pending_demand = max(0, pending_demand - 1)
    vehicles.erase(vehicle)
    vehicle.queue_free()

func reroute_vehicle(vehicle: VehicleAgent) -> void:
    var start_cell := _nearest_road_cell_to_world(vehicle.position)
    var destination_access := _access_road_cell(vehicle.destination_building_cell)
    if start_cell == INVALID_CELL or destination_access == INVALID_CELL:
        _fail_trip(vehicle)
        return

    var path_cells := graph.get_path_cells(start_cell, destination_access)
    if path_cells.is_empty():
        _fail_trip(vehicle)
        return

    var points: Array[Vector2] = []
    for cell in path_cells:
        points.append(cell_to_world(cell))
    vehicle.replace_path(points)

func _fail_trip(vehicle: VehicleAgent) -> void:
    pending_demand += 1
    vehicles.erase(vehicle)
    vehicle.completed = true
    vehicle.queue_free()

func _unhandled_input(event: InputEvent) -> void:
    if is_game_over:
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _begin_interaction(event.position)
        else:
            _end_interaction()
        return

    if event is InputEventMouseMotion and _dragging:
        _continue_interaction(event.position)
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            _begin_interaction(event.position)
        else:
            _end_interaction()
        return

    if event is InputEventScreenDrag and _dragging:
        _continue_interaction(event.position)

func _begin_interaction(position: Vector2) -> void:
    var cell := world_to_cell(position)
    if not _valid_cell(cell):
        return

    if interaction_mode == "signal":
        _toggle_signal(cell)
        return

    _dragging = true
    _last_drag_cell = cell
    _apply_cell_action(cell)

func _continue_interaction(position: Vector2) -> void:
    var cell := world_to_cell(position)
    if not _valid_cell(cell) or cell == _last_drag_cell:
        return
    _apply_manhattan_action(_last_drag_cell, cell)
    _last_drag_cell = cell

func _end_interaction() -> void:
    _dragging = false
    _last_drag_cell = INVALID_CELL

func _apply_manhattan_action(from_cell: Vector2i, to_cell: Vector2i) -> void:
    var cursor := from_cell
    _apply_cell_action(cursor)

    while cursor.x != to_cell.x:
        cursor.x += 1 if to_cell.x > cursor.x else -1
        _apply_cell_action(cursor)

    while cursor.y != to_cell.y:
        cursor.y += 1 if to_cell.y > cursor.y else -1
        _apply_cell_action(cursor)

func _apply_cell_action(cell: Vector2i) -> void:
    if interaction_mode == "road":
        _add_road_cell(cell)
    elif interaction_mode == "erase":
        _remove_road_cell(cell)

func _add_road_cell(cell: Vector2i, free: bool = false) -> void:
    if not _valid_cell(cell) or road_cells.has(cell) or _is_building_cell(cell):
        return
    if not free and road_budget <= 0:
        toast_requested.emit("No road segments available")
        return

    road_cells[cell] = true
    graph.add_cell(cell)
    if not free:
        road_budget -= 1
    queue_redraw()

func _remove_road_cell(cell: Vector2i) -> void:
    if not road_cells.has(cell):
        return
    road_cells.erase(cell)
    graph.remove_cell(cell)
    traffic_lights.erase(cell)
    road_budget += 1
    queue_redraw()

func _toggle_signal(cell: Vector2i) -> void:
    if not road_cells.has(cell) or graph.degree(cell) < 3:
        toast_requested.emit("Signals require a 3-way or 4-way junction")
        return
    if traffic_lights.has(cell):
        traffic_lights.erase(cell)
        toast_requested.emit("Traffic signal removed")
    else:
        traffic_lights[cell] = true
        toast_requested.emit("Traffic signal installed")
    queue_redraw()

func _vertical_signal_green(cell: Vector2i) -> bool:
    var phase_offset := float(abs(cell.x * 17 + cell.y * 31) % 20) * 0.08
    return fmod(sim_time + phase_offset, 6.0) < 3.0

func _create_starter_city() -> void:
    for x in range(4, 13):
        _add_road_cell(Vector2i(x, 7), true)
    for y in range(5, 10):
        _add_road_cell(Vector2i(8, y), true)

    _add_building(Vector2i(4, 6), "residential")
    _add_building(Vector2i(5, 8), "residential")
    _add_building(Vector2i(12, 6), "office")
    _add_building(Vector2i(11, 8), "shop")
    _add_building(Vector2i(9, 5), "hospital")

func _spawn_building() -> void:
    for attempt in range(40):
        var cell := Vector2i(
            rng.randi_range(MIN_CELL.x + 1, MAX_CELL.x - 1),
            rng.randi_range(MIN_CELL.y + 1, MAX_CELL.y - 1)
        )
        if road_cells.has(cell) or _is_building_cell(cell):
            continue
        if _has_building_within(cell, 1):
            continue

        var roll := rng.randf()
        var building_type := "residential"
        if roll > 0.88:
            building_type = "hospital"
        elif roll > 0.68:
            building_type = "shop"
        elif roll > 0.45:
            building_type = "office"
        _add_building(cell, building_type)
        toast_requested.emit("City growth: new %s zone" % building_type)
        return

func _add_building(cell: Vector2i, building_type: String) -> void:
    buildings.append(CityBuilding.new(cell, building_type, _building_color(building_type)))

func _building_color(building_type: String) -> Color:
    match building_type:
        "office":
            return OFFICE_COLOR
        "shop":
            return SHOP_COLOR
        "hospital":
            return HOSPITAL_COLOR
        _:
            return RESIDENTIAL_COLOR

func _generate_trip() -> void:
    if buildings.size() < 2:
        return
    if vehicles.size() >= 140:
        pending_demand += 1
        return

    var origin: CityBuilding = buildings[rng.randi_range(0, buildings.size() - 1)]
    var candidates: Array[CityBuilding] = []
    for building in buildings:
        if building == origin:
            continue
        if building.building_type != origin.building_type:
            candidates.append(building)

    if candidates.is_empty():
        return

    var destination: CityBuilding = candidates[rng.randi_range(0, candidates.size() - 1)]
    var start_access := _access_road_cell(origin.cell)
    var end_access := _access_road_cell(destination.cell)

    if start_access == INVALID_CELL or end_access == INVALID_CELL:
        pending_demand += 1
        return

    var path_cells := graph.get_path_cells(start_access, end_access)
    if path_cells.is_empty():
        pending_demand += 1
        return

    var points: Array[Vector2] = []
    for cell in path_cells:
        points.append(cell_to_world(cell))

    var vehicle := VehicleAgent.new()
    vehicle.setup(points, destination.cell, self, origin.color.darkened(0.28))
    add_child(vehicle)
    vehicles.append(vehicle)
    pending_demand = max(0, pending_demand - 1)

func _access_road_cell(building_cell: Vector2i) -> Vector2i:
    for candidate in [
        building_cell,
        building_cell + Vector2i.UP,
        building_cell + Vector2i.DOWN,
        building_cell + Vector2i.LEFT,
        building_cell + Vector2i.RIGHT
    ]:
        if road_cells.has(candidate):
            return candidate
    return INVALID_CELL

func _nearest_road_cell_to_world(world_position: Vector2) -> Vector2i:
    var best := INVALID_CELL
    var best_distance := INF
    for raw_cell in road_cells.keys():
        var cell: Vector2i = raw_cell
        var distance := cell_to_world(cell).distance_squared_to(world_position)
        if distance < best_distance:
            best_distance = distance
            best = cell
    return best

func _rebuild_occupancy() -> void:
    occupancy.clear()
    for vehicle in vehicles:
        if not is_instance_valid(vehicle) or vehicle.completed:
            continue
        var cell := world_to_cell(vehicle.position)
        occupancy[cell] = int(occupancy.get(cell, 0)) + 1

func _update_flow(sim_delta: float) -> void:
    var waiting_count := 0
    for vehicle in vehicles:
        if is_instance_valid(vehicle) and vehicle.waiting:
            waiting_count += 1

    var overloaded_cells := 0
    for raw_count in occupancy.values():
        var count := int(raw_count)
        if count >= 3:
            overloaded_cells += count - 2

    var penalty := pending_demand * 2.7 + waiting_count * 0.75 + overloaded_cells * 1.8
    flow_score = clamp(100.0 - penalty, 0.0, 100.0)

    if flow_score < 20.0:
        critical_time += sim_delta
    else:
        critical_time = max(0.0, critical_time - sim_delta * 0.7)

    if critical_time >= 45.0:
        is_game_over = true
        paused = true
        game_over.emit(get_snapshot())

func _estimate_population() -> int:
    var population := 0
    for building in buildings:
        match building.building_type:
            "residential":
                population += 180
            "office":
                population += 70
            "shop":
                population += 40
            "hospital":
                population += 90
    return population

func _valid_cell(cell: Vector2i) -> bool:
    return cell.x >= MIN_CELL.x and cell.x <= MAX_CELL.x and cell.y >= MIN_CELL.y and cell.y <= MAX_CELL.y

func _is_building_cell(cell: Vector2i) -> bool:
    for building in buildings:
        if building.cell == cell:
            return true
    return false

func _has_building_within(cell: Vector2i, radius: int) -> bool:
    for building in buildings:
        if abs(building.cell.x - cell.x) <= radius and abs(building.cell.y - cell.y) <= radius:
            return true
    return false

func _emit_hud() -> void:
    hud_updated.emit(get_snapshot())

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), BACKGROUND, true)

    for x in range(MIN_CELL.x, MAX_CELL.x + 1):
        for y in range(MIN_CELL.y, MAX_CELL.y + 1):
            draw_circle(cell_to_world(Vector2i(x, y)), 1.4, GRID_DOT)

    for raw_cell in road_cells.keys():
        var cell: Vector2i = raw_cell
        var point := cell_to_world(cell)
        draw_circle(point, 10.0, ROAD_COLOR)
        for direction in [Vector2i.RIGHT, Vector2i.DOWN]:
            var neighbor: Vector2i = cell + direction
            if road_cells.has(neighbor):
                var neighbor_point: Vector2 = cell_to_world(neighbor)
                draw_line(point, neighbor_point, ROAD_COLOR, 18.0, true)
                draw_line(point, neighbor_point, ROAD_MARKING, 1.3, true)

    for raw_cell in traffic_lights.keys():
        var cell: Vector2i = raw_cell
        var signal_color := Color("#4E9F6A") if _vertical_signal_green(cell) else Color("#D85D5D")
        draw_circle(cell_to_world(cell), 6.5, Color("#202A30"))
        draw_circle(cell_to_world(cell), 4.2, signal_color)

    for building in buildings:
        var center := cell_to_world(building.cell)
        var connected := _access_road_cell(building.cell) != INVALID_CELL
        var size := Vector2(27.0, 27.0)
        draw_rect(Rect2(center - size * 0.5, size), building.color, true)
        draw_rect(Rect2(center - Vector2(10.0, 9.0), Vector2(20.0, 4.0)), building.color.lightened(0.22), true)

        if building.building_type == "hospital":
            draw_rect(Rect2(center - Vector2(2.5, 9.0), Vector2(5.0, 18.0)), Color.WHITE, true)
            draw_rect(Rect2(center - Vector2(9.0, 2.5), Vector2(18.0, 5.0)), Color.WHITE, true)

        if not connected:
            draw_arc(center, 18.0, 0.0, TAU, 28, Color("#C94C4C"), 2.0, true)
