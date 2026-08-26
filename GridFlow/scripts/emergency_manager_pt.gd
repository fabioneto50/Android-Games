extends EmergencyManager
class_name EmergencyManagerPT

func activate_green_corridor() -> void:
    _clean_active_list()

    if green_charges <= 0:
        simulation.toast_requested.emit("Não tens cargas de Corredor Verde disponíveis")
        return

    if active.is_empty():
        simulation.toast_requested.emit("Não existe nenhuma ambulância a necessitar de prioridade")
        return

    var ambulance: VehicleAgent = active[0]
    green_cells.clear()

    for index: int in range(ambulance.path_index, ambulance.path_points.size()):
        var world_point: Vector2 = ambulance.path_points[index]
        var cell: Vector2i = simulation.world_to_cell(world_point)
        if simulation.is_road_cell(cell):
            green_cells[cell] = true

    if green_cells.is_empty():
        simulation.toast_requested.emit("Não foi possível criar o Corredor Verde")
        return

    green_charges -= 1
    green_timer = 12.0
    simulation.toast_requested.emit("CORREDOR VERDE ATIVO — a ambulância tem prioridade nos semáforos")
    simulation.queue_redraw()
    simulation._emit_hud()

func on_vehicle_completed(vehicle: VehicleAgent) -> void:
    if not vehicle.is_emergency:
        return
    active.erase(vehicle)
    completed_count += 1
    simulation.toast_requested.emit("Emergência concluída  +500")
    simulation._emit_hud()

func on_vehicle_failed(vehicle: VehicleAgent) -> void:
    if not vehicle.is_emergency:
        return
    active.erase(vehicle)
    failed_count += 1
    simulation.toast_requested.emit("Falha na resposta à emergência")
    simulation._emit_hud()

func _spawn_emergency() -> void:
    var hospitals: Array[CityBuilding] = []
    var origins: Array[CityBuilding] = []

    for building: CityBuilding in simulation.buildings:
        if building.building_type == "hospital":
            hospitals.append(building)
        else:
            origins.append(building)

    if hospitals.is_empty() or origins.is_empty():
        return

    origins.shuffle()
    hospitals.shuffle()

    for origin: CityBuilding in origins:
        var start_access: Vector2i = simulation._access_road_cell(origin.cell)
        if start_access == simulation.INVALID_CELL:
            continue

        for hospital: CityBuilding in hospitals:
            var end_access: Vector2i = simulation._access_road_cell(hospital.cell)
            if end_access == simulation.INVALID_CELL:
                continue

            var path_cells: Array[Vector2i] = simulation.graph.get_path_cells(start_access, end_access)
            if path_cells.is_empty():
                continue

            var points: Array[Vector2] = [simulation.cell_to_world(origin.cell)]
            for cell: Vector2i in path_cells:
                points.append(simulation.cell_to_world(cell))
            points.append(simulation.cell_to_world(hospital.cell))

            var ambulance := VehicleAgentPT.new()
            ambulance.setup(points, hospital.cell, simulation, AMBULANCE_COLOR, true, 35.0)
            simulation.add_child(ambulance)
            simulation.vehicles.append(ambulance)
            active.append(ambulance)
            simulation.toast_requested.emit("CHAMADA DE AMBULÂNCIA — chega ao hospital em menos de 35 segundos")
            simulation._emit_hud()
            return

    failed_count += 1
    simulation.pending_demand += 2
    simulation.toast_requested.emit("Emergência sem percurso disponível até ao hospital")
    simulation._emit_hud()
