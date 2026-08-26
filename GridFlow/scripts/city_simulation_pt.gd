extends CitySimulation
class_name CitySimulationPT

# Cada casa residencial possui uma pequena frota própria.
# Os destinos acumulam pedidos até um carro chegar efetivamente ao edifício.
var home_active_vehicles: Dictionary = {}
var destination_inbound: Dictionary = {}

func _ready() -> void:
    rng.randomize()
    emergency_manager = EmergencyManagerPT.new(self)
    _create_starter_city()
    _recompute_pending_demand()
    queue_redraw()
    _emit_hud()

func get_snapshot() -> Dictionary:
    var snapshot: Dictionary = super.get_snapshot()
    snapshot["requests"] = get_total_destination_demand()
    snapshot["home_cars_available"] = get_total_available_home_cars()
    return snapshot

func get_cell_capacity(cell: Vector2i) -> int:
    var capacity: int = get_lane_count(cell) * 3
    if roundabouts.has(cell):
        capacity += 6
    return capacity

func get_speed_factor(cell: Vector2i, density: int) -> float:
    var capacity: int = maxi(2, get_cell_capacity(cell))
    var load: float = float(density) / float(capacity)
    var factor: float = clampf(1.08 - load * 0.72, 0.24, 1.08)
    if roundabouts.has(cell):
        factor = clampf(maxf(factor, 0.82) + 0.10, 0.82, 1.16)
    return factor

func can_vehicle_enter(vehicle: VehicleAgent, from_world: Vector2, to_world: Vector2) -> bool:
    var target_cell: Vector2i = world_to_cell(to_world)

    if emergency_manager != null and emergency_manager.allows_signal_bypass(vehicle, target_cell):
        return true

    if roundabouts.has(target_cell):
        var density: int = get_occupancy(target_cell)
        var capacity: int = get_cell_capacity(target_cell)
        return vehicle.is_emergency or density < capacity

    if not traffic_lights.has(target_cell):
        return true

    var from_cell: Vector2i = world_to_cell(from_world)
    var delta: Vector2i = target_cell - from_cell
    if delta == Vector2i.ZERO:
        return true

    var vertical_move: bool = abs(delta.y) >= abs(delta.x)
    var vertical_green: bool = _vertical_signal_green(target_cell)
    return vertical_green if vertical_move else not vertical_green

func reroute_vehicle(vehicle: VehicleAgent) -> void:
    var start_cell: Vector2i = _nearest_road_cell_to_world(vehicle.position)
    var destination_access: Vector2i = _access_road_cell(vehicle.destination_building_cell)
    if start_cell == INVALID_CELL or destination_access == INVALID_CELL:
        if vehicle.is_emergency:
            emergency_vehicle_timed_out(vehicle)
        else:
            _fail_trip(vehicle)
        return

    var path_cells: Array[Vector2i] = graph.get_path_cells(start_cell, destination_access)
    if path_cells.is_empty():
        if vehicle.is_emergency:
            emergency_vehicle_timed_out(vehicle)
        else:
            _fail_trip(vehicle)
        return

    var points: Array[Vector2] = [vehicle.position]
    for cell: Vector2i in path_cells:
        var point := cell_to_world(cell)
        if points[-1].distance_to(point) > 1.0:
            points.append(point)
    points.append(cell_to_world(vehicle.destination_building_cell))
    vehicle.replace_path(points)

func vehicle_completed(vehicle: VehicleAgent) -> void:
    var commuter := vehicle as VehicleAgentPT
    if commuter != null and not commuter.is_emergency and commuter.home_building_cell != VehicleAgentPT.NO_HOME:
        if commuter.returning_home:
            _vehicle_returned_home(commuter)
        else:
            _vehicle_reached_destination(commuter)
        return

    super.vehicle_completed(vehicle)

