extends CitySimulationPT
class_name CitySimulationEconomy

signal building_selected(cell: Vector2i)

const GROUP_COLOURS := {
    "red": Color("#D96A64"),
    "blue": Color("#5F8FD3"),
    "yellow": Color("#D9B75F"),
    "green": Color("#68AD7B")
}

var coins: int = 30
var shop_level: int = 1
var _growth_spawn_counter: int = 0

func _ready() -> void:
    super._ready()
    road_budget = 80
    signal_budget = 1
    roundabout_budget = 0
    lane_upgrade_budget = 0
    bridge_budget = 0
    if emergency_manager != null:
        emergency_manager.green_charges = 0
    _recompute_pending_demand()
    _emit_hud()

func get_snapshot() -> Dictionary:
    var snapshot: Dictionary = super.get_snapshot()
    snapshot["coins"] = coins
    snapshot["shop_level"] = shop_level
    snapshot["shop_upgrade_cost"] = get_shop_upgrade_cost()
    return snapshot

# O início é deliberadamente mais calmo. A pressão cresce de forma progressiva.
func _current_demand_interval() -> float:
    var hour: int = int(city_minutes / 60.0)
    if (hour >= 7 and hour < 10) or (hour >= 16 and hour < 20):
        return 1.75 if week < 6 else 1.50
    if hour >= 22 or hour < 6:
        return 4.2
    return 2.75 if week < 6 else 2.35

# Em vez de uma melhoria aleatória, cada semana dá um pequeno rendimento e a
# progressão passa a ser controlada exclusivamente pelo jogador na loja.
func _begin_weekly_upgrade() -> void:
    week += 1
    coins += 6
    awaiting_upgrade = false
    paused = false
    toast_requested.emit("Semana %d  •  +6 moedas de planeamento" % week)
    _emit_hud()

# Crescimento a metade da velocidade do protótipo anterior.
func _spawn_building() -> void:
    _growth_spawn_counter += 1
    if _growth_spawn_counter % 2 != 0:
        return

    for _attempt: int in range(50):
        var max_y: int = MAX_CELL.y - 1
        if bridge_budget <= 0 and bridge_cells.is_empty() and shop_level < 3:
            max_y = RIVER_ROW - 1

        var cell := Vector2i(
            rng.randi_range(MIN_CELL.x + 1, MAX_CELL.x - 1),
            rng.randi_range(MIN_CELL.y + 1, max_y)
        )
        if _is_water_cell(cell) or road_cells.has(cell) or _is_building_cell(cell):
            continue
        if _has_building_within(cell, 1):
            continue

        var roll: float = rng.randf()
        var building_type := "residential"
        if roll >= 0.95:
            building_type = "hospital"
        elif roll >= 0.80:
            building_type = "shop"
        elif roll >= 0.56:
            building_type = "office"

        _add_building(cell, building_type)
        toast_requested.emit("A cidade cresceu: %s" % _building_name_pt(building_type))
        return

func _add_building(cell: Vector2i, building_type: String) -> void:
    var group: String = _choose_group_for_building(building_type)
    var building := CityBuilding.new(cell, building_type, get_group_colour(group), group)
    buildings.append(building)

func get_group_colour(group: String) -> Color:
    return GROUP_COLOURS.get(group, GROUP_COLOURS["red"]) as Color

func _available_groups() -> Array[String]:
    if week < 5:
        return ["red"]
    if week < 9:
        return ["red", "blue"]
    if week < 13:
        return ["red", "blue", "yellow"]
    return ["red", "blue", "yellow", "green"]

