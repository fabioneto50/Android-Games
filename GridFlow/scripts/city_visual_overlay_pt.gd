extends CityVisualOverlay
class_name CityVisualOverlayPT

const ROTUNDA_SETAS := Color("#F3D16F")
const ROTUNDA_ILHA := Color("#86A977")
const CEDENCIA := Color("#F1EEE6")
const LIGACAO_PISO := Color("#4A575A")
const LIGACAO_BORDA := Color("#D2CFC5")
const ROTUNDA_RAIO_EXTERIOR := 31.0
const ROTUNDA_RAIO_PISTA := 27.5
const ROTUNDA_RAIO_ILHA := 14.0
const ROTUNDA_RAIO_TRAJETO := 21.5

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
    eyebrow.text = "ESTRATÉGIA DE TRÁFEGO URBANO"
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
    city.text = "LISBOA"
    city.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    city.add_theme_font_size_override("font_size", 16)
    city.add_theme_color_override("font_color", Color("#94AAA9"))
    column.add_child(city)

    var divider := HSeparator.new()
    divider.custom_minimum_size = Vector2(0.0, 14.0)
    column.add_child(divider)

    var description := Label.new()
    description.text = "Constrói uma rede viária resistente enquanto Lisboa cresce à tua volta.\nControla cruzamentos, cria rotundas, alarga estradas, atravessa o Tejo e abre caminho às emergências antes de o trânsito colapsar."
    description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.add_theme_font_size_override("font_size", 14)
    description.add_theme_color_override("font_color", Color("#C7D3D1"))
    description.custom_minimum_size = Vector2(0.0, 82.0)
    column.add_child(description)

    var features := Label.new()
    features.text = "TRÁFEGO DINÂMICO   •   HORA DE PONTA   •   EMERGÊNCIAS   •   CRESCIMENTO"
    features.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    features.add_theme_font_size_override("font_size", 10)
    features.add_theme_color_override("font_color", Color("#78908F"))
    column.add_child(features)

    var play := Button.new()
    play.text = "CONTINUAR EM LISBOA"
    play.custom_minimum_size = Vector2(0.0, 58.0)
    play.add_theme_font_size_override("font_size", 15)
    GridFlowUITheme.apply_button(play, true)
    play.pressed.connect(_start_game)
    column.add_child(play)

    var hint := Label.new()
    hint.text = "Dica: as rotundas grandes mantêm o fluxo sem semáforos, mas é preciso deixar espaço à volta."
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 10)
    hint.add_theme_color_override("font_color", Color("#718483"))
    column.add_child(hint)

func _draw_buildings() -> void:
    _draw_building_connections()
    super._draw_buildings()

func _draw_building_connections() -> void:
    for building: CityBuilding in simulation.buildings:
        var access: Vector2i = simulation._access_road_cell(building.cell)
        if access == simulation.INVALID_CELL:
            continue

        var house_center: Vector2 = simulation.cell_to_world(building.cell)
        var road_center: Vector2 = simulation.cell_to_world(access)
        var direction: Vector2 = (road_center - house_center).normalized()
        if direction.length_squared() <= 0.0:
            continue

        var start: Vector2 = house_center + direction * 13.0
        var end: Vector2 = road_center - direction * 8.0
        var width: float = 9.0 if building.building_type == "hospital" else 6.0

        draw_line(start + Vector2(1.0, 2.0), end + Vector2(1.0, 2.0), Color(0.0, 0.0, 0.0, 0.16), width + 5.0, true)
        draw_line(start, end, LIGACAO_BORDA, width + 4.0, true)
        draw_line(start, end, LIGACAO_PISO, width, true)

        if building.building_type == "residential":
            var normal := Vector2(-direction.y, direction.x)
            draw_line(start - normal * 3.0, start + normal * 3.0, Color("#E9E5DA"), 1.2, true)

func _draw_roundabouts_signals_and_directions() -> void:
    for raw_cell: Variant in simulation.roundabouts.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = simulation.cell_to_world(cell)

        # Rotunda muito maior: o círculo tapa completamente o antigo cruzamento
        # e deixa uma pista circular larga e legível.
        draw_circle(center + Vector2(2.5, 4.0), ROTUNDA_RAIO_EXTERIOR + 2.0, Color(0.0, 0.0, 0.0, 0.20))
        draw_circle(center, ROTUNDA_RAIO_EXTERIOR, Color("#202D31"))
        draw_circle(center, ROTUNDA_RAIO_PISTA, Color("#334248"))

        # Linha circular de circulação que coincide com a trajetória dos carros.
        draw_arc(center, ROTUNDA_RAIO_TRAJETO, 0.0, TAU, 56, Color(0.88, 0.88, 0.80, 0.42), 1.2, true)

        draw_circle(center, ROTUNDA_RAIO_ILHA + 2.0, Color("#253236"))
        draw_circle(center, ROTUNDA_RAIO_ILHA, ROTUNDA_ILHA.darkened(0.12))
        draw_circle(center, ROTUNDA_RAIO_ILHA - 2.5, ROTUNDA_ILHA)
        draw_circle(center + Vector2(-4.0, -3.0), 4.5, Color("#6F9D73"))
        draw_circle(center + Vector2(4.5, 3.5), 3.3, Color("#7FAF80"))

        _draw_circular_arrow(center, -0.15)
        _draw_circular_arrow(center, 1.95)
        _draw_circular_arrow(center, 4.05)

        for grid_direction: Vector2i in simulation.DIRECTIONS:
            if not simulation.road_cells.has(cell + grid_direction):
                continue
            _draw_yield_mark(center, grid_direction)

    for raw_cell: Variant in simulation.traffic_lights.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var center: Vector2 = simulation.cell_to_world(cell)
        var green: bool = simulation._vertical_signal_green(cell)
        draw_circle(center + Vector2(1.0, 1.5), 7.3, Color(0.0, 0.0, 0.0, 0.18))
        draw_circle(center, 6.6, Color("#172326"))
        draw_circle(center, 4.0, Color("#66C990") if green else Color("#E36C65"))

    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var one_way: Vector2i = simulation.graph.get_one_way(cell)
        if one_way == Vector2i.ZERO:
            continue
        var center: Vector2 = simulation.cell_to_world(cell)
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
            draw_arc(simulation.cell_to_world(cell), 15.0 * pulse, 0.0, TAU, 24, Color("#5FD39A"), 3.0, true)

func _draw_circular_arrow(center: Vector2, start_angle: float) -> void:
    var radius: float = ROTUNDA_RAIO_TRAJETO
    var end_angle: float = start_angle - 0.86
    draw_arc(center, radius, end_angle, start_angle, 18, ROTUNDA_SETAS, 2.6, true)

    var tip := center + Vector2(cos(end_angle), sin(end_angle)) * radius
    var tangent := Vector2(-sin(end_angle), cos(end_angle))
    var radial := Vector2(cos(end_angle), sin(end_angle))
    draw_colored_polygon(PackedVector2Array([
        tip,
        tip + tangent * 5.5 + radial * 2.0,
        tip + tangent * 1.0 - radial * 5.0
    ]), ROTUNDA_SETAS)

func _draw_yield_mark(center: Vector2, grid_direction: Vector2i) -> void:
    var direction := Vector2(float(grid_direction.x), float(grid_direction.y))
    var normal := Vector2(-direction.y, direction.x)
    var base_center := center + direction * 35.0
    var tip := center + direction * 28.0
    draw_colored_polygon(PackedVector2Array([
        tip,
        base_center + normal * 5.0,
        base_center - normal * 5.0
    ]), CEDENCIA)
