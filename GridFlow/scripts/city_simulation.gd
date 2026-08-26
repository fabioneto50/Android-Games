extends Node2D
class_name CitySimulation

signal hud_updated(snapshot: Dictionary)
signal toast_requested(message: String)
signal game_over(snapshot: Dictionary)
signal upgrade_requested(options: Array[Dictionary])

const GRID_SIZE := 48.0
const GRID_ORIGIN := Vector2(24.0, 24.0)
const WORLD_SIZE := Vector2(1280.0, 720.0)
const MIN_CELL := Vector2i(0, 2)
const MAX_CELL := Vector2i(26, 14)
const INVALID_CELL := Vector2i(-999, -999)
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const RIVER_ROW := 11

const BACKGROUND := Color("#F4F0E6")
const GRID_DOT := Color("#DED9CE")
const ROAD_COLOR := Color("#36454F")
const ROAD_MARKING := Color("#BBC4C7")
const RESIDENTIAL_COLOR := Color("#E88D67")
const OFFICE_COLOR := Color("#6C91C2")
const SHOP_COLOR := Color("#E9C46A")
const HOSPITAL_COLOR := Color("#D85D5D")
const ONEWAY_COLOR := Color("#F4C95D")
const ROUNDABOUT_COLOR := Color("#82A7A6")
const WATER_COLOR := Color("#86B8C9")
const BRIDGE_COLOR := Color("#B7A47D")

var graph := RoadGraph.new()
var road_cells: Dictionary = {}
var road_lanes: Dictionary = {}
var traffic_lights: Dictionary = {}
var roundabouts: Dictionary = {}
var bridge_cells: Dictionary = {}
var buildings: Array[CityBuilding] = []
var vehicles: Array[VehicleAgent] = []
var occupancy: Dictionary = {}
var rng := RandomNumberGenerator.new()

var interaction_mode: String = "road"
var paused: bool = false
var time_scale: float = 1.0
var is_game_over: bool = false
var awaiting_upgrade: bool = false

var road_budget: int = 120
var signal_budget: int = 2
var roundabout_budget: int = 1
var lane_upgrade_budget: int = 2
var bridge_budget: int = 1
var week: int = 1
var completed_trips: int = 0
var pending_demand: int = 0
var flow_score: float = 100.0
var critical_time: float = 0.0
var sim_time: float = 0.0
var city_minutes: float = 420.0

var view_zoom: float = 1.0
var _dragging: bool = false
var _panning: bool = false
var _last_drag_cell: Vector2i = INVALID_CELL
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
    if paused or is_game_over or awaiting_upgrade:
        return

    var sim_delta: float = delta * time_scale
    sim_time += sim_delta
    city_minutes = fmod(city_minutes + sim_delta * 3.0, 1440.0)
    _growth_timer += sim_delta
    _demand_timer += sim_delta
    _week_timer += sim_delta
    _hud_timer += delta

    _rebuild_occupancy()

    if _growth_timer >= 9.0:
        _growth_timer = 0.0
        _spawn_building()

    if _demand_timer >= _current_demand_interval():
        _demand_timer = 0.0
        _generate_trip()

    if _week_timer >= 60.0:
        _week_timer = 0.0
        _begin_weekly_upgrade()

    _update_flow(sim_delta)

    if _hud_timer >= 0.15:
        _hud_timer = 0.0
        _emit_hud()

    queue_redraw()

func set_mode(mode: String) -> void:
    interaction_mode = mode
    _dragging = false
    _panning = false
    _last_drag_cell = INVALID_CELL
    _emit_hud()

func set_paused(value: bool) -> void:
    if awaiting_upgrade:
        return
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

func zoom_by(factor: float, screen_center: Vector2 = Vector2(640.0, 360.0)) -> void:
    var old_zoom: float = view_zoom
    var new_zoom: float = clampf(old_zoom * factor, 0.65, 1.85)
    if is_equal_approx(old_zoom, new_zoom):
        return

    var world_anchor: Vector2 = (screen_center - position) / old_zoom
    view_zoom = new_zoom
    scale = Vector2.ONE * view_zoom
    position = screen_center - world_anchor * view_zoom
    queue_redraw()