func _choose_group_for_building(building_type: String) -> String:
    var allowed := _available_groups()
    if buildings.is_empty():
        return "red"

    if building_type != "residential":
        var home_groups: Array[String] = []
        for group: String in allowed:
            for building: CityBuilding in buildings:
                if building.is_home() and building.mobility_group == group:
                    home_groups.append(group)
                    break
        if not home_groups.is_empty():
            allowed = home_groups

    var best_group: String = allowed[0]
    var best_count: int = 999999
    for group: String in allowed:
        var count: int = 0
        for building: CityBuilding in buildings:
            if building.mobility_group != group:
                continue
            if building_type == "residential" and building.is_home():
                count += 1
            elif building_type != "residential" and building.is_destination():
                count += 1
        if count < best_count:
            best_count = count
            best_group = group
    return best_group

func _generate_trip() -> void:
    var destination := _select_destination_for_new_request()
    if destination == null:
        return

    var request_amount := 1
    if week >= 10 and rng.randf() < 0.14:
        request_amount = 2
    destination.demand = mini(destination.demand + request_amount, destination.demand_capacity + 2)
    _recompute_pending_demand()

    var dispatch_attempts := 3 if _is_rush_hour() else 2
    for _attempt: int in range(dispatch_attempts):
        if not _dispatch_best_available_trip():
            break

# Um carro só serve destinos com a mesma cor/grupo da sua casa de origem.
func _dispatch_vehicle_to(destination: CityBuilding) -> bool:
    if vehicles.size() >= 140:
        return false

    var destination_access: Vector2i = _access_road_cell(destination.cell)
    if destination_access == INVALID_CELL:
        return false

    var selected_home: CityBuilding = null
    var selected_path: Array[Vector2i] = []
    var selected_length := 999999

    for home: CityBuilding in buildings:
        if not home.is_home():
            continue
        if not home.group_matches(destination):
            continue
        if get_home_available_cars(home) <= 0:
            continue

        var home_access: Vector2i = _access_road_cell(home.cell)
        if home_access == INVALID_CELL:
            continue

        var path_cells: Array[Vector2i] = graph.get_path_cells(home_access, destination_access)
        if path_cells.is_empty():
            continue
        if path_cells.size() < selected_length:
            selected_length = path_cells.size()
            selected_home = home
            selected_path = path_cells

    if selected_home == null or selected_path.is_empty():
        return false

    var points: Array[Vector2] = [cell_to_world(selected_home.cell)]
    for cell: Vector2i in selected_path:
        points.append(cell_to_world(cell))
    points.append(cell_to_world(destination.cell))

    var vehicle := VehicleAgentPT.new()
    vehicle.setup_commute(points, destination.cell, self, selected_home.color.darkened(0.22), selected_home.cell)
    vehicle.base_speed *= 1.0 + 0.05 * float(selected_home.upgrade_level - 1)
    add_child(vehicle)
    vehicles.append(vehicle)

    home_active_vehicles[selected_home.cell] = int(home_active_vehicles.get(selected_home.cell, 0)) + 1
    destination_inbound[destination.cell] = int(destination_inbound.get(destination.cell, 0)) + 1
    return true

func _vehicle_reached_destination(vehicle: VehicleAgentPT) -> void:
    var destination := _building_at_cell(vehicle.destination_building_cell)
    var reward := 3
    if destination != null:
        reward += maxi(0, destination.upgrade_level - 1)
    super._vehicle_reached_destination(vehicle)
    coins += reward
    _emit_hud()

# Flow mais tolerante: o jogador tem tempo para reagir, comprar e melhorar.
func _update_flow(sim_delta: float) -> void:
    var waiting_count := 0
    for vehicle: VehicleAgent in vehicles:
        if is_instance_valid(vehicle) and vehicle.waiting:
            waiting_count += 1

    var overloaded_cells := 0
    for raw_cell: Variant in occupancy.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var count: int = int(occupancy[cell])
        var capacity: int = get_cell_capacity(cell)
        if count > capacity:
            overloaded_cells += count - capacity

    var emergency_penalty := 0.0
    if emergency_manager != null:
        emergency_penalty = float(emergency_manager.failed_count) * 0.8

    var penalty := float(pending_demand) * 1.35 + float(waiting_count) * 0.42 + float(overloaded_cells) * 1.15 + emergency_penalty
    flow_score = clampf(100.0 - penalty, 0.0, 100.0)

    if flow_score < 15.0:
        critical_time += sim_delta
    else:
        critical_time = maxf(0.0, critical_time - sim_delta * 1.1)

    if critical_time >= 90.0:
        is_game_over = true
        paused = true
        game_over.emit(get_snapshot())

