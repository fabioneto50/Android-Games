extends CitySimulation
class_name CitySimulationPT

func _ready() -> void:
    rng.randomize()
    emergency_manager = EmergencyManagerPT.new(self)
    _create_starter_city()
    queue_redraw()
    _emit_hud()

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

    var points: Array[Vector2] = [cell_to_world(origin.cell)]
    for cell: Vector2i in path_cells:
        points.append(cell_to_world(cell))
    points.append(cell_to_world(destination.cell))

    var vehicle := VehicleAgentPT.new()
    vehicle.setup(points, destination.cell, self, origin.color.darkened(0.28))
    add_child(vehicle)
    vehicles.append(vehicle)
    pending_demand = maxi(0, pending_demand - 1)
