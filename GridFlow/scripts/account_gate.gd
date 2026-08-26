extends CanvasLayer
class_name GridFlowAccountGate

var account_manager := GridFlowAccountManager.new()
var simulation: CitySimulationPT
var login_root: Control
var session_panel: PanelContainer
var identifier_input: LineEdit
var password_input: LineEdit
var feedback_label: Label
var session_label: Label
var _autosave_timer: float = 0.0
var _authenticated: bool = false

func _ready() -> void:
    layer = 120
    await get_tree().process_frame
    simulation = get_parent().get("simulation") as CitySimulationPT
    if simulation == null:
        return
    simulation.set_paused(true)
    _build_login()
    _build_session_badge()

func _process(delta: float) -> void:
    if not _authenticated or simulation == null:
        return
    _autosave_timer += delta
    if _autosave_timer >= 4.0:
        _autosave_timer = 0.0
        _save_current_game()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST and _authenticated:
        _save_current_game()

func _build_login() -> void:
    login_root = Control.new()
    login_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(login_root)

    var backdrop := ColorRect.new()
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.color = Color(0.025, 0.045, 0.052, 0.96)
    login_root.add_child(backdrop)

    var panel := PanelContainer.new()
    panel.position = Vector2(365.0, 95.0)
    panel.size = Vector2(550.0, 530.0)
    GridFlowUITheme.apply_panel(panel, Color("#122126"), 24)
    login_root.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 42)
    margin.add_theme_constant_override("margin_right", 42)
    margin.add_theme_constant_override("margin_top", 34)
    margin.add_theme_constant_override("margin_bottom", 32)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 13)
    margin.add_child(column)

    var eyebrow := Label.new()
    eyebrow.text = "PERFIL DO JOGADOR"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 11)
    eyebrow.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    column.add_child(eyebrow)

    var title := Label.new()
    title.text = "GRIDFLOW"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", Color("#F4F7F2"))
    column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Entra para continuar a tua cidade exatamente onde a deixaste."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.add_theme_font_size_override("font_size", 13)
    subtitle.add_theme_color_override("font_color", Color("#AFC0BE"))
    subtitle.custom_minimum_size = Vector2(0.0, 42.0)
    column.add_child(subtitle)

    identifier_input = LineEdit.new()
    identifier_input.placeholder_text = "Utilizador ou e-mail"
    identifier_input.text = account_manager.get_last_identifier()
    identifier_input.custom_minimum_size = Vector2(0.0, 48.0)
    identifier_input.add_theme_font_size_override("font_size", 14)
    column.add_child(identifier_input)

    password_input = LineEdit.new()
    password_input.placeholder_text = "Palavra-passe"
    password_input.secret = true
    password_input.custom_minimum_size = Vector2(0.0, 48.0)
    password_input.add_theme_font_size_override("font_size", 14)
    password_input.text_submitted.connect(func(_value: String): _try_login())
    column.add_child(password_input)

    feedback_label = Label.new()
    feedback_label.text = "A conta e o progresso ficam guardados neste dispositivo/navegador."
    feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    feedback_label.custom_minimum_size = Vector2(0.0, 44.0)
    feedback_label.add_theme_font_size_override("font_size", 11)
    feedback_label.add_theme_color_override("font_color", Color("#7F9795"))
    column.add_child(feedback_label)

    var login_button := Button.new()
    login_button.text = "ENTRAR"
    login_button.custom_minimum_size = Vector2(0.0, 54.0)
    login_button.add_theme_font_size_override("font_size", 14)
    GridFlowUITheme.apply_button(login_button, true)
    login_button.pressed.connect(_try_login)
    column.add_child(login_button)

    var create_button := Button.new()
    create_button.text = "CRIAR CONTA"
    create_button.custom_minimum_size = Vector2(0.0, 50.0)
    create_button.add_theme_font_size_override("font_size", 13)
    GridFlowUITheme.apply_button(create_button)
    create_button.pressed.connect(_try_create_account)
    column.add_child(create_button)

    var note := Label.new()
    note.text = "Podes usar um nome de utilizador ou um endereço de e-mail."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 10)
    note.add_theme_color_override("font_color", Color("#718483"))
    column.add_child(note)