func _begin_interaction(world_position: Vector2) -> void:
    var cell := world_to_cell(world_position)
    var building := _building_at_cell(cell)
    if building != null:
        building_selected.emit(cell)
        return
    super._begin_interaction(world_position)

func get_building_upgrade_cost(building: CityBuilding) -> int:
    if building == null:
        return 0
    if building.is_home():
        return 20 + (building.upgrade_level - 1) * 16
    return 24 + (building.upgrade_level - 1) * 18

func upgrade_building(cell: Vector2i) -> bool:
    var building := _building_at_cell(cell)
    if building == null:
        return false
    if building.upgrade_level >= 5:
        toast_requested.emit("Este edifício já atingiu o nível máximo")
        return false
    var cost := get_building_upgrade_cost(building)
    if coins < cost:
        toast_requested.emit("Moedas insuficientes para esta melhoria")
        return false
    coins -= cost
    building.apply_upgrade()
    _recompute_pending_demand()
    toast_requested.emit("Edifício melhorado para nível %d" % building.upgrade_level)
    _emit_hud()
    queue_redraw()
    return true

func get_shop_upgrade_cost() -> int:
    match shop_level:
        1:
            return 45
        2:
            return 85
        3:
            return 135
        _:
            return 0

func upgrade_shop() -> bool:
    if shop_level >= 4:
        return false
    var cost := get_shop_upgrade_cost()
    if coins < cost:
        toast_requested.emit("Moedas insuficientes para evoluir a loja")
        return false
    coins -= cost
    shop_level += 1
    toast_requested.emit("Loja evoluída para nível %d" % shop_level)
    _emit_hud()
    return true

func get_shop_catalog() -> Array[Dictionary]:
    return [
        {"id":"roads", "title":"20 ESTRADAS", "detail":"+20 troços", "cost":12, "level":1},
        {"id":"signals", "title":"SEMÁFORO", "detail":"+1 unidade", "cost":18, "level":1},
        {"id":"roundabout", "title":"ROTUNDA", "detail":"+1 unidade", "cost":28, "level":2},
        {"id":"lanes", "title":"ALARGAMENTO", "detail":"+1 melhoria", "cost":24, "level":2},
        {"id":"bridge", "title":"PONTE", "detail":"+1 travessia", "cost":36, "level":3},
        {"id":"green", "title":"CORREDOR VERDE", "detail":"+1 carga", "cost":30, "level":3}
    ]

func buy_shop_item(item_id: String) -> bool:
    var item: Dictionary = {}
    for candidate: Dictionary in get_shop_catalog():
        if String(candidate.id) == item_id:
            item = candidate
            break
    if item.is_empty():
        return false
    if shop_level < int(item.level):
        toast_requested.emit("Evolui a loja para desbloquear este item")
        return false

    var cost := int(item.cost)
    if shop_level >= 4:
        cost = int(ceil(float(cost) * 0.85))
    if coins < cost:
        toast_requested.emit("Moedas insuficientes")
        return false

    coins -= cost
    match item_id:
        "roads":
            road_budget += 20
        "signals":
            signal_budget += 1
        "roundabout":
            roundabout_budget += 1
        "lanes":
            lane_upgrade_budget += 1
        "bridge":
            bridge_budget += 1
        "green":
            if emergency_manager != null:
                emergency_manager.green_charges += 1
    toast_requested.emit("Compra concluída: %s" % String(item.title))
    _emit_hud()
    return true
