extends GridFlowAccountGate
class_name GridFlowAccountGateBootstrap

var _simulation_resolved: bool = false
var menu_root: Control
var menu_stats: Label
var menu_note: Label
var continue_button: Button
var new_game_button: Button
var guide_panel: PanelContainer
var _had_existing_save: bool = false
var _new_game_armed: bool = false

func _ready() -> void:
    layer = 120
    _build_login()
    _build_session_badge()
    _build_main_menu()
    _try_resolve_simulation()

func _process(delta: float) -> void:
    if not _simulation_resolved:
        _try_resolve_simulation()
        if not _simulation_resolved:
            return

    super._process(delta)

func _try_resolve_simulation() -> void:
    if simulation != null:
        _simulation_resolved = true
        simulation.set_paused(true)
        return

    var parent_node := get_parent()
    if parent_node == null:
        return

    var candidate: Variant = parent_node.get("simulation")
    if candidate is CitySimulationPT:
        simulation = candidate as CitySimulationPT
        _simulation_resolved = true
        simulation.set_paused(true)

func _try_login() -> void:
    if not _simulation_resolved:
        _try_resolve_simulation()
    if simulation == null:
        _set_feedback("O jogo ainda está a iniciar. Tenta novamente.", true)
        return
    super._try_login()

func _try_create_account() -> void:
    if not _simulation_resolved:
        _try_resolve_simulation()
    if simulation == null:
        _set_feedback("O jogo ainda está a iniciar. Tenta novamente.", true)
        return
    super._try_create_account()

func _finish_authentication(new_account: bool) -> void:
    _had_existing_save = account_manager.has_save() and not new_account
    super._finish_authentication(new_account)
    _hide_legacy_intro()
    _show_main_menu()

func _logout() -> void:
    if menu_root != null:
        menu_root.visible = false
    if guide_panel != null:
        guide_panel.visible = false
    _new_game_armed = false
    super._logout()

func _hide_legacy_intro() -> void:
    var parent_node := get_parent()
    if parent_node == null:
        return
    var overlay_variant: Variant = parent_node.get("city_overlay")
    if overlay_variant is CityVisualOverlayPT:
        var overlay := overlay_variant as CityVisualOverlayPT
        overlay._intro_visible = false
        if overlay._intro_layer != null:
            overlay._intro_layer.visible = false