func reset_view() -> void:
    view_zoom = 1.0
    scale = Vector2.ONE
    position = Vector2.ZERO

func get_snapshot() -> Dictionary:
    return {
        "flow": int(round(flow_score)),
        "week": week,
        "time": _format_city_time(),
        "rush": _is_rush_hour(),
        "roads": road_budget,
        "signals": signal_budget,
        "roundabouts": roundabout_budget,
        "lane_upgrades": lane_upgrade_budget,
        "bridges": bridge_budget,
        "trips": completed_trips,
        "pending": pending_demand,
        "vehicles": vehicles.size(),
        "population": _estimate_population(),
        "speed": int(time_scale),
        "paused": paused,
        "mode": interaction_mode,
        "zoom": view_zoom,
        "upgrade_pending": awaiting_upgrade,
        "score": completed_trips * 10 + (week - 1) * 100
    }

func world_to_cell(world_position: Vector2) -> Vector2i:
    return Vector2i(
        int(round((world_position.x - GRID_ORIGIN.x) / GRID_SIZE)),
        int(round((world_position.y - GRID_ORIGIN.y) / GRID_SIZE))
    )

func cell_to_world(cell: Vector2i) -> Vector2:
    return GRID_ORIGIN + Vector2(cell.x * GRID_SIZE, cell.y * GRID_SIZE)

func screen_to_world(screen_position: Vector2) -> Vector2:
    return (screen_position - position) / view_zoom

func is_road_cell(cell: Vector2i) -> bool:
    return road_cells.has(cell)

func get_occupancy(cell: Vector2i) -> int:
    return int(occupancy.get(cell, 0))

func get_lane_count(cell: Vector2i) -> int:
    return int(road_lanes.get(cell, 1))

func get_cell_capacity(cell: Vector2i) -> int:
    var capacity: int = get_lane_count(cell) * 3
    if roundabouts.has(cell):
        capacity += 2
    return capacity

func get_speed_factor(cell: Vector2i, density: int) -> float:
    var capacity: int = maxi(2, get_cell_capacity(cell))
    var load: float = float(density) / float(capacity)
    var factor: float = clampf(1.08 - load * 0.72, 0.24, 1.08)
    if roundabouts.has(cell):
        factor = minf(1.12, factor + 0.08)
    return factor

func can_vehicle_enter(from_world: Vector2, to_world: Vector2) -> bool:
    var target_cell: Vector2i = world_to_cell(to_world)
    if not traffic_lights.has(target_cell):
        return true

    var from_cell: Vector2i = world_to_cell(from_world)
    var delta: Vector2i = target_cell - from_cell
    if delta == Vector2i.ZERO:
        return true

    var vertical_move: bool = abs(delta.y) >= abs(delta.x)
    var vertical_green: bool = _vertical_signal_green(target_cell)
    return vertical_green if vertical_move else not vertical_green

func vehicle_completed(vehicle: VehicleAgent) -> void:
    completed_trips += 1
    pending_demand = maxi(0, pending_demand - 1)
    vehicles.erase(vehicle)
    vehicle.queue_free()

func reroute_vehicle(vehicle: VehicleAgent) -> void:
    var start_cell: Vector2i = _nearest_road_cell_to_world(vehicle.position)
    var destination_access: Vector2i = _access_road_cell(vehicle.destination_building_cell)
    if start_cell == INVALID_CELL or destination_access == INVALID_CELL:
        _fail_trip(vehicle)
        return

    var path_cells: Array[Vector2i] = graph.get_path_cells(start_cell, destination_access)
    if path_cells.is_empty():
        _fail_trip(vehicle)
        return

    var points: Array[Vector2] = []
    for cell: Vector2i in path_cells:
        points.append(cell_to_world(cell))
    vehicle.replace_path(points)

