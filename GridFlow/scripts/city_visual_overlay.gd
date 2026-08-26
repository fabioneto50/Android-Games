extends Node2D
class_name CityVisualOverlay

var simulation: CitySimulation
var _building_birth: Dictionary = {}
var _intro_layer: CanvasLayer
var _intro_panel: PanelContainer
var _intro_visible: bool = true

const DAY_GROUND := Color("#E8E5D8")
const NIGHT_GROUND := Color("#263437")
const ROAD_SURFACE := Color("#334248")
const ROAD_EDGE := Color("#202D31")
const LANE_MARK := Color(0.82, 0.85, 0.82, 0.62)
const SIDEWALK := Color("#D6D3C8")
const SHADOW := Color(0.08, 0.12, 0.13, 0.18)
const WATER_DAY := Color("#75B6C5")
const WATER_NIGHT := Color("#315D69")
const WATER_LINE := Color(0.82, 0.94, 0.95, 0.34)
const FLOW_OK := Color("#68C894")
const FLOW_WARN := Color("#E5BA61")
const FLOW_BAD := Color("#E36C65")
const PARK_GRASS := Color("#AFC69C")
const TREE_TRUNK := Color("#79634C")
const TREE_LEAF := Color("#6F9D73")
const STREET_LIGHT := Color("#FFE7A1")
const GREEN_CORRIDOR := Color("#5FD39A")

func _init(p_simulation: CitySimulation) -> void:
    simulation = p_simulation
    z_index = 5

func _ready() -> void:
    _build_intro()
    simulation.set_paused(true)

func _process(_delta: float) -> void:
    for building: CityBuilding in simulation.buildings:
        if not _building_birth.has(building.cell):
            _building_birth[building.cell] = simulation.sim_time
    queue_redraw()

func _build_intro() -> void:
    _intro_layer = CanvasLayer.new()
    _intro_layer.layer = 90
    add_child(_intro_layer)

    var backdrop := ColorRect.new()
    backdrop.position = Vector2.ZERO
    backdrop.size = Vector2(1280.0, 720.0)
    backdrop.color = Color(0.035, 0.065, 0.072, 0.90)
    _intro_layer.add_child(backdrop)

    _intro_panel = PanelContainer.new()
    _intro_panel.position = Vector2(362.0, 142.0)
    _intro_panel.size = Vector2(556.0, 430.0)
    GridFlowUITheme.apply_panel(_intro_panel, Color("#122126"), 22)
    _intro_layer.add_child(_intro_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 38)
    margin.add_theme_constant_override("margin_right", 38)
    margin.add_theme_constant_override("margin_top", 34)
    margin.add_theme_constant_override("margin_bottom", 32)
    _intro_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 13)
    margin.add_child(column)

    var eyebrow := Label.new()
    eyebrow.text = "URBAN TRAFFIC STRATEGY"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 11)
    eyebrow.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    column.add_child(eyebrow)

    var title := Label.new()
    title.text = "GRIDFLOW"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 46)
    title.add_theme_color_override("font_color", Color("#F4F7F2"))
    column.add_child(title)

    var city := Label.new()
    city.text = "LISBON"
    city.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    city.add_theme_font_size_override("font_size", 16)
    city.add_theme_color_override("font_color", Color("#94AAA9"))
    column.add_child(city)

    var divider := HSeparator.new()
    divider.custom_minimum_size = Vector2(0.0, 14.0)
    column.add_child(divider)

    var description := Label.new()
    description.text = "Build a resilient road network as Lisbon grows around you.\nControl junctions, widen roads, cross the Tagus and clear emergency routes before the city locks up."
    description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.add_theme_font_size_override("font_size", 14)
    description.add_theme_color_override("font_color", Color("#C7D3D1"))
    description.custom_minimum_size = Vector2(0.0, 78.0)
    column.add_child(description)

    var features := Label.new()
    features.text = "DYNAMIC TRAFFIC   •   RUSH HOUR   •   EMERGENCIES   •   CITY GROWTH"
    features.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    features.add_theme_font_size_override("font_size", 10)
    features.add_theme_color_override("font_color", Color("#78908F"))
    column.add_child(features)

    var play := Button.new()
    play.text = "START LISBON"
    play.custom_minimum_size = Vector2(0.0, 58.0)
    play.add_theme_font_size_override("font_size", 15)
    GridFlowUITheme.apply_button(play, true)
    play.pressed.connect(_start_game)
    column.add_child(play)

    var hint := Label.new()
    hint.text = "Tip: keep alternative routes available before rush hour begins."
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 10)
    hint.add_theme_color_override("font_color", Color("#718483"))
    column.add_child(hint)