func _build_main_menu() -> void:
    menu_root = Control.new()
    menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_root.visible = false
    add_child(menu_root)

    var backdrop := ColorRect.new()
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.color = Color("#091317")
    menu_root.add_child(backdrop)

    var glow := ColorRect.new()
    glow.position = Vector2(0.0, 0.0)
    glow.size = Vector2(1280.0, 720.0)
    glow.color = Color(0.08, 0.18, 0.19, 0.34)
    menu_root.add_child(glow)

    var shell := PanelContainer.new()
    shell.position = Vector2(110.0, 72.0)
    shell.size = Vector2(1060.0, 576.0)
    GridFlowUITheme.apply_panel(shell, Color("#112126"), 24)
    menu_root.add_child(shell)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_top", 30)
    margin.add_theme_constant_override("margin_bottom", 30)
    shell.add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 34)
    margin.add_child(row)

    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(430.0, 0.0)
    left.add_theme_constant_override("separation", 12)
    row.add_child(left)

    var eyebrow := Label.new()
    eyebrow.text = "CENTRO DE CONTROLO URBANO"
    eyebrow.add_theme_font_size_override("font_size", 11)
    eyebrow.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    left.add_child(eyebrow)

    var title := Label.new()
    title.text = "GRIDFLOW"
    title.add_theme_font_size_override("font_size", 48)
    title.add_theme_color_override("font_color", Color("#F2F6F3"))
    left.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Constrói a rede. Controla o trânsito. Mantém a cidade viva."
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.custom_minimum_size = Vector2(410.0, 48.0)
    subtitle.add_theme_font_size_override("font_size", 14)
    subtitle.add_theme_color_override("font_color", Color("#AFC1BE"))
    left.add_child(subtitle)

    continue_button = Button.new()
    continue_button.text = "CONTINUAR LISBOA"
    continue_button.custom_minimum_size = Vector2(0.0, 58.0)
    continue_button.add_theme_font_size_override("font_size", 15)
    GridFlowUITheme.apply_button(continue_button, true)
    continue_button.pressed.connect(_start_from_menu)
    left.add_child(continue_button)

    new_game_button = Button.new()
    new_game_button.text = "NOVO JOGO"
    new_game_button.custom_minimum_size = Vector2(0.0, 52.0)
    new_game_button.add_theme_font_size_override("font_size", 13)
    GridFlowUITheme.apply_button(new_game_button)
    new_game_button.pressed.connect(_new_game_from_menu)
    left.add_child(new_game_button)

    var how_to := Button.new()
    how_to.text = "COMO JOGAR"
    how_to.custom_minimum_size = Vector2(0.0, 48.0)
    how_to.add_theme_font_size_override("font_size", 12)
    GridFlowUITheme.apply_button(how_to)
    how_to.pressed.connect(_toggle_guide)
    left.add_child(how_to)

    var logout := Button.new()
    logout.text = "TERMINAR SESSÃO"
    logout.custom_minimum_size = Vector2(0.0, 44.0)
    logout.add_theme_font_size_override("font_size", 11)
    GridFlowUITheme.apply_button(logout)
    logout.pressed.connect(_logout)
    left.add_child(logout)

    menu_note = Label.new()
    menu_note.text = ""
    menu_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    menu_note.custom_minimum_size = Vector2(410.0, 46.0)
    menu_note.add_theme_font_size_override("font_size", 10)
    menu_note.add_theme_color_override("font_color", Color("#7F9693"))
    left.add_child(menu_note)

    var right := VBoxContainer.new()
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_theme_constant_override("separation", 14)
    row.add_child(right)

    var profile := Label.new()
    profile.name = "ProfileLabel"
    profile.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    profile.add_theme_font_size_override("font_size", 11)
    profile.add_theme_color_override("font_color", Color("#8CA4A1"))
    right.add_child(profile)

    var city_card := PanelContainer.new()
    city_card.custom_minimum_size = Vector2(0.0, 330.0)
    GridFlowUITheme.apply_panel(city_card, Color("#172C31"), 18)
    right.add_child(city_card)

    var card_margin := MarginContainer.new()
    card_margin.add_theme_constant_override("margin_left", 24)
    card_margin.add_theme_constant_override("margin_right", 24)
    card_margin.add_theme_constant_override("margin_top", 22)
    card_margin.add_theme_constant_override("margin_bottom", 22)
    city_card.add_child(card_margin)

    var card := VBoxContainer.new()
    card.add_theme_constant_override("separation", 10)
    card_margin.add_child(card)

    var city_tag := Label.new()
    city_tag.text = "CIDADE ATIVA  •  PORTUGAL"
    city_tag.add_theme_font_size_override("font_size", 10)
    city_tag.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    card.add_child(city_tag)

    var city_name := Label.new()
    city_name.text = "LISBOA"
    city_name.add_theme_font_size_override("font_size", 34)
    city_name.add_theme_color_override("font_color", Color("#F1F5F2"))
    card.add_child(city_name)

    var city_description := Label.new()
    city_description.text = "Tejo • pontes • hora de ponta • emergências\nMantém as casas ligadas aos destinos enquanto a cidade cresce."
    city_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    city_description.custom_minimum_size = Vector2(0.0, 58.0)
    city_description.add_theme_font_size_override("font_size", 12)
    city_description.add_theme_color_override("font_color", Color("#B8C7C4"))
    card.add_child(city_description)

    var divider := HSeparator.new()
    card.add_child(divider)

    menu_stats = Label.new()
    menu_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    menu_stats.custom_minimum_size = Vector2(0.0, 88.0)
    menu_stats.add_theme_font_size_override("font_size", 13)
    menu_stats.add_theme_color_override("font_color", Color("#D8E2DF"))
    card.add_child(menu_stats)

    var future := Label.new()
    future.text = "PRÓXIMAS CIDADES\nPorto  •  Madrid  •  Amesterdão   —   em desenvolvimento"
    future.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    future.add_theme_font_size_override("font_size", 10)
    future.add_theme_color_override("font_color", Color("#647C7A"))
    right.add_child(future)

    _build_guide_panel()

func _build_guide_panel() -> void:
    guide_panel = PanelContainer.new()
    guide_panel.position = Vector2(330.0, 145.0)
    guide_panel.size = Vector2(620.0, 430.0)
    guide_panel.visible = false
    GridFlowUITheme.apply_panel(guide_panel, Color("#13262B"), 20)
    menu_root.add_child(guide_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 30)
    margin.add_theme_constant_override("margin_right", 30)
    margin.add_theme_constant_override("margin_top", 26)
    margin.add_theme_constant_override("margin_bottom", 26)
    guide_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    margin.add_child(column)

    var title := Label.new()
    title.text = "COMO FUNCIONA A CIDADE"
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", Color("#F2F5F2"))
    column.add_child(title)

    var body := Label.new()
    body.text = "• Cada CASA tem 2 carros próprios.\n• Escritórios, comércio e hospitais acumulam PEDIDOS DE DESLOCAÇÃO.\n• Um carro só sai se a sua casa estiver ligada por estrada ao destino.\n• O percurso completo é CASA → DESTINO → CASA.\n• Os losangos sobre um destino mostram a procura por servir.\n• Quando o anel do destino fica amarelo ou vermelho, a pressão está elevada.\n• Pedidos acumulados, filas e estradas sobrecarregadas fazem descer o FLUXO.\n• Rotundas, vias adicionais e percursos alternativos aumentam a capacidade da rede."
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.custom_minimum_size = Vector2(0.0, 285.0)
    body.add_theme_font_size_override("font_size", 13)
    body.add_theme_color_override("font_color", Color("#C7D3D0"))
    column.add_child(body)

    var close := Button.new()
    close.text = "FECHAR"
    close.custom_minimum_size = Vector2(0.0, 46.0)
    GridFlowUITheme.apply_button(close, true)
    close.pressed.connect(_toggle_guide)
    column.add_child(close)

