extends CityVisualOverlayPT
class_name CityVisualOverlayPremium

const DISTRICT_A := Color(0.84, 0.80, 0.68, 0.055)
const DISTRICT_B := Color(0.53, 0.73, 0.66, 0.050)
const DISTRICT_C := Color(0.62, 0.70, 0.80, 0.045)
const CROSSWALK := Color(0.91, 0.91, 0.84, 0.48)
const FERRY_BODY := Color("#E8E5D9")
const FERRY_GLASS := Color("#365E67")

func _draw_environment() -> void:
    super._draw_environment()

    # Grandes manchas de bairro dão estrutura visual à cidade sem criar uma grelha rígida.
    draw_circle(Vector2(220.0, 230.0), 150.0, DISTRICT_A)
    draw_circle(Vector2(590.0, 260.0), 175.0, DISTRICT_B)
    draw_circle(Vector2(980.0, 250.0), 170.0, DISTRICT_C)
    draw_circle(Vector2(360.0, 520.0), 145.0, Color(DISTRICT_B, 0.038))
    draw_circle(Vector2(900.0, 535.0), 180.0, Color(DISTRICT_A, 0.036))

    # Textura cartográfica muito subtil.
    for x: int in range(0, 1281, 96):
        draw_line(Vector2(float(x), 110.0), Vector2(float(x), 590.0), Color(0.22, 0.31, 0.31, 0.035), 1.0, true)
    for y: int in range(120, 590, 96):
        draw_line(Vector2(0.0, float(y)), Vector2(1280.0, float(y)), Color(0.22, 0.31, 0.31, 0.03), 1.0, true)

func _draw_water_detail() -> void:
    super._draw_water_detail()
    _draw_ferry(0.17, 1.0)
    _draw_ferry(0.68, -1.0)

func _draw_ferry(offset: float, direction_sign: float) -> void:
    var river_y: float = simulation.cell_to_world(Vector2i(0, simulation.RIVER_ROW)).y
    var travel: float = fmod(simulation.sim_time * 15.0 * direction_sign + offset * 1280.0 + 1280.0, 1280.0)
    var x: float = travel if direction_sign > 0.0 else 1280.0 - travel
    var center := Vector2(x, river_y + (9.0 if offset < 0.5 else -10.0))
    draw_rect(Rect2(center + Vector2(-10.0, -3.5), Vector2(20.0, 7.0)), Color(0.04, 0.10, 0.12, 0.15), true)
    draw_rect(Rect2(center + Vector2(-9.0, -4.5), Vector2(18.0, 7.0)), FERRY_BODY, true)
    draw_rect(Rect2(center + Vector2(-4.0, -5.5), Vector2(8.0, 3.0)), FERRY_GLASS, true)
    draw_line(center + Vector2(-12.0, 4.5), center + Vector2(-22.0, 4.5), Color(0.88, 0.95, 0.94, 0.22), 1.3, true)

func _draw_roads() -> void:
    super._draw_roads()
    _draw_crosswalks()

func _draw_crosswalks() -> void:
    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        if simulation.roundabouts.has(cell):
            continue
        var degree: int = simulation.graph.degree(cell)
        if degree < 3:
            continue
        var center: Vector2 = simulation.cell_to_world(cell)
        for direction: Vector2i in simulation.DIRECTIONS:
            if not simulation.road_cells.has(cell + direction):
                continue
            var dir := Vector2(float(direction.x), float(direction.y))
            var normal := Vector2(-dir.y, dir.x)
            var base := center + dir * 15.0
            for stripe: int in range(-2, 3):
                var p := base + normal * float(stripe) * 3.0
                draw_line(p - dir * 2.5, p + dir * 2.5, CROSSWALK, 1.6, true)

func _draw_buildings() -> void:
    super._draw_buildings()
    _draw_building_accents()

func _draw_building_accents() -> void:
    for building: CityBuilding in simulation.buildings:
        var center: Vector2 = simulation.cell_to_world(building.cell)
        var accent: Color
        match building.building_type:
            "office":
                accent = Color("#8EB9ED")
            "shop":
                accent = Color("#F2CF72")
            "hospital":
                accent = Color("#F17B77")
            _:
                accent = Color("#F2A27D")

        # Pequena base luminosa separa visualmente cada função sem poluir o mapa.
        draw_line(center + Vector2(-11.0, 16.0), center + Vector2(11.0, 16.0), Color(accent, 0.58), 2.2, true)
        if building.building_type != "residential" and building.demand > 0:
            var intensity: float = clampf(float(building.demand) / float(maxi(1, building.demand_capacity)), 0.0, 1.5)
            draw_arc(center, 24.0 + intensity * 2.0, -2.5, -0.65, 18, Color(accent, 0.15 + intensity * 0.13), 1.5, true)