func _vehicle_reached_destination(vehicle: VehicleAgentPT) -> void:
    var destination := _building_at_cell(vehicle.destination_building_cell)
    _decrement_inbound(vehicle.destination_building_cell)

    if destination != null and destination.is_destination():
        destination.demand = maxi(0, destination.demand - 1)
        completed_trips += 1

    _recompute_pending_demand()

    var home := _building_at_cell(vehicle.home_building_cell)
    if home == null:
        _release_home_slot(vehicle.home_building_cell)
        vehicles.erase(vehicle)
        vehicle.queue_free()
        return

    var start_access: Vector2i = _access_road_cell(vehicle.destination_building_cell)
    var home_access: Vector2i = _access_road_cell(home.cell)
    if start_access == INVALID_CELL or home_access == INVALID_CELL:
        _release_home_slot(home.cell)
        vehicles.erase(vehicle)
        vehicle.queue_free()
        return

    var path_cells: Array[Vector2i] = graph.get_path_cells(start_access, home_access)
    if path_cells.is_empty():
        _release_home_slot(home.cell)
        vehicles.erase(vehicle)
        vehicle.queue_free()
        return

    var points: Array[Vector2] = [vehicle.position]
    for cell: Vector2i in path_cells:
        var point := cell_to_world(cell)
        if points[-1].distance_to(point) > 1.0:
            points.append(point)
    points.append(cell_to_world(home.cell))

    vehicle.begin_return_trip(points)
    _emit_hud()

func _vehicle_returned_home(vehicle: VehicleAgentPT) -> void:
    _release_home_slot(vehicle.home_building_cell)
    vehicles.erase(vehicle)
    vehicle.queue_free()
    _emit_hud()

func _fail_trip(vehicle: VehicleAgent) -> void:
    var commuter := vehicle as VehicleAgentPT
    if commuter != null and not commuter.is_emergency and commuter.home_building_cell != VehicleAgentPT.NO_HOME:
        if not commuter.returning_home:
            _decrement_inbound(commuter.destination_building_cell)
        _release_home_slot(commuter.home_building_cell)
        vehicles.erase(commuter)
        commuter.completed = true
        commuter.queue_free()
        _recompute_pending_demand()
        _emit_hud()
        return

    super._fail_trip(vehicle)

func apply_upgrade(upgrade_id: String) -> void:
    if not awaiting_upgrade:
        return

    match upgrade_id:
        "roads":
            road_budget += 30
            toast_requested.emit("Melhoria: +30 troços de estrada")
        "signals":
            signal_budget += 2
            toast_requested.emit("Melhoria: +2 semáforos")
        "roundabout":
            roundabout_budget += 1
            toast_requested.emit("Melhoria: +1 rotunda")
        "lanes":
            lane_upgrade_budget += 2
            toast_requested.emit("Melhoria: +2 alargamentos de estrada")
        "bridge":
            bridge_budget += 1
            toast_requested.emit("Melhoria: +1 ponte")
        "green":
            emergency_manager.green_charges += 1
            toast_requested.emit("Melhoria: +1 Corredor Verde")
        _:
            road_budget += 20
            toast_requested.emit("Melhoria: +20 troços de estrada")

    awaiting_upgrade = false
    paused = false
    _emit_hud()

func _build_upgrade_options() -> Array[Dictionary]:
    var pool: Array[Dictionary] = [
        {"id": "roads", "title": "ESTRADAS", "detail": "+30 troços de estrada"},
        {"id": "signals", "title": "SEMÁFOROS", "detail": "+2 semáforos"},
        {"id": "roundabout", "title": "ROTUNDA", "detail": "+1 rotunda"},
        {"id": "lanes", "title": "ALARGAR ESTRADAS", "detail": "+2 alargamentos"},
        {"id": "bridge", "title": "TRAVESSIA DO TEJO", "detail": "+1 ponte"},
        {"id": "green", "title": "CORREDOR VERDE", "detail": "+1 carga de prioridade"}
    ]
    pool.shuffle()
    return [pool[0], pool[1]]

func _add_road_cell(cell: Vector2i, free: bool = false, as_bridge: bool = false) -> void:
    if not _valid_cell(cell) or road_cells.has(cell) or _is_building_cell(cell):
        return
    if _is_water_cell(cell) and not as_bridge:
        toast_requested.emit("É necessária uma ponte para atravessar o Tejo")
        return
    if as_bridge and not _is_water_cell(cell):
        toast_requested.emit("As pontes só podem ser construídas sobre o Tejo")
        return
    if not free and road_budget <= 0:
        toast_requested.emit("Não tens troços de estrada disponíveis")
        return
    if as_bridge and bridge_budget <= 0:
        toast_requested.emit("Não tens pontes disponíveis")
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
        toast_requested.emit("Ponte removida e recurso devolvido")
        return
    _add_road_cell(cell, false, true)
    if bridge_cells.has(cell):
        toast_requested.emit("Travessia sobre o Tejo construída")