func _show_main_menu() -> void:
    if menu_root == null or simulation == null:
        return
    simulation.set_paused(true)
    menu_root.visible = true
    session_panel.visible = false
    guide_panel.visible = false
    _new_game_armed = false
    new_game_button.text = "NOVO JOGO"

    var profile := menu_root.find_child("ProfileLabel", true, false) as Label
    if profile != null:
        profile.text = "JOGADOR  %s" % account_manager.current_user

    _refresh_menu_summary()

func _refresh_menu_summary() -> void:
    if simulation == null:
        return
    var snapshot: Dictionary = simulation.get_snapshot()
    if _had_existing_save:
        continue_button.text = "CONTINUAR LISBOA"
        menu_note.text = "O teu progresso é guardado automaticamente neste dispositivo."
    else:
        continue_button.text = "COMEÇAR EM LISBOA"
        menu_note.text = "Nova cidade pronta. O primeiro save será criado automaticamente."

    menu_stats.text = "SEMANA %d\nPOPULAÇÃO %s\nPONTUAÇÃO %d\nPEDIDOS PENDENTES %d  •  CARROS EM CASA %d" % [
        int(snapshot.week),
        _compact_menu_number(int(snapshot.population)),
        int(snapshot.score),
        int(snapshot.get("requests", snapshot.pending)),
        int(snapshot.get("home_cars_available", 0))
    ]

func _start_from_menu() -> void:
    _new_game_armed = false
    menu_root.visible = false
    guide_panel.visible = false
    session_panel.visible = true
    simulation.set_paused(false)
    _save_current_game()

func _new_game_from_menu() -> void:
    if _had_existing_save and not _new_game_armed:
        _new_game_armed = true
        new_game_button.text = "CONFIRMAR NOVA CIDADE"
        menu_note.text = "Atenção: isto substitui a cidade guardada deste jogador. Carrega novamente para confirmar."
        menu_note.add_theme_color_override("font_color", GridFlowUITheme.WARNING)
        return

    start_new_city_for_current_user()
    _had_existing_save = false
    _new_game_armed = false
    menu_note.add_theme_color_override("font_color", Color("#7F9693"))
    _start_from_menu()

func _toggle_guide() -> void:
    guide_panel.visible = not guide_panel.visible

func _compact_menu_number(value: int) -> String:
    if value >= 1000000:
        return "%.1fM" % (float(value) / 1000000.0)
    if value >= 1000:
        return "%.1fK" % (float(value) / 1000.0)
    return str(value)

# Save v3: acrescenta a procura de cada destino sem quebrar saves anteriores.
func _capture_game_state() -> Dictionary:
    var data: Dictionary = super._capture_game_state()
    data["version"] = 3
    var building_data: Array = []
    for building: CityBuilding in simulation.buildings:
        building_data.append({
            "x": building.cell.x,
            "y": building.cell.y,
            "type": building.building_type,
            "demand": building.demand
        })
    data["buildings"] = building_data
    return data

func _restore_game_state(data: Dictionary) -> void:
    super._restore_game_state(data)
    simulation.home_active_vehicles.clear()
    simulation.destination_inbound.clear()

    var building_data: Array = data.get("buildings", []) as Array
    for raw_building: Variant in building_data:
        if not raw_building is Dictionary:
            continue
        var item: Dictionary = raw_building
        var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
        var building := simulation._building_at_cell(cell)
        if building != null:
            building.demand = int(item.get("demand", 0))

    simulation._recompute_pending_demand()
    simulation._emit_hud()

func _reset_to_new_game() -> void:
    super._reset_to_new_game()
    simulation.home_active_vehicles.clear()
    simulation.destination_inbound.clear()
    for building: CityBuilding in simulation.buildings:
        building.demand = 0
    simulation._recompute_pending_demand()
    simulation._emit_hud()