func apply_upgrade(upgrade_id: String) -> void:
    if not awaiting_upgrade:
        return

    match upgrade_id:
        "roads":
            road_budget += 30
            toast_requested.emit("Upgrade: +30 road segments")
        "signals":
            signal_budget += 2
            toast_requested.emit("Upgrade: +2 traffic signals")
        "roundabout":
            roundabout_budget += 1
            toast_requested.emit("Upgrade: +1 roundabout")
        "lanes":
            lane_upgrade_budget += 2
            toast_requested.emit("Upgrade: +2 lane upgrades")
        "bridge":
            bridge_budget += 1
            toast_requested.emit("Upgrade: +1 bridge")
        _:
            road_budget += 20
            toast_requested.emit("Upgrade: +20 road segments")

    awaiting_upgrade = false
    paused = false
    _emit_hud()

func _begin_weekly_upgrade() -> void:
    week += 1
    awaiting_upgrade = true
    paused = true
    var options: Array[Dictionary] = _build_upgrade_options()
    upgrade_requested.emit(options)
    _emit_hud()

func _build_upgrade_options() -> Array[Dictionary]:
    var pool: Array[Dictionary] = [
        {"id": "roads", "title": "ROAD SUPPLY", "detail": "+30 road segments"},
        {"id": "signals", "title": "SMART SIGNALS", "detail": "+2 traffic signals"},
        {"id": "roundabout", "title": "ROUNDABOUT", "detail": "+1 roundabout"},
        {"id": "lanes", "title": "ROAD WIDENING", "detail": "+2 lane upgrades"},
        {"id": "bridge", "title": "RIVER CROSSING", "detail": "+1 bridge over the Tagus"}
    ]
    pool.shuffle()
    return [pool[0], pool[1]]

func _current_demand_interval() -> float:
    var hour: int = int(city_minutes / 60.0)
    if (hour >= 7 and hour < 10) or (hour >= 16 and hour < 20):
        return 0.95
    if hour >= 22 or hour < 6:
        return 2.5
    return 1.65

func _is_rush_hour() -> bool:
    var hour: int = int(city_minutes / 60.0)
    return (hour >= 7 and hour < 10) or (hour >= 16 and hour < 20)

func _format_city_time() -> String:
    var total_minutes: int = int(city_minutes) % 1440
    var hours: int = total_minutes / 60
    var minutes: int = total_minutes % 60
    return "%02d:%02d" % [hours, minutes]

func _fail_trip(vehicle: VehicleAgent) -> void:
    pending_demand += 1
    vehicles.erase(vehicle)
    vehicle.completed = true
    vehicle.queue_free()

func _unhandled_input(event: InputEvent) -> void:
    if is_game_over or awaiting_upgrade:
        return

    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_by(1.12, event.position)
            return
        if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_by(0.89, event.position)
            return
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                _begin_screen_interaction(event.position)
            else:
                _end_interaction()
            return

    if event is InputEventMouseMotion:
        if _panning:
            _pan_by(event.relative)
        elif _dragging:
            _continue_interaction(screen_to_world(event.position))
        return

    if event is InputEventScreenTouch:
        if event.pressed:
            _begin_screen_interaction(event.position)
        else:
            _end_interaction()
        return

    if event is InputEventScreenDrag:
        if _panning:
            _pan_by(event.relative)
        elif _dragging:
            _continue_interaction(screen_to_world(event.position))
        return

    if event is InputEventMagnifyGesture:
        zoom_by(event.factor, event.position)

func _begin_screen_interaction(screen_position: Vector2) -> void:
    if interaction_mode == "pan":
        _panning = true
        return
    _begin_interaction(screen_to_world(screen_position))

func _pan_by(screen_delta: Vector2) -> void:
    position += screen_delta