func _build_session_badge() -> void:
    session_panel = PanelContainer.new()
    session_panel.position = Vector2(1010.0, 122.0)
    session_panel.size = Vector2(250.0, 48.0)
    session_panel.visible = false
    GridFlowUITheme.apply_panel(session_panel, Color(0.06, 0.11, 0.12, 0.92), 12)
    add_child(session_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 8)
    margin.add_theme_constant_override("margin_top", 6)
    margin.add_theme_constant_override("margin_bottom", 6)
    session_panel.add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    margin.add_child(row)

    session_label = Label.new()
    session_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    session_label.add_theme_font_size_override("font_size", 10)
    session_label.add_theme_color_override("font_color", Color("#C9D5D2"))
    row.add_child(session_label)

    var logout_button := Button.new()
    logout_button.text = "SAIR"
    logout_button.custom_minimum_size = Vector2(58.0, 30.0)
    logout_button.add_theme_font_size_override("font_size", 9)
    GridFlowUITheme.apply_button(logout_button)
    logout_button.pressed.connect(_logout)
    row.add_child(logout_button)

func _try_login() -> void:
    var result := account_manager.login(identifier_input.text, password_input.text)
    if not bool(result.get("ok", false)):
        _set_feedback(String(result.get("message", "Não foi possível iniciar sessão.")), true)
        return
    _finish_authentication(false)

func _try_create_account() -> void:
    var result := account_manager.create_account(identifier_input.text, password_input.text)
    if not bool(result.get("ok", false)):
        _set_feedback(String(result.get("message", "Não foi possível criar a conta.")), true)
        return
    _finish_authentication(true)

func _finish_authentication(new_account: bool) -> void:
    _authenticated = true
    _autosave_timer = 0.0
    password_input.text = ""

    if new_account:
        _reset_to_new_game()
    elif account_manager.has_save():
        _restore_game_state(account_manager.load_game())
    else:
        _reset_to_new_game()

    login_root.visible = false
    session_panel.visible = true
    session_label.text = "JOGADOR  %s" % account_manager.current_user
    simulation.set_paused(true)
    simulation._emit_hud()

func _logout() -> void:
    _save_current_game()
    account_manager.logout()
    _authenticated = false
    session_panel.visible = false
    login_root.visible = true
    feedback_label.text = "Sessão terminada. Entra noutra conta ou volta a iniciar sessão."
    feedback_label.add_theme_color_override("font_color", Color("#7F9795"))
    simulation.set_paused(true)

func start_new_city_for_current_user() -> void:
    if not _authenticated:
        return
    account_manager.delete_save()
    _reset_to_new_game()
    _save_current_game()

func _set_feedback(message: String, is_error: bool) -> void:
    feedback_label.text = message
    feedback_label.add_theme_color_override("font_color", GridFlowUITheme.DANGER if is_error else GridFlowUITheme.ACCENT)

func _save_current_game() -> void:
    if not _authenticated or simulation == null:
        return
    account_manager.save_game(_capture_game_state())

func _capture_game_state() -> Dictionary:
    var roads: Array = []
    for raw_cell: Variant in simulation.road_cells.keys():
        var cell: Vector2i = raw_cell as Vector2i
        var one_way: Vector2i = simulation.graph.get_one_way(cell)
        roads.append({
            "x": cell.x,
            "y": cell.y,
            "lanes": simulation.get_lane_count(cell),
            "one_x": one_way.x,
            "one_y": one_way.y,
            "signal": simulation.traffic_lights.has(cell),
            "roundabout": simulation.roundabouts.has(cell),
            "bridge": simulation.bridge_cells.has(cell)
        })

    var building_data: Array = []
    for building: CityBuilding in simulation.buildings:
        building_data.append({
            "x": building.cell.x,
            "y": building.cell.y,
            "type": building.building_type
        })

    return {
        "version": 2,
        "week": simulation.week,
        "road_budget": simulation.road_budget,
        "signal_budget": simulation.signal_budget,
        "roundabout_budget": simulation.roundabout_budget,
        "lane_upgrade_budget": simulation.lane_upgrade_budget,
        "bridge_budget": simulation.bridge_budget,
        "completed_trips": simulation.completed_trips,
        "pending_demand": simulation.pending_demand,
        "flow_score": simulation.flow_score,
        "critical_time": simulation.critical_time,
        "sim_time": simulation.sim_time,
        "city_minutes": simulation.city_minutes,
        "roads": roads,
        "buildings": building_data,
        "emergency_completed": simulation.emergency_manager.completed_count,
        "emergency_failed": simulation.emergency_manager.failed_count,
        "green_charges": simulation.emergency_manager.green_charges
    }