func _toggle_signal(cell: Vector2i) -> void:
    if not road_cells.has(cell) or graph.degree(cell) < 3:
        toast_requested.emit("O semáforo precisa de um cruzamento com 3 ou 4 acessos")
        return

    if traffic_lights.has(cell):
        traffic_lights.erase(cell)
        signal_budget += 1
        toast_requested.emit("Semáforo removido")
    else:
        if signal_budget <= 0:
            toast_requested.emit("Não tens semáforos disponíveis")
            return
        if roundabouts.has(cell):
            roundabouts.erase(cell)
            roundabout_budget += 1
        traffic_lights[cell] = true
        signal_budget -= 1
        toast_requested.emit("Semáforo instalado")
    queue_redraw()
    _emit_hud()

func _toggle_roundabout(cell: Vector2i) -> void:
    if not road_cells.has(cell) or graph.degree(cell) < 3:
        toast_requested.emit("A rotunda precisa de um cruzamento com 3 ou 4 acessos")
        return

    if roundabouts.has(cell):
        roundabouts.erase(cell)
        roundabout_budget += 1
        toast_requested.emit("Rotunda removida")
    else:
        if roundabout_budget <= 0:
            toast_requested.emit("Não tens rotundas disponíveis")
            return
        if traffic_lights.has(cell):
            traffic_lights.erase(cell)
            signal_budget += 1
        roundabouts[cell] = true
        roundabout_budget -= 1
        toast_requested.emit("Rotunda instalada — os veículos cedem à entrada e circulam sem semáforos")
    queue_redraw()
    _emit_hud()

func _upgrade_lane(cell: Vector2i) -> void:
    if not road_cells.has(cell):
        toast_requested.emit("Toca numa estrada para a alargar")
        return

    var lanes: int = get_lane_count(cell)
    if lanes >= 3:
        toast_requested.emit("Esta estrada já tem 3 vias")
        return
    if lane_upgrade_budget <= 0:
        toast_requested.emit("Não tens alargamentos disponíveis")
        return

    lanes += 1
    road_lanes[cell] = lanes
    lane_upgrade_budget -= 1
    toast_requested.emit("Estrada alargada para %d vias" % lanes)
    queue_redraw()
    _emit_hud()

func _cycle_one_way(cell: Vector2i) -> void:
    if not road_cells.has(cell):
        toast_requested.emit("Toca numa estrada para definir o sentido")
        return

    var options: Array[Vector2i] = [Vector2i.ZERO]
    for direction: Vector2i in DIRECTIONS:
        if road_cells.has(cell + direction):
            options.append(direction)

    if options.size() <= 1:
        toast_requested.emit("Esta estrada ainda não tem ligação a outra estrada")
        return

    var current: Vector2i = graph.get_one_way(cell)
    var current_index: int = options.find(current)
    var next_index: int = 0 if current_index < 0 else (current_index + 1) % options.size()
    var next_direction: Vector2i = options[next_index]
    graph.set_one_way(cell, next_direction)

    if next_direction == Vector2i.ZERO:
        toast_requested.emit("Estrada novamente com dois sentidos")
    else:
        toast_requested.emit("Sentido único atualizado")
    queue_redraw()

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
        toast_requested.emit("A cidade cresceu: %s" % _building_name_pt(building_type))
        return

func _building_name_pt(building_type: String) -> String:
    match building_type:
        "office":
            return "novos escritórios"
        "shop":
            return "nova zona comercial"
        "hospital":
            return "novo hospital"
        _:
            return "nova zona residencial"

# Cada pulso de procura cria um pedido num destino. Só depois tentamos despachar
# um dos carros que esteja efetivamente estacionado numa casa ligada à rede.
func _generate_trip() -> void:
    var destination := _select_destination_for_new_request()
    if destination == null:
        return

    var request_amount: int = 1
    if week >= 5 and rng.randf() < 0.24:
        request_amount += 1
    if week >= 10 and rng.randf() < 0.18:
        request_amount += 1

    destination.demand += request_amount
    _recompute_pending_demand()

    var dispatch_attempts: int = 2 if _is_rush_hour() else 1
    for _attempt: int in range(dispatch_attempts):
        if not _dispatch_best_available_trip():
            break