func _begin_interaction(world_position: Vector2) -> void:
    var cell: Vector2i = world_to_cell(world_position)
    if not _valid_cell(cell):
        return

    match interaction_mode:
        "signal":
            _toggle_signal(cell)
            return
        "roundabout":
            _toggle_roundabout(cell)
            return
        "lanes":
            _upgrade_lane(cell)
            return
        "oneway":
            _cycle_one_way(cell)
            return
        "bridge":
            _place_bridge(cell)
            return

    _dragging = true
    _last_drag_cell = cell
    _apply_cell_action(cell)

func _continue_interaction(world_position: Vector2) -> void:
    var cell: Vector2i = world_to_cell(world_position)
    if not _valid_cell(cell) or cell == _last_drag_cell:
        return
    _apply_manhattan_action(_last_drag_cell, cell)
    _last_drag_cell = cell

func _end_interaction() -> void:
    _dragging = false
    _panning = false
    _last_drag_cell = INVALID_CELL

func _apply_manhattan_action(from_cell: Vector2i, to_cell: Vector2i) -> void:
    var cursor: Vector2i = from_cell
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

func _add_road_cell(cell: Vector2i, free: bool = false, as_bridge: bool = false) -> void:
    if not _valid_cell(cell) or road_cells.has(cell) or _is_building_cell(cell):
        return
    if _is_water_cell(cell) and not as_bridge:
        toast_requested.emit("The Tagus requires a bridge")
        return
    if as_bridge and not _is_water_cell(cell):
        toast_requested.emit("Bridge segments can only cross the Tagus")
        return
    if not free and road_budget <= 0:
        toast_requested.emit("No road segments available")
        return
    if as_bridge and bridge_budget <= 0:
        toast_requested.emit("No bridges available")
        return

    road_cells[cell] = true
    road_lanes[cell] = 1
    graph.add_cell(cell)
    if not free:
        road_budget -= 1
    if as_bridge:
        bridge_cells[cell] = true
        bridge_budget -= 1
    queue_redraw()
    _emit_hud()

func _place_bridge(cell: Vector2i) -> void:
    if bridge_cells.has(cell):
        _remove_road_cell(cell)
        toast_requested.emit("Bridge removed and refunded")
        return
    _add_road_cell(cell, false, true)
    if bridge_cells.has(cell):
        toast_requested.emit("Bridge crossing created")

func _remove_road_cell(cell: Vector2i) -> void:
    if not road_cells.has(cell):
        return

    var lanes: int = get_lane_count(cell)
    var was_bridge: bool = bridge_cells.has(cell)
    road_cells.erase(cell)
    road_lanes.erase(cell)
    graph.remove_cell(cell)
    road_budget += 1
    lane_upgrade_budget += maxi(0, lanes - 1)

    if was_bridge:
        bridge_cells.erase(cell)
        bridge_budget += 1
    if traffic_lights.has(cell):
        traffic_lights.erase(cell)
        signal_budget += 1
    if roundabouts.has(cell):
        roundabouts.erase(cell)
        roundabout_budget += 1

    queue_redraw()
    _emit_hud()

func _toggle_signal(cell: Vector2i) -> void:
    if not road_cells.has(cell) or graph.degree(cell) < 3:
        toast_requested.emit("Signals require a 3-way or 4-way junction")
        return

    if traffic_lights.has(cell):
        traffic_lights.erase(cell)
        signal_budget += 1
        toast_requested.emit("Traffic signal removed")
    else:
        if signal_budget <= 0:
            toast_requested.emit("No traffic signals available")
            return
        if roundabouts.has(cell):
            roundabouts.erase(cell)
            roundabout_budget += 1
        traffic_lights[cell] = true
        signal_budget -= 1
        toast_requested.emit("Traffic signal installed")
    queue_redraw()
    _emit_hud()

