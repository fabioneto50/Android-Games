extends GridFlowAccountGatePremium
class_name GridFlowAccountGateEconomy

func _capture_game_state() -> Dictionary:
    var data: Dictionary = super._capture_game_state()
    var economy := simulation as CitySimulationEconomy
    if economy == null:
        return data

    data["version"] = 4
    data["coins"] = economy.coins
    data["shop_level"] = economy.shop_level

    var building_data: Array = []
    for building: CityBuilding in economy.buildings:
        building_data.append({
            "x": building.cell.x,
            "y": building.cell.y,
            "type": building.building_type,
            "demand": building.demand,
            "group": building.mobility_group,
            "level": building.upgrade_level,
            "home_capacity": building.home_vehicle_capacity,
            "demand_capacity": building.demand_capacity
        })
    data["buildings"] = building_data
    return data

func _restore_game_state(data: Dictionary) -> void:
    super._restore_game_state(data)
    var economy := simulation as CitySimulationEconomy
    if economy == null:
        return

    economy.coins = int(data.get("coins", 30))
    economy.shop_level = clampi(int(data.get("shop_level", 1)), 1, 4)

    var building_data: Array = data.get("buildings", []) as Array
    for raw_building: Variant in building_data:
        if not raw_building is Dictionary:
            continue
        var item: Dictionary = raw_building
        var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
        var building := economy._building_at_cell(cell)
        if building == null:
            continue
        building.mobility_group = String(item.get("group", "red"))
        building.color = economy.get_group_colour(building.mobility_group)
        building.upgrade_level = clampi(int(item.get("level", 1)), 1, 5)
        building.demand = int(item.get("demand", 0))
        building.home_vehicle_capacity = int(item.get("home_capacity", building.home_vehicle_capacity + maxi(0, building.upgrade_level - 1)))
        building.demand_capacity = int(item.get("demand_capacity", building.demand_capacity + maxi(0, building.upgrade_level - 1) * 3))

    economy.home_active_vehicles.clear()
    economy.destination_inbound.clear()
    economy._recompute_pending_demand()
    economy._emit_hud()
    economy.queue_redraw()

func _reset_to_new_game() -> void:
    super._reset_to_new_game()
    var economy := simulation as CitySimulationEconomy
    if economy == null:
        return
    economy.coins = 30
    economy.shop_level = 1
    economy.road_budget = 80
    economy.signal_budget = 1
    economy.roundabout_budget = 0
    economy.lane_upgrade_budget = 0
    economy.bridge_budget = 0
    economy.home_active_vehicles.clear()
    economy.destination_inbound.clear()
    economy._growth_spawn_counter = 0
    if economy.emergency_manager != null:
        economy.emergency_manager.green_charges = 0
    economy._recompute_pending_demand()
    economy._emit_hud()

func _refresh_menu_summary() -> void:
    super._refresh_menu_summary()
    var economy := simulation as CitySimulationEconomy
    if economy == null or menu_stats == null:
        return
    var snapshot := economy.get_snapshot()
    menu_stats.text = "SEMANA %d   •   POPULAÇÃO %s\nPONTUAÇÃO %d   •   ◈ %d MOEDAS\nLOJA NÍVEL %d   •   PEDIDOS %d   •   CARROS EM CASA %d" % [
        int(snapshot.week),
        _compact_menu_number(int(snapshot.population)),
        int(snapshot.score),
        economy.coins,
        economy.shop_level,
        int(snapshot.get("requests", snapshot.pending)),
        int(snapshot.get("home_cars_available", 0))
    ]
