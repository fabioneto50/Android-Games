extends RefCounted
class_name EmergencyManager

const AMBULANCE_COLOR := Color("#D94B4B")
const GREEN_CORRIDOR_COLOR := Color("#60C689")

var simulation: Node
var active: Array[VehicleAgent] = []
var completed_count: int = 0
var failed_count: int = 0
var green_charges: int = 1
var green_cells: Dictionary = {}
var green_timer: float = 0.0
var _spawn_timer: float = 0.0

func _init(p_simulation: Node) -> void:
    simulation = p_simulation

func tick(sim_delta: float) -> void:
    _clean_active_list()

    if green_timer > 0.0:
        green_timer = maxf(0.0, green_timer - sim_delta)
        if green_timer <= 0.0:
            green_cells.clear()
            simulation.queue_redraw()

    if simulation.week < 2:
        return

    _spawn_timer += sim_delta
    if _spawn_timer >= 24.0:
        _spawn_timer = 0.0
        _spawn_emergency()

func activate_green_corridor() -> void:
    _clean_active_list()
    if green_charges <= 0:
        simulation.toast_requested.emit("No Green Corridor charges available")
        return
    if active.is_empty():
        simulation.toast_requested.emit("No active ambulance requires priority")
        return

    var ambulance: VehicleAgent = active[0]
    green_cells.clear()
    for index: int in range(ambulance.path_index, ambulance.path_points.size()):
        var world_point: Vector2 = ambulance.path_points[index]
        var cell: Vector2i = simulation.world_to_cell(world_point)
        if simulation.is_road_cell(cell):
            green_cells[cell] = true

    if green_cells.is_empty():
        simulation.toast_requested.emit("Unable to create Green Corridor")
        return

    green_charges -= 1
    green_timer = 12.0
    simulation.toast_requested.emit("GREEN CORRIDOR ACTIVE — ambulance has signal priority")
    simulation.queue_redraw()
    simulation._emit_hud()

func allows_signal_bypass(vehicle: VehicleAgent, target_cell: Vector2i) -> bool:
    return vehicle.is_emergency and green_timer > 0.0 and green_cells.has(target_cell)

func on_vehicle_completed(vehicle: VehicleAgent) -> void:
    if not vehicle.is_emergency:
        return
    active.erase(vehicle)
    completed_count += 1
    simulation.toast_requested.emit("Emergency completed +500")
    simulation._emit_hud()

func on_vehicle_failed(vehicle: VehicleAgent) -> void:
    if not vehicle.is_emergency:
        return
    active.erase(vehicle)
    failed_count += 1
    simulation.toast_requested.emit("Emergency response failed")
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

            var points: Array[Vector2] = []
            for cell: Vector2i in path_cells:
                points.append(simulation.cell_to_world(cell))

            var ambulance := VehicleAgent.new()
            ambulance.setup(points, hospital.cell, simulation, AMBULANCE_COLOR, true, 35.0)
            simulation.add_child(ambulance)
            simulation.vehicles.append(ambulance)
            active.append(ambulance)
            simulation.toast_requested.emit("AMBULANCE CALL — reach hospital within 35 seconds")
            simulation._emit_hud()
            return

    failed_count += 1
    simulation.pending_demand += 2
    simulation.toast_requested.emit("Emergency generated but no hospital route is available")
    simulation._emit_hud()

func _clean_active_list() -> void:
    for index: int in range(active.size() - 1, -1, -1):
        var vehicle: VehicleAgent = active[index]
        if not is_instance_valid(vehicle) or vehicle.completed:
            active.remove_at(index)