func _toggle_roundabout(cell: Vector2i) -> void:
    if not road_cells.has(cell) or graph.degree(cell) < 3:
        toast_requested.emit("Roundabouts require a 3-way or 4-way junction")
        return

    if roundabouts.has(cell):
        roundabouts.erase(cell)
        roundabout_budget += 1
        toast_requested.emit("Roundabout removed")
    else:
        if roundabout_budget <= 0:
            toast_requested.emit("No roundabouts available")
            return
        if traffic_lights.has(cell):
            traffic_lights.erase(cell)
            signal_budget += 1
        roundabouts[cell] = true
        roundabout_budget -= 1
        toast_requested.emit("Roundabout installed")
    queue_redraw()
    _emit_hud()

func _upgrade_lane(cell: Vector2i) -> void:
    if not road_cells.has(cell):
        toast_requested.emit("Tap a road to widen it")
        return

    var lanes: int = get_lane_count(cell)
    if lanes >= 3:
        toast_requested.emit("Road already has 3 lanes")
        return
    if lane_upgrade_budget <= 0:
        toast_requested.emit("No lane upgrades available")
        return

    lanes += 1
    road_lanes[cell] = lanes
    lane_upgrade_budget -= 1
    toast_requested.emit("Road widened to %d lanes" % lanes)
    queue_redraw()
    _emit_hud()

func _cycle_one_way(cell: Vector2i) -> void:
    if not road_cells.has(cell):
        toast_requested.emit("Tap a road to set direction")
        return

    var options: Array[Vector2i] = [Vector2i.ZERO]
    for direction: Vector2i in DIRECTIONS:
        if road_cells.has(cell + direction):
            options.append(direction)

    if options.size() <= 1:
        toast_requested.emit("This road has no connected direction")
        return

    var current: Vector2i = graph.get_one_way(cell)
    var current_index: int = options.find(current)
    var next_index: int = 0 if current_index < 0 else (current_index + 1) % options.size()
    var next_direction: Vector2i = options[next_index]
    graph.set_one_way(cell, next_direction)

    if next_direction == Vector2i.ZERO:
        toast_requested.emit("Road restored to two-way")
    else:
        toast_requested.emit("One-way direction updated")
    queue_redraw()

func _vertical_signal_green(cell: Vector2i) -> bool:
    var phase_offset: float = float(abs(cell.x * 17 + cell.y * 31) % 20) * 0.08
    return fmod(sim_time + phase_offset, 6.0) < 3.0

func _create_starter_city() -> void:
    for x: int in range(4, 13):
        _add_road_cell(Vector2i(x, 7), true)
    for y: int in range(5, 10):
        _add_road_cell(Vector2i(8, y), true)

    _add_building(Vector2i(4, 6), "residential")
    _add_building(Vector2i(5, 8), "residential")
    _add_building(Vector2i(12, 6), "office")
    _add_building(Vector2i(11, 8), "shop")
    _add_building(Vector2i(9, 5), "hospital")

func _spawn_building() -> void:
    for _attempt: int in range(40):
        var cell := Vector2i(
            rng.randi_range(MIN_CELL.x + 1, MAX_CELL.x - 1),
            rng.randi_range(MIN_CELL.y + 1, MAX_CELL.y - 1)
        )
        if _is_water_cell(cell) or road_cells.has(cell) or _is_building_cell(cell):
            continue
        if _has_building_within(cell, 1):
            continue

        var roll: float = rng.randf()
        var building_type: String = "residential"
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
    for building: CityBuilding in buildings:
        if building == origin:
            continue
        if building.building_type != origin.building_type:
            candidates.append(building)

    if candidates.is_empty():
        return

    var destination: CityBuilding = candidates[rng.randi_range(0, candidates.size() - 1)]
    var start_access: Vector2i = _access_road_cell(origin.cell)
    var end_access: Vector2i = _access_road_cell(destination.cell)

    if start_access == INVALID_CELL or end_access == INVALID_CELL:
        pending_demand += 1
        return

    var path_cells: Array[Vector2i] = graph.get_path_cells(start_access, end_access)
    if path_cells.is_empty():
        pending_demand += 1
        return

    var points: Array[Vector2] = []
    for cell: Vector2i in path_cells:
        points.append(cell_to_world(cell))

    var vehicle := VehicleAgent.new()
    vehicle.setup(points, destination.cell, self, origin.color.darkened(0.28))
    add_child(vehicle)
    vehicles.append(vehicle)
    pending_demand = maxi(0, pending_demand - 1)

