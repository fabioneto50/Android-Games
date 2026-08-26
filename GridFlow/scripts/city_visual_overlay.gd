extends Node2D
class_name CityVisualOverlay

var simulation: CitySimulation

const MAP_BG := Color("#E7E7DF")
const MAP_BLOCK_A := Color("#EBECE5")
const MAP_BLOCK_B := Color("#E2E4DC")
const GRID_DOT := Color(0.47, 0.52, 0.51, 0.22)
const ROAD_SURFACE := Color("#334248")
const ROAD_EDGE := Color("#202D31")
const LANE_MARK := Color(0.82, 0.85, 0.82, 0.62)
const SIDEWALK := Color("#CFD0C8")
const SHADOW := Color(0.08, 0.12, 0.13, 0.18)
const WATER := Color("#78AFC0")
const WATER_DEEP := Color("#669FAF")
const WATER_LINE := Color(0.88, 0.96, 0.97, 0.40)
const FLOW_OK := Color("#68C894")
const FLOW_WARN := Color("#E5BA61")
const FLOW_BAD := Color("#E36C65")
const ONEWAY := Color("#F0C36A")
const ROUNDABOUT := Color("#78B09C")
const BRIDGE_RAIL := Color("#E5DDC8")

func _init(p_simulation: CitySimulation) -> void:
    simulation = p_simulation
    z_index = 5

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    if simulation == null:
        return
    _draw_landscape()
    _draw_water_detail()
    _draw_roads()
    _draw_green_corridor()
    _draw_bridge_details()
    _draw_junction_controls()
    _draw_one_way_arrows()
    _draw_buildings()

func _draw_landscape() -> void:
    draw_rect(Rect2(Vector2.ZERO, simulation.WORLD_SIZE), MAP_BG, true)

    # Subtle planning parcels give the city more texture without visual noise.
    for x: int in range(simulation.MIN_CELL.x, simulation.MAX_CELL.x + 1):
        for y: int in range(simulation.MIN_CELL.y, simulation.MAX_CELL.y + 1):
            if y == simulation.RIVER_ROW:
                continue
            var center: Vector2 = simulation.cell_to_world(Vector2i(x, y))
            if (x + y) % 5 == 0:
                draw_rect(Rect2(center - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), MAP_BLOCK_A, true)
            elif (x * 3 + y) % 11 == 0:
                draw_rect(Rect2(center - Vector2(22.0, 22.0), Vector2(44.0, 44.0)), MAP_BLOCK_B, true)
            draw_circle(center, 1.25, GRID_DOT)

    var river_y: float = simulation.cell_to_world(Vector2i(0, simulation.RIVER_ROW)).y
    draw_rect(Rect2(Vector2(0.0, river_y - simulation.GRID_SIZE * 0.48), Vector2(simulation.WORLD_SIZE.x, simulation.GRID_SIZE * 0.96)), WATER_DEEP, true)
    draw_rect(Rect2(Vector2(0.0, river_y - simulation.GRID_SIZE * 0.40), Vector2(simulation.WORLD_SIZE.x, simulation.GRID_SIZE * 0.80)), WATER, true)
    draw_line(Vector2(0.0, river_y - simulation.GRID_SIZE * 0.46), Vector2(simulation.WORLD_SIZE.x, river_y - simulation.GRID_SIZE * 0.46), Color(0.35, 0.52, 0.55, 0.20), 2.0, true)
    draw_line(Vector2(0.0, river_y + simulation.GRID_SIZE * 0.46), Vector2(simulation.WORLD_SIZE.x, river_y + simulation.GRID_SIZE * 0.46), Color(0.35, 0.52, 0.55, 0.20), 2.0, true)

func _draw_water_detail() -> void:
    var river_y: float = simulation.cell_to_world(Vector2i(0, simulation.RIVER_ROW)).y
    for index: int in range(7):
        var y_offset: float = -15.0 + float(index) * 5.0
        var phase: float = fmod(simulation.sim_time * 8.0 + float(index) * 17.0, 52.0)
        var x: float = -phase
        while x < simulation.WORLD_SIZE.x:
            draw_line(Vector2(x, river_y + y_offset), Vector2(x + 17.0, river_y + y_offset), WATER_LINE, 1.05, true)
            x += 52.0