func _start_game() -> void:
    if not _intro_visible:
        return
    _intro_visible = false
    simulation.set_paused(false)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(_intro_layer, "offset:y", -34.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
    tween.tween_property(_intro_panel, "modulate:a", 0.0, 0.24)
    tween.chain().tween_callback(func(): _intro_layer.visible = false)

func _draw() -> void:
    if simulation == null:
        return
    _draw_environment()
    _draw_parks_and_trees()
    _draw_water_detail()
    _draw_roads()
    _draw_buildings()
    _draw_network_furniture()
    _draw_day_night_atmosphere()
    _draw_night_lights()

func _day_factor() -> float:
    var hour: float = simulation.city_minutes / 60.0
    if hour >= 7.0 and hour <= 18.0:
        return 1.0
    if hour >= 5.0 and hour < 7.0:
        return smoothstep(5.0, 7.0, hour)
    if hour > 18.0 and hour < 21.0:
        return 1.0 - smoothstep(18.0, 21.0, hour)
    return 0.0

func _draw_environment() -> void:
    var daylight := _day_factor()
    var ground := NIGHT_GROUND.lerp(DAY_GROUND, daylight)
    draw_rect(Rect2(Vector2.ZERO, simulation.WORLD_SIZE), ground, true)

    # Soft neighbourhood blocks create depth without a visible editor-like grid.
    for x: int in range(simulation.MIN_CELL.x, simulation.MAX_CELL.x + 1):
        for y: int in range(simulation.MIN_CELL.y, simulation.MAX_CELL.y + 1):
            var cell := Vector2i(x, y)
            if y == simulation.RIVER_ROW:
                continue
            if _cell_hash(cell) % 7 == 0:
                var center := simulation.cell_to_world(cell)
                draw_circle(center, 21.0, Color(0.96, 0.95, 0.90, 0.10 + daylight * 0.08))

    var river_y: float = simulation.cell_to_world(Vector2i(0, simulation.RIVER_ROW)).y
    var water := WATER_NIGHT.lerp(WATER_DAY, daylight)
    draw_rect(Rect2(Vector2(0.0, river_y - simulation.GRID_SIZE * 0.47), Vector2(simulation.WORLD_SIZE.x, simulation.GRID_SIZE * 0.94)), water, true)

func _draw_parks_and_trees() -> void:
    for x: int in range(simulation.MIN_CELL.x, simulation.MAX_CELL.x + 1):
        for y: int in range(simulation.MIN_CELL.y, simulation.MAX_CELL.y + 1):
            var cell := Vector2i(x, y)
            if y == simulation.RIVER_ROW or simulation.road_cells.has(cell) or simulation._is_building_cell(cell):
                continue
            var h := _cell_hash(cell)
            var center := simulation.cell_to_world(cell)
            if h % 31 == 0:
                draw_circle(center, 18.0, Color(PARK_GRASS, 0.52))
                draw_arc(center, 18.0, 0.0, TAU, 24, Color(0.35, 0.52, 0.37, 0.28), 1.0, true)
                _draw_tree(center + Vector2(-7.0, 2.0), 1.0)
                _draw_tree(center + Vector2(7.0, -4.0), 0.85)
                draw_line(center + Vector2(-13.0, 11.0), center + Vector2(13.0, -11.0), Color(0.88, 0.82, 0.68, 0.66), 2.0, true)
            elif h % 19 == 0:
                _draw_tree(center + Vector2(float((h % 9) - 4), float(((h / 7) % 9) - 4)), 0.78)

func _draw_tree(center: Vector2, tree_scale: float) -> void:
    draw_line(center + Vector2(0.0, 3.0) * tree_scale, center + Vector2(0.0, 10.0) * tree_scale, TREE_TRUNK, 2.3 * tree_scale, true)
    draw_circle(center + Vector2(0.0, -2.0) * tree_scale, 7.0 * tree_scale, Color(0.12, 0.18, 0.14, 0.16))
    draw_circle(center + Vector2(-1.5, -3.5) * tree_scale, 6.5 * tree_scale, TREE_LEAF)
    draw_circle(center + Vector2(3.0, -2.0) * tree_scale, 4.7 * tree_scale, TREE_LEAF.lightened(0.08))

func _draw_water_detail() -> void:
    var river_y: float = simulation.cell_to_world(Vector2i(0, simulation.RIVER_ROW)).y
    for index: int in range(7):
        var y_offset: float = -16.0 + float(index) * 5.0
        var phase: float = fmod(simulation.sim_time * 7.0 + float(index) * 15.0, 52.0)
        var x: float = -phase
        while x < simulation.WORLD_SIZE.x:
            draw_line(Vector2(x, river_y + y_offset), Vector2(x + 20.0, river_y + y_offset), WATER_LINE, 1.0, true)
            x += 52.0

    # Quays along both banks.
    draw_line(Vector2(0.0, river_y - 24.0), Vector2(simulation.WORLD_SIZE.x, river_y - 24.0), Color(0.82, 0.80, 0.72, 0.55), 3.0, true)
    draw_line(Vector2(0.0, river_y + 24.0), Vector2(simulation.WORLD_SIZE.x, river_y + 24.0), Color(0.82, 0.80, 0.72, 0.55), 3.0, true)

func _draw_roads() -> void:
    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var point: Vector2 = simulation.cell_to_world(cell)
        for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
            var neighbor: Vector2i = cell + direction
            if not simulation.road_cells.has(neighbor):
                continue

            var neighbor_point: Vector2 = simulation.cell_to_world(neighbor)
            var lanes: int = maxi(simulation.get_lane_count(cell), simulation.get_lane_count(neighbor))
            var road_width: float = 18.0 + float(lanes - 1) * 7.0
            var bridge_segment: bool = simulation.bridge_cells.has(cell) or simulation.bridge_cells.has(neighbor)
            var surface: Color = Color("#6E6B62") if bridge_segment else ROAD_SURFACE

            draw_line(point + Vector2(1.8, 2.8), neighbor_point + Vector2(1.8, 2.8), SHADOW, road_width + 9.0, true)
            draw_line(point, neighbor_point, Color("#B8B6AE") if not bridge_segment else Color("#B9AA89"), road_width + 6.0, true)
            draw_line(point, neighbor_point, ROAD_EDGE, road_width + 2.5, true)
            draw_line(point, neighbor_point, surface, road_width, true)
            _draw_lane_marks(point, neighbor_point, lanes, road_width)
            _draw_load_indicator(cell, neighbor, point, neighbor_point, road_width)

            if bridge_segment:
                _draw_bridge_rails(point, neighbor_point, road_width)

    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = simulation.cell_to_world(cell)
        var lanes: int = simulation.get_lane_count(cell)
        var radius: float = 9.0 + float(lanes - 1) * 3.5
        var bridge_node: bool = simulation.bridge_cells.has(cell)
        draw_circle(center + Vector2(1.2, 2.0), radius + 3.0, SHADOW)
        draw_circle(center, radius + 2.2, ROAD_EDGE)
        draw_circle(center, radius, Color("#6E6B62") if bridge_node else ROAD_SURFACE)

    _draw_roundabouts_signals_and_directions()

func _draw_bridge_rails(from: Vector2, to: Vector2, road_width: float) -> void:
    var direction := (to - from).normalized()
    if direction.length_squared() <= 0.0:
        return
    var normal := Vector2(-direction.y, direction.x)
    var edge := road_width * 0.5 + 3.0
    draw_line(from + normal * edge, to + normal * edge, Color("#E7DFC9"), 1.8, true)
    draw_line(from - normal * edge, to - normal * edge, Color("#E7DFC9"), 1.8, true)

func _draw_lane_marks(from: Vector2, to: Vector2, lanes: int, road_width: float) -> void:
    var direction: Vector2 = (to - from).normalized()
    if direction.length_squared() <= 0.0:
        return
    var normal := Vector2(-direction.y, direction.x)
    _draw_dashed_segment(from, to, LANE_MARK, 1.15, 7.0, 6.0)
    if lanes >= 2:
        var offset: float = road_width * 0.25
        _draw_dashed_segment(from + normal * offset, to + normal * offset, Color(LANE_MARK, 0.35), 0.8, 5.0, 7.0)
        _draw_dashed_segment(from - normal * offset, to - normal * offset, Color(LANE_MARK, 0.35), 0.8, 5.0, 7.0)

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
    var direction: Vector2 = (to - from).normalized()
    var normal := Vector2(-direction.y, direction.x)
    var offset: float = road_width * 0.5 - 2.3
    draw_line(from + normal * offset, to + normal * offset, Color(color, 0.88), 2.5, true)

func _draw_roundabouts_signals_and_directions() -> void:
    for raw_cell: Variant in simulation.roundabouts.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center := simulation.cell_to_world(cell)
        draw_circle(center, 16.0, ROAD_EDGE)
        draw_circle(center, 13.5, ROAD_SURFACE)
        draw_circle(center, 7.0, PARK_GRASS.darkened(0.12))
        draw_circle(center + Vector2(-1.0, -1.5), 3.2, TREE_LEAF)

    for raw_cell: Variant in simulation.traffic_lights.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center := simulation.cell_to_world(cell)
        var green: bool = simulation._vertical_signal_green(cell)
        draw_circle(center + Vector2(1.0, 1.5), 7.3, SHADOW)
        draw_circle(center, 6.6, Color("#172326"))
        draw_circle(center, 4.0, Color("#66C990") if green else Color("#E36C65"))

    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var one_way: Vector2i = simulation.graph.get_one_way(cell)
        if one_way == Vector2i.ZERO:
            continue
        var center := simulation.cell_to_world(cell)
        var direction_vector := Vector2(float(one_way.x), float(one_way.y))
        var normal := Vector2(-direction_vector.y, direction_vector.x)
        var tip := center + direction_vector * 10.0
        var tail := center - direction_vector * 6.0
        var arrow := Color("#F1C766")
        draw_line(tail, tip, arrow, 2.5, true)
        draw_line(tip, tip - direction_vector * 5.0 + normal * 4.0, arrow, 2.5, true)
        draw_line(tip, tip - direction_vector * 5.0 - normal * 4.0, arrow, 2.5, true)

    if simulation.emergency_manager != null and simulation.emergency_manager.green_timer > 0.0:
        var pulse: float = 1.0 + sin(simulation.sim_time * 5.0) * 0.12
        for raw_cell: Variant in simulation.emergency_manager.green_cells.keys():
            var cell: Vector2i = raw_cell as Vector2i
            draw_arc(simulation.cell_to_world(cell), 15.0 * pulse, 0.0, TAU, 24, Color(GREEN_CORRIDOR, 0.9), 3.0, true)

func _draw_buildings() -> void:
    for building: CityBuilding in simulation.buildings:
        var center: Vector2 = simulation.cell_to_world(building.cell)
        var connected: bool = simulation._access_road_cell(building.cell) != simulation.INVALID_CELL
        var age: float = simulation.sim_time - float(_building_birth.get(building.cell, simulation.sim_time))
        var pop_scale: float = clampf(age / 0.42, 0.18, 1.0)
        pop_scale = 1.0 - pow(1.0 - pop_scale, 3.0)

        draw_set_transform(center, 0.0, Vector2.ONE * pop_scale)
        _draw_building_shadow(Vector2.ZERO)
        match building.building_type:
            "office":
                _draw_office(Vector2.ZERO, building.color)
            "shop":
                _draw_shop(Vector2.ZERO, building.color)
            "hospital":
                _draw_hospital(Vector2.ZERO, building.color)
            _:
                _draw_house(Vector2.ZERO, building.color)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

        if not connected:
            draw_arc(center, 21.0, 0.0, TAU, 30, FLOW_BAD, 2.5, true)
            draw_circle(center + Vector2(15.0, -15.0), 5.0, FLOW_BAD)
            draw_line(center + Vector2(15.0, -18.0), center + Vector2(15.0, -14.0), Color.WHITE, 1.6, true)
            draw_circle(center + Vector2(15.0, -11.6), 0.9, Color.WHITE)

func _draw_building_shadow(center: Vector2) -> void:
    draw_rect(Rect2(center + Vector2(-14.0, -11.0) + Vector2(3.0, 5.0), Vector2(28.0, 27.0)), Color(0.05, 0.08, 0.09, 0.20), true)

func _draw_house(center: Vector2, color: Color) -> void:
    draw_rect(Rect2(center + Vector2(-12.0, -7.0), Vector2(24.0, 20.0)), color, true)
    draw_colored_polygon(PackedVector2Array([center + Vector2(-15.0, -7.0), center + Vector2(0.0, -18.0), center + Vector2(15.0, -7.0)]), color.darkened(0.20))
    draw_rect(Rect2(center + Vector2(-3.2, 3.0), Vector2(6.4, 10.0)), color.darkened(0.30), true)
    draw_rect(Rect2(center + Vector2(-9.0, -3.0), Vector2(5.0, 5.0)), Color("#DCE8E5"), true)
    draw_rect(Rect2(center + Vector2(4.0, -3.0), Vector2(5.0, 5.0)), Color("#DCE8E5"), true)

func _draw_office(center: Vector2, color: Color) -> void:
    draw_rect(Rect2(center + Vector2(-13.0, -17.0), Vector2(26.0, 31.0)), color.darkened(0.10), true)
    draw_rect(Rect2(center + Vector2(-10.0, -14.0), Vector2(20.0, 26.0)), color, true)
    for x: int in range(3):
        for y: int in range(4):
            var window_center := center + Vector2(-6.0 + float(x) * 6.0, -9.0 + float(y) * 6.0)
            var window_color := Color("#F5DEA0") if _day_factor() < 0.35 and (x + y) % 2 == 0 else Color("#D9E8E8")
            draw_rect(Rect2(window_center - Vector2(1.8, 1.6), Vector2(3.6, 3.2)), window_color, true)
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

func _draw_network_furniture() -> void:
    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        if _cell_hash(cell) % 4 != 0:
            continue
        var center := simulation.cell_to_world(cell)
        var offset := Vector2(15.0, -14.0)
        draw_line(center + offset, center + offset + Vector2(0.0, -8.0), Color("#526568"), 1.3, true)
        draw_circle(center + offset + Vector2(0.0, -9.0), 1.8, Color("#D6DFD8"))

func _draw_day_night_atmosphere() -> void:
    var darkness: float = 1.0 - _day_factor()
    if darkness <= 0.01:
        return
    draw_rect(Rect2(Vector2.ZERO, simulation.WORLD_SIZE), Color(0.035, 0.075, 0.105, darkness * 0.28), true)

func _draw_night_lights() -> void:
    var darkness: float = 1.0 - _day_factor()
    if darkness < 0.18:
        return
    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        if _cell_hash(cell) % 4 != 0:
            continue
        var center := simulation.cell_to_world(cell) + Vector2(15.0, -23.0)
        draw_circle(center, 10.0, Color(STREET_LIGHT, 0.035 + darkness * 0.07))
        draw_circle(center, 4.5, Color(STREET_LIGHT, 0.08 + darkness * 0.14))
        draw_circle(center, 1.8, Color(STREET_LIGHT, 0.72 + darkness * 0.24))

func _cell_hash(cell: Vector2i) -> int:
    return abs(cell.x * 73856093 ^ cell.y * 19349663)