func _access_road_cell(building_cell: Vector2i) -> Vector2i:
    var candidates: Array[Vector2i] = [
        building_cell,
        building_cell + Vector2i.UP,
        building_cell + Vector2i.DOWN,
        building_cell + Vector2i.LEFT,
        building_cell + Vector2i.RIGHT
    ]
    for candidate: Vector2i in candidates:
        if road_cells.has(candidate):
            return candidate
    return INVALID_CELL

func _nearest_road_cell_to_world(world_position: Vector2) -> Vector2i:
    var best: Vector2i = INVALID_CELL
    var best_distance: float = INF
    for raw_cell: Variant in road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var distance: float = cell_to_world(cell).distance_squared_to(world_position)
        if distance < best_distance:
            best_distance = distance
            best = cell
    return best

func _rebuild_occupancy() -> void:
    occupancy.clear()
    for vehicle: VehicleAgent in vehicles:
        if not is_instance_valid(vehicle) or vehicle.completed:
            continue
        var cell: Vector2i = world_to_cell(vehicle.position)
        occupancy[cell] = int(occupancy.get(cell, 0)) + 1

func _update_flow(sim_delta: float) -> void:
    var waiting_count: int = 0
    for vehicle: VehicleAgent in vehicles:
        if is_instance_valid(vehicle) and vehicle.waiting:
            waiting_count += 1

    var overloaded_cells: int = 0
    for raw_cell: Variant in occupancy.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var count: int = int(occupancy[cell])
        var capacity: int = get_cell_capacity(cell)
        if count > capacity:
            overloaded_cells += count - capacity

    var penalty: float = float(pending_demand) * 2.7 + float(waiting_count) * 0.75 + float(overloaded_cells) * 1.8
    flow_score = clampf(100.0 - penalty, 0.0, 100.0)

    if flow_score < 20.0:
        critical_time += sim_delta
    else:
        critical_time = maxf(0.0, critical_time - sim_delta * 0.7)

    if critical_time >= 45.0:
        is_game_over = true
        paused = true
        game_over.emit(get_snapshot())

func _estimate_population() -> int:
    var population: int = 0
    for building: CityBuilding in buildings:
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

func _is_water_cell(cell: Vector2i) -> bool:
    return cell.y == RIVER_ROW

func _is_building_cell(cell: Vector2i) -> bool:
    for building: CityBuilding in buildings:
        if building.cell == cell:
            return true
    return false

func _has_building_within(cell: Vector2i, radius: int) -> bool:
    for building: CityBuilding in buildings:
        if abs(building.cell.x - cell.x) <= radius and abs(building.cell.y - cell.y) <= radius:
            return true
    return false