func _draw_roads() -> void:
    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var point: Vector2 = simulation.cell_to_world(cell)
        var draw_directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN]
        for direction: Vector2i in draw_directions:
            var neighbor: Vector2i = cell + direction
            if not simulation.road_cells.has(neighbor):
                continue

            var neighbor_point: Vector2 = simulation.cell_to_world(neighbor)
            var lanes: int = maxi(simulation.get_lane_count(cell), simulation.get_lane_count(neighbor))
            var road_width: float = 18.0 + float(lanes - 1) * 7.0
            var bridge_segment: bool = simulation.bridge_cells.has(cell) or simulation.bridge_cells.has(neighbor)
            var surface: Color = Color("#716C62") if bridge_segment else ROAD_SURFACE
            var edge_color: Color = Color("#554F47") if bridge_segment else ROAD_EDGE

            draw_line(point + Vector2(1.5, 2.6), neighbor_point + Vector2(1.5, 2.6), SHADOW, road_width + 8.0, true)
            draw_line(point, neighbor_point, Color("#BEB8AA") if bridge_segment else SIDEWALK, road_width + 6.0, true)
            draw_line(point, neighbor_point, edge_color, road_width + 2.5, true)
            draw_line(point, neighbor_point, surface, road_width, true)

            _draw_lane_marks(point, neighbor_point, lanes, road_width)
            _draw_load_indicator(cell, neighbor, point, neighbor_point, road_width)

    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = simulation.cell_to_world(cell)
        var lanes: int = simulation.get_lane_count(cell)
        var radius: float = 9.0 + float(lanes - 1) * 3.5
        var bridge_node: bool = simulation.bridge_cells.has(cell)
        draw_circle(center + Vector2(1.2, 2.0), radius + 2.0, SHADOW)
        draw_circle(center, radius + 2.0, Color("#554F47") if bridge_node else ROAD_EDGE)
        draw_circle(center, radius, Color("#716C62") if bridge_node else ROAD_SURFACE)

func _draw_lane_marks(from: Vector2, to: Vector2, lanes: int, road_width: float) -> void:
    var direction: Vector2 = (to - from).normalized()
    if direction.length_squared() <= 0.0:
        return
    var normal := Vector2(-direction.y, direction.x)

    _draw_dashed_segment(from, to, LANE_MARK, 1.15, 7.0, 6.0)

    if lanes >= 2:
        var offset: float = road_width * 0.25
        var secondary_mark := LANE_MARK
        secondary_mark.a = 0.34
        _draw_dashed_segment(from + normal * offset, to + normal * offset, secondary_mark, 0.8, 5.0, 7.0)
        _draw_dashed_segment(from - normal * offset, to - normal * offset, secondary_mark, 0.8, 5.0, 7.0)