func _select_destination_for_new_request() -> CityBuilding:
    var total_weight: float = 0.0
    for building: CityBuilding in buildings:
        if building.is_destination():
            total_weight += _destination_demand_weight(building)

    if total_weight <= 0.0:
        return null

    var roll: float = rng.randf_range(0.0, total_weight)
    var cursor: float = 0.0
    for building: CityBuilding in buildings:
        if not building.is_destination():
            continue
        cursor += _destination_demand_weight(building)
        if roll <= cursor:
            return building

    return null

func _destination_demand_weight(building: CityBuilding) -> float:
    var hour: int = int(city_minutes / 60.0)
    match building.building_type:
        "office":
            if hour >= 7 and hour < 11:
                return 5.0
            if hour >= 14 and hour < 18:
                return 3.0
            return 1.4
        "shop":
            if hour >= 11 and hour < 21:
                return 4.0
            return 1.2
        "hospital":
            return 1.8
        _:
            return 1.0

func _dispatch_best_available_trip() -> bool:
    var attempted: Dictionary = {}
    var destination_count: int = 0
    for building: CityBuilding in buildings:
        if building.is_destination() and _outstanding_requests(building) > 0:
            destination_count += 1

    for _index: int in range(destination_count):
        var destination := _highest_unattempted_destination(attempted)
        if destination == null:
            return false
        attempted[destination.cell] = true
        if _dispatch_vehicle_to(destination):
            return true

    return false

func _highest_unattempted_destination(attempted: Dictionary) -> CityBuilding:
    var best: CityBuilding = null
    var best_score: float = -INF

    for building: CityBuilding in buildings:
        if not building.is_destination() or attempted.has(building.cell):
            continue
        var outstanding: int = _outstanding_requests(building)
        if outstanding <= 0:
            continue
        var score: float = float(outstanding) * 10.0 + building.pressure() * 4.0
        if score > best_score:
            best_score = score
            best = building

    return best

func _dispatch_vehicle_to(destination: CityBuilding) -> bool:
    if vehicles.size() >= 140:
        return false

    var destination_access: Vector2i = _access_road_cell(destination.cell)
    if destination_access == INVALID_CELL:
        return false

    var selected_home: CityBuilding = null
    var selected_path: Array[Vector2i] = []
    var selected_length: int = 999999

    for home: CityBuilding in buildings:
        if not home.is_home():
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
    var car_color: Color = selected_home.color.darkened(0.30)
    vehicle.setup_commute(points, destination.cell, self, car_color, selected_home.cell)
    add_child(vehicle)
    vehicles.append(vehicle)

    home_active_vehicles[selected_home.cell] = int(home_active_vehicles.get(selected_home.cell, 0)) + 1
    destination_inbound[destination.cell] = int(destination_inbound.get(destination.cell, 0)) + 1
    return true

func _outstanding_requests(destination: CityBuilding) -> int:
    return maxi(0, destination.demand - int(destination_inbound.get(destination.cell, 0)))

func _decrement_inbound(cell: Vector2i) -> void:
    var current: int = int(destination_inbound.get(cell, 0))
    if current <= 1:
        destination_inbound.erase(cell)
    else:
        destination_inbound[cell] = current - 1

func _release_home_slot(cell: Vector2i) -> void:
    var current: int = int(home_active_vehicles.get(cell, 0))
    if current <= 1:
        home_active_vehicles.erase(cell)
    else:
        home_active_vehicles[cell] = current - 1

func get_home_available_cars(home: CityBuilding) -> int:
    if home == null or not home.is_home():
        return 0
    var active: int = int(home_active_vehicles.get(home.cell, 0))
    return maxi(0, home.home_vehicle_capacity - active)

func get_total_available_home_cars() -> int:
    var total: int = 0
    for building: CityBuilding in buildings:
        if building.is_home():
            total += get_home_available_cars(building)
    return total

func get_total_destination_demand() -> int:
    var total: int = 0
    for building: CityBuilding in buildings:
        if building.is_destination():
            total += building.demand
    return total

func _recompute_pending_demand() -> void:
    pending_demand = get_total_destination_demand()

func _building_at_cell(cell: Vector2i) -> CityBuilding:
    for building: CityBuilding in buildings:
        if building.cell == cell:
            return building
    return null