func _draw_home_garage(center: Vector2, home: CityBuilding, sim_pt: CitySimulationPT) -> void:
    var available: int = sim_pt.get_home_available_cars(home)
    var active: int = home.home_vehicle_capacity - available
    var base := center + Vector2(-10.5, 14.5)

    draw_rect(Rect2(base + Vector2(-3.0, -2.5), Vector2(25.0, 9.0)), Color(0.09, 0.14, 0.15, 0.24), true)
    draw_line(base + Vector2(-1.5, 6.0), base + Vector2(21.0, 6.0), Color(0.82, 0.84, 0.79, 0.34), 1.0, true)
    for index: int in range(home.home_vehicle_capacity):
        var slot := base + Vector2(float(index) * 11.0, 0.0)
        var car_present: bool = index >= active
        draw_rect(Rect2(slot, Vector2(8.5, 4.5)), Color("#223136"), true)
        if car_present:
            draw_rect(Rect2(slot + Vector2(0.8, 0.6), Vector2(6.9, 3.0)), Color("#DDEAE5"), true)
            draw_rect(Rect2(slot + Vector2(4.8, 1.0), Vector2(2.0, 2.2)), Color("#73969B"), true)
        else:
            draw_rect(Rect2(slot + Vector2(1.0, 1.0), Vector2(6.5, 2.4)), Color("#405257"), false, 1.0)

func _draw_destination_requests(center: Vector2, destination: CityBuilding) -> void:
    var demand: int = destination.demand
    if demand <= 0:
        return

    var pressure: float = destination.pressure()
    var marker_color := PEDIDO_NORMAL
    if pressure >= 1.0:
        marker_color = PEDIDO_CRITICO
    elif pressure >= 0.65:
        marker_color = PEDIDO_ALERTA

    var visible_count: int = mini(demand, 5)
    var spacing: float = 9.0
    var start_x: float = center.x - float(visible_count - 1) * spacing * 0.5
    var y: float = center.y - 29.0

    # Marcadores em cápsula: mais legíveis e menos semelhantes aos pins de outros jogos.
    draw_line(Vector2(start_x - 7.0, y), Vector2(start_x + float(visible_count - 1) * spacing + 7.0, y), Color(0.08, 0.13, 0.14, 0.36), 10.0, true)
    for index: int in range(visible_count):
        var p := Vector2(start_x + float(index) * spacing, y)
        draw_circle(p, 3.1, Color("#243438"))
        draw_circle(p, 2.1, marker_color)

    if demand > 5:
        var extra := Vector2(start_x + float(visible_count - 1) * spacing + 11.0, y)
        draw_circle(extra, 4.0, marker_color)
        draw_circle(extra, 1.7, Color("#243438"))

    if pressure >= 0.65:
        var pulse: float = 1.0 + sin(simulation.sim_time * 4.2) * 0.07
        draw_arc(center, 23.0 * pulse, 0.0, TAU, 34, Color(marker_color, 0.34 if pressure < 1.0 else 0.52), 2.4 if pressure < 1.0 else 3.2, true)

func _draw_day_night_atmosphere() -> void:
    super._draw_day_night_atmosphere()
    var darkness: float = 1.0 - _day_factor()
    if darkness <= 0.08:
        return
    # Vignette suave nas margens para reforçar as luzes sem escurecer o centro do mapa.
    draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(1280.0, 44.0)), Color(0.02, 0.05, 0.07, darkness * 0.12), true)
    draw_rect(Rect2(Vector2(0.0, 676.0), Vector2(1280.0, 44.0)), Color(0.02, 0.05, 0.07, darkness * 0.12), true)
    draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(38.0, 720.0)), Color(0.02, 0.05, 0.07, darkness * 0.09), true)
    draw_rect(Rect2(Vector2(1242.0, 0.0), Vector2(38.0, 720.0)), Color(0.02, 0.05, 0.07, darkness * 0.09), true)