func _draw_dashed_segment(from: Vector2, to: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
    var distance: float = from.distance_to(to)
    if distance <= 0.0:
        return
    var direction: Vector2 = (to - from) / distance
    var cursor: float = 4.0
    while cursor < distance - 3.0:
        var end_cursor: float = minf(cursor + dash, distance - 3.0)
        draw_line(from + direction * cursor, from + direction * end_cursor, color, width, true)
        cursor += dash + gap

func _draw_load_indicator(cell: Vector2i, neighbor: Vector2i, from: Vector2, to: Vector2, road_width: float) -> void:
    var load_a: float = float(simulation.get_occupancy(cell)) / float(maxi(1, simulation.get_cell_capacity(cell)))
    var load_b: float = float(simulation.get_occupancy(neighbor)) / float(maxi(1, simulation.get_cell_capacity(neighbor)))
    var load: float = maxf(load_a, load_b)
    if load < 0.34:
        return

    var color := FLOW_OK
    if load >= 0.95:
        color = FLOW_BAD
    elif load >= 0.65:
        color = FLOW_WARN
    color.a = 0.88

    var direction: Vector2 = (to - from).normalized()
    var normal := Vector2(-direction.y, direction.x)
    var offset: float = road_width * 0.5 - 2.4
    draw_line(from + normal * offset, to + normal * offset, color, 2.7, true)

func _draw_green_corridor() -> void:
    if simulation.emergency_manager == null or simulation.emergency_manager.green_timer <= 0.0:
        return
    for raw_cell: Variant in simulation.emergency_manager.green_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = simulation.cell_to_world(cell)
        draw_arc(center, 15.5, 0.0, TAU, 28, Color(0.31, 0.78, 0.55, 0.75), 3.0, true)
        draw_arc(center, 19.0, 0.0, TAU, 28, Color(0.31, 0.78, 0.55, 0.15), 2.0, true)

func _draw_bridge_details() -> void:
    for raw_cell: Variant in simulation.bridge_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = simulation.cell_to_world(cell)
        draw_line(center + Vector2(-14.0, -17.0), center + Vector2(-14.0, 17.0), BRIDGE_RAIL, 2.2, true)
        draw_line(center + Vector2(14.0, -17.0), center + Vector2(14.0, 17.0), BRIDGE_RAIL, 2.2, true)
        draw_circle(center + Vector2(-14.0, -17.0), 1.8, BRIDGE_RAIL)
        draw_circle(center + Vector2(14.0, -17.0), 1.8, BRIDGE_RAIL)

func _draw_junction_controls() -> void:
    for raw_cell: Variant in simulation.roundabouts.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = simulation.cell_to_world(cell)
        draw_circle(center, 16.0, ROAD_EDGE)
        draw_circle(center, 12.8, ROAD_SURFACE)
        draw_circle(center, 7.0, MAP_BG)
        draw_arc(center, 10.0, 0.0, TAU, 30, ROUNDABOUT, 2.5, true)
        draw_circle(center, 3.4, Color("#A6B995"))

    for raw_cell: Variant in simulation.traffic_lights.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = simulation.cell_to_world(cell)
        var vertical_green: bool = simulation._vertical_signal_green(cell)
        var active_color: Color = FLOW_OK if vertical_green else FLOW_BAD
        draw_circle(center + Vector2(1.0, 1.5), 7.4, Color(0.0, 0.0, 0.0, 0.18))
        draw_circle(center, 6.5, Color("#172126"))
        draw_circle(center, 3.8, active_color)
        draw_arc(center, 8.8, 0.0, TAU, 20, Color(active_color.r, active_color.g, active_color.b, 0.22), 1.4, true)

func _draw_one_way_arrows() -> void:
    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var one_way: Vector2i = simulation.graph.get_one_way(cell)
        if one_way == Vector2i.ZERO:
            continue
        var center: Vector2 = simulation.cell_to_world(cell)
        var direction_vector := Vector2(float(one_way.x), float(one_way.y))
        var normal := Vector2(-direction_vector.y, direction_vector.x)
        var tip: Vector2 = center + direction_vector * 10.0
        var tail: Vector2 = center - direction_vector * 6.0
        draw_line(tail, tip, ONEWAY, 2.4, true)
        draw_line(tip, tip - direction_vector * 5.0 + normal * 3.8, ONEWAY, 2.4, true)
        draw_line(tip, tip - direction_vector * 5.0 - normal * 3.8, ONEWAY, 2.4, true)

func _draw_buildings() -> void:
    for building: CityBuilding in simulation.buildings:
        var center: Vector2 = simulation.cell_to_world(building.cell)
        var connected: bool = simulation._access_road_cell(building.cell) != simulation.INVALID_CELL
        _draw_building_shadow(center)

        match building.building_type:
            "office":
                _draw_office(center, building.color)
            "shop":
                _draw_shop(center, building.color)
            "hospital":
                _draw_hospital(center, building.color)
            _:
                _draw_house(center, building.color)

        if not connected:
            draw_arc(center, 21.0, 0.0, TAU, 30, FLOW_BAD, 2.5, true)
            draw_circle(center + Vector2(15.0, -15.0), 5.0, FLOW_BAD)
            draw_line(center + Vector2(15.0, -18.0), center + Vector2(15.0, -14.0), Color.WHITE, 1.6, true)
            draw_circle(center + Vector2(15.0, -11.6), 0.9, Color.WHITE)

func _draw_building_shadow(center: Vector2) -> void:
    draw_rect(Rect2(center + Vector2(-11.0, -6.0), Vector2(28.0, 27.0)), Color(0.05, 0.08, 0.09, 0.20), true)

func _draw_house(center: Vector2, color: Color) -> void:
    draw_rect(Rect2(center + Vector2(-12.0, -7.0), Vector2(24.0, 20.0)), color, true)
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(-15.0, -7.0),
        center + Vector2(0.0, -18.0),
        center + Vector2(15.0, -7.0)
    ]), color.darkened(0.20))
    draw_rect(Rect2(center + Vector2(-3.2, 3.0), Vector2(6.4, 10.0)), color.darkened(0.30), true)
    draw_rect(Rect2(center + Vector2(-9.0, -3.0), Vector2(5.0, 5.0)), Color("#DCE8E5"), true)
    draw_rect(Rect2(center + Vector2(4.0, -3.0), Vector2(5.0, 5.0)), Color("#DCE8E5"), true)