func _restore_game_state(data: Dictionary) -> void:
    if data.is_empty():
        _reset_to_new_game()
        return

    _clear_city()

    simulation.week = int(data.get("week", 1))
    simulation.road_budget = int(data.get("road_budget", 120))
    simulation.signal_budget = int(data.get("signal_budget", 2))
    simulation.roundabout_budget = int(data.get("roundabout_budget", 1))
    simulation.lane_upgrade_budget = int(data.get("lane_upgrade_budget", 2))
    simulation.bridge_budget = int(data.get("bridge_budget", 1))
    simulation.completed_trips = int(data.get("completed_trips", 0))
    simulation.pending_demand = int(data.get("pending_demand", 0))
    simulation.flow_score = float(data.get("flow_score", 100.0))
    simulation.critical_time = float(data.get("critical_time", 0.0))
    simulation.sim_time = float(data.get("sim_time", 0.0))
    simulation.city_minutes = float(data.get("city_minutes", 420.0))

    var roads: Array = data.get("roads", []) as Array
    for raw_road: Variant in roads:
        if not raw_road is Dictionary:
            continue
        var road: Dictionary = raw_road
        var cell := Vector2i(int(road.get("x", 0)), int(road.get("y", 0)))
        simulation.road_cells[cell] = true
        simulation.road_lanes[cell] = int(road.get("lanes", 1))
        simulation.graph.add_cell(cell)
        if bool(road.get("signal", false)):
            simulation.traffic_lights[cell] = true
        if bool(road.get("roundabout", false)):
            simulation.roundabouts[cell] = true
        if bool(road.get("bridge", false)):
            simulation.bridge_cells[cell] = true

    for raw_road: Variant in roads:
        if not raw_road is Dictionary:
            continue
        var road: Dictionary = raw_road
        var cell := Vector2i(int(road.get("x", 0)), int(road.get("y", 0)))
        var one_way := Vector2i(int(road.get("one_x", 0)), int(road.get("one_y", 0)))
        simulation.graph.set_one_way(cell, one_way)

    var building_data: Array = data.get("buildings", []) as Array
    for raw_building: Variant in building_data:
        if not raw_building is Dictionary:
            continue
        var item: Dictionary = raw_building
        simulation._add_building(
            Vector2i(int(item.get("x", 0)), int(item.get("y", 0))),
            String(item.get("type", "residential"))
        )

    simulation.emergency_manager.completed_count = int(data.get("emergency_completed", 0))
    simulation.emergency_manager.failed_count = int(data.get("emergency_failed", 0))
    simulation.emergency_manager.green_charges = int(data.get("green_charges", 1))
    simulation.emergency_manager.active.clear()
    simulation.emergency_manager.green_cells.clear()
    simulation.emergency_manager.green_timer = 0.0

    _finalize_restored_state()

func _reset_to_new_game() -> void:
    _clear_city()
    simulation.road_budget = 120
    simulation.signal_budget = 2
    simulation.roundabout_budget = 1
    simulation.lane_upgrade_budget = 2
    simulation.bridge_budget = 1
    simulation.week = 1
    simulation.completed_trips = 0
    simulation.pending_demand = 0
    simulation.flow_score = 100.0
    simulation.critical_time = 0.0
    simulation.sim_time = 0.0
    simulation.city_minutes = 420.0
    simulation.emergency_manager.completed_count = 0
    simulation.emergency_manager.failed_count = 0
    simulation.emergency_manager.green_charges = 1
    simulation._create_starter_city()
    _finalize_restored_state()

func _clear_city() -> void:
    for vehicle: VehicleAgent in simulation.vehicles:
        if is_instance_valid(vehicle):
            vehicle.queue_free()
    simulation.vehicles.clear()
    simulation.occupancy.clear()
    simulation.buildings.clear()
    simulation.road_cells.clear()
    simulation.road_lanes.clear()
    simulation.traffic_lights.clear()
    simulation.roundabouts.clear()
    simulation.bridge_cells.clear()
    simulation.graph.clear()

func _finalize_restored_state() -> void:
    simulation.is_game_over = false
    simulation.awaiting_upgrade = false
    simulation.paused = true
    simulation._growth_timer = 0.0
    simulation._demand_timer = 0.0
    simulation._week_timer = 0.0
    simulation._hud_timer = 0.0
    simulation.reset_view()
    simulation.queue_redraw()
    simulation._emit_hud()