func _emit_hud() -> void:
    hud_updated.emit(get_snapshot())

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), BACKGROUND, true)

    var river_y: float = cell_to_world(Vector2i(0, RIVER_ROW)).y
    draw_rect(Rect2(Vector2(0.0, river_y - GRID_SIZE * 0.46), Vector2(WORLD_SIZE.x, GRID_SIZE * 0.92)), WATER_COLOR, true)
    draw_line(Vector2(0.0, river_y - GRID_SIZE * 0.34), Vector2(WORLD_SIZE.x, river_y - GRID_SIZE * 0.34), WATER_COLOR.lightened(0.12), 2.0, true)

    for x: int in range(MIN_CELL.x, MAX_CELL.x + 1):
        for y: int in range(MIN_CELL.y, MAX_CELL.y + 1):
            if y == RIVER_ROW:
                continue
            draw_circle(cell_to_world(Vector2i(x, y)), 1.4, GRID_DOT)

    for raw_cell: Variant in road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var point: Vector2 = cell_to_world(cell)
        var cell_lanes: int = get_lane_count(cell)
        var node_width: float = 10.0 + float(cell_lanes - 1) * 3.5
        draw_circle(point, node_width, ROAD_COLOR)

        var draw_directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
        for direction: Vector2i in draw_directions:
            var neighbor: Vector2i = cell + direction
            if not road_cells.has(neighbor):
                continue
            var neighbor_point: Vector2 = cell_to_world(neighbor)
            var lanes: int = cell_lanes
            var neighbor_lanes: int = get_lane_count(neighbor)
            if neighbor_lanes > lanes:
                lanes = neighbor_lanes
            var road_width: float = 18.0 + float(lanes - 1) * 7.0
            var segment_color: Color = BRIDGE_COLOR if bridge_cells.has(cell) or bridge_cells.has(neighbor) else ROAD_COLOR
            draw_line(point, neighbor_point, segment_color, road_width, true)
            draw_line(point, neighbor_point, ROAD_MARKING, 1.3, true)

    for raw_cell: Variant in bridge_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = cell_to_world(cell)
        draw_line(center + Vector2(-13.0, -16.0), center + Vector2(-13.0, 16.0), Color("#ECE6D4"), 2.0, true)
        draw_line(center + Vector2(13.0, -16.0), center + Vector2(13.0, 16.0), Color("#ECE6D4"), 2.0, true)

    for raw_cell: Variant in roundabouts.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = cell_to_world(cell)
        draw_circle(center, 15.0, ROAD_COLOR)
        draw_circle(center, 8.0, BACKGROUND)
        draw_arc(center, 11.0, 0.0, TAU, 30, ROUNDABOUT_COLOR, 3.0, true)

    for raw_cell: Variant in traffic_lights.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var signal_color: Color = Color("#4E9F6A") if _vertical_signal_green(cell) else Color("#D85D5D")
        draw_circle(cell_to_world(cell), 6.5, Color("#202A30"))
        draw_circle(cell_to_world(cell), 4.2, signal_color)

    for raw_cell: Variant in road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var one_way: Vector2i = graph.get_one_way(cell)
        if one_way == Vector2i.ZERO:
            continue
        var center: Vector2 = cell_to_world(cell)
        var direction_vector: Vector2 = Vector2(float(one_way.x), float(one_way.y))
        var normal: Vector2 = Vector2(-direction_vector.y, direction_vector.x)
        var tip: Vector2 = center + direction_vector * 10.0
        var tail: Vector2 = center - direction_vector * 6.0
        draw_line(tail, tip, ONEWAY_COLOR, 2.5, true)
        draw_line(tip, tip - direction_vector * 5.0 + normal * 4.0, ONEWAY_COLOR, 2.5, true)
        draw_line(tip, tip - direction_vector * 5.0 - normal * 4.0, ONEWAY_COLOR, 2.5, true)

    for building: CityBuilding in buildings:
        var center: Vector2 = cell_to_world(building.cell)
        var connected: bool = _access_road_cell(building.cell) != INVALID_CELL
        var building_size: Vector2 = Vector2(27.0, 27.0)
        draw_rect(Rect2(center - building_size * 0.5, building_size), building.color, true)
        draw_rect(Rect2(center - Vector2(10.0, 9.0), Vector2(20.0, 4.0)), building.color.lightened(0.22), true)

        if building.building_type == "hospital":
            draw_rect(Rect2(center - Vector2(2.5, 9.0), Vector2(5.0, 18.0)), Color.WHITE, true)
            draw_rect(Rect2(center - Vector2(9.0, 2.5), Vector2(18.0, 5.0)), Color.WHITE, true)

        if not connected:
            draw_arc(center, 18.0, 0.0, TAU, 28, Color("#C94C4C"), 2.0, true)