func _draw_office(center: Vector2, color: Color) -> void:
    draw_rect(Rect2(center + Vector2(-13.0, -17.0), Vector2(26.0, 31.0)), color.darkened(0.10), true)
    draw_rect(Rect2(center + Vector2(-10.0, -14.0), Vector2(20.0, 26.0)), color, true)
    for x: int in range(3):
        for y: int in range(4):
            var window_center := center + Vector2(-6.0 + float(x) * 6.0, -9.0 + float(y) * 6.0)
            draw_rect(Rect2(window_center - Vector2(1.8, 1.6), Vector2(3.6, 3.2)), Color("#D9E8E8"), true)
    draw_rect(Rect2(center + Vector2(-3.0, 7.0), Vector2(6.0, 7.0)), color.darkened(0.28), true)

func _draw_shop(center: Vector2, color: Color) -> void:
    draw_rect(Rect2(center + Vector2(-14.0, -10.0), Vector2(28.0, 23.0)), color, true)
    draw_rect(Rect2(center + Vector2(-14.0, -12.0), Vector2(28.0, 6.0)), color.darkened(0.16), true)
    for x: int in range(5):
        var stripe_color: Color = Color("#F5EFE1") if x % 2 == 0 else color.darkened(0.12)
        draw_rect(Rect2(center + Vector2(-13.0 + float(x) * 5.2, -10.0), Vector2(5.2, 5.0)), stripe_color, true)
    draw_rect(Rect2(center + Vector2(-9.0, 0.0), Vector2(8.0, 8.0)), Color("#DCE8E5"), true)
    draw_rect(Rect2(center + Vector2(3.0, -1.0), Vector2(6.0, 14.0)), color.darkened(0.28), true)

func _draw_hospital(center: Vector2, color: Color) -> void:
    draw_rect(Rect2(center + Vector2(-15.0, -15.0), Vector2(30.0, 29.0)), Color("#F4F5F1"), true)
    draw_rect(Rect2(center + Vector2(-15.0, 8.0), Vector2(30.0, 6.0)), color, true)
    draw_rect(Rect2(center + Vector2(-2.5, -10.0), Vector2(5.0, 15.0)), color, true)
    draw_rect(Rect2(center + Vector2(-8.0, -5.0), Vector2(16.0, 5.0)), color, true)
    draw_rect(Rect2(center + Vector2(-4.0, 5.0), Vector2(8.0, 9.0)), Color("#B9D2D4"), true)
