extends Node

var simulation: CitySimulationPT
var city_overlay: CityVisualOverlayPT
var status_label: Label
var resource_label: Label
var help_label: Label
var toast_label: Label
var speed_button: Button
var pause_button: Button
var green_button: Button
var flow_bar: ProgressBar
var mode_buttons: Dictionary = {}
var upgrade_panel: PanelContainer
var game_over_panel: PanelContainer
var upgrade_buttons: Array[Button] = []
var _upgrade_ids: Array[String] = ["", ""]
var _toast_tween: Tween

func _ready() -> void:
    simulation = CitySimulationPT.new()
    add_child(simulation)
    city_overlay = CityVisualOverlayPT.new(simulation)
    simulation.add_child(city_overlay)
    _build_interface()

    simulation.hud_updated.connect(_on_hud_updated)
    simulation.toast_requested.connect(_show_toast)
    simulation.game_over.connect(_on_game_over)
    simulation.upgrade_requested.connect(_on_upgrade_requested)

    _set_mode("road")
    _on_hud_updated(simulation.get_snapshot())

func _build_interface() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    var top_panel := PanelContainer.new()
    top_panel.position = Vector2(16.0, 14.0)
    top_panel.size = Vector2(1248.0, 100.0)
    GridFlowUITheme.apply_panel(top_panel, Color("#142125"), 16)
    canvas.add_child(top_panel)

    var top_margin := MarginContainer.new()
    top_margin.add_theme_constant_override("margin_left", 16)
    top_margin.add_theme_constant_override("margin_right", 14)
    top_margin.add_theme_constant_override("margin_top", 10)
    top_margin.add_theme_constant_override("margin_bottom", 10)
    top_panel.add_child(top_margin)

    var top_row := HBoxContainer.new()
    top_row.add_theme_constant_override("separation", 12)
    top_margin.add_child(top_row)

    var brand_column := VBoxContainer.new()
    brand_column.custom_minimum_size = Vector2(210.0, 76.0)
    brand_column.add_theme_constant_override("separation", -2)
    top_row.add_child(brand_column)

    var title := Label.new()
    title.text = "GRIDFLOW"
    title.add_theme_font_size_override("font_size", 25)
    title.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    brand_column.add_child(title)

    var city_label := Label.new()
    city_label.text = "LISBOA  •  CONTROLO DE TRÁFEGO"
    city_label.add_theme_font_size_override("font_size", 11)
    GridFlowUITheme.apply_label(city_label, true)
    brand_column.add_child(city_label)

    var objective := Label.new()
    objective.text = "MANTÉM A CIDADE EM MOVIMENTO"
    objective.add_theme_font_size_override("font_size", 9)
    objective.add_theme_color_override("font_color", Color("#6F8588"))
    brand_column.add_child(objective)

    var status_column := VBoxContainer.new()
    status_column.custom_minimum_size = Vector2(454.0, 76.0)
    status_column.add_theme_constant_override("separation", 5)
    top_row.add_child(status_column)

    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 14)
    status_label.custom_minimum_size = Vector2(454.0, 22.0)
    GridFlowUITheme.apply_label(status_label)
    status_column.add_child(status_label)

    resource_label = Label.new()
    resource_label.add_theme_font_size_override("font_size", 11)
    resource_label.custom_minimum_size = Vector2(454.0, 18.0)
    GridFlowUITheme.apply_label(resource_label, true)
    status_column.add_child(resource_label)

    var flow_row := HBoxContainer.new()
    flow_row.add_theme_constant_override("separation", 8)
    status_column.add_child(flow_row)

    var flow_caption := Label.new()
    flow_caption.text = "FLUXO"
    flow_caption.custom_minimum_size = Vector2(45.0, 18.0)
    flow_caption.add_theme_font_size_override("font_size", 10)
    GridFlowUITheme.apply_label(flow_caption, true)
    flow_row.add_child(flow_caption)

    flow_bar = ProgressBar.new()
    flow_bar.min_value = 0.0
    flow_bar.max_value = 100.0
    flow_bar.value = 100.0
    flow_bar.show_percentage = false
    flow_bar.custom_minimum_size = Vector2(397.0, 12.0)
    GridFlowUITheme.apply_progress(flow_bar)
    flow_row.add_child(flow_bar)

    green_button = Button.new()
    green_button.text = "CORREDOR VERDE\nx1"
    green_button.custom_minimum_size = Vector2(118.0, 68.0)
    green_button.add_theme_font_size_override("font_size", 11)
    GridFlowUITheme.apply_button(green_button, true)
    green_button.pressed.connect(simulation.activate_green_corridor)
    top_row.add_child(green_button)

    pause_button = Button.new()
    pause_button.text = "PAUSA"
    pause_button.custom_minimum_size = Vector2(82.0, 68.0)
    pause_button.add_theme_font_size_override("font_size", 11)
    GridFlowUITheme.apply_button(pause_button)
    pause_button.pressed.connect(_toggle_pause)
    top_row.add_child(pause_button)

    speed_button = Button.new()
    speed_button.text = "1x"
    speed_button.custom_minimum_size = Vector2(54.0, 68.0)
    speed_button.add_theme_font_size_override("font_size", 12)
    GridFlowUITheme.apply_button(speed_button)
    speed_button.pressed.connect(_cycle_speed)
    top_row.add_child(speed_button)

    var view_column := VBoxContainer.new()
    view_column.custom_minimum_size = Vector2(116.0, 68.0)
    view_column.add_theme_constant_override("separation", 5)
    top_row.add_child(view_column)

    var zoom_row := HBoxContainer.new()
    zoom_row.add_theme_constant_override("separation", 5)
    view_column.add_child(zoom_row)

    var zoom_out := Button.new()
    zoom_out.text = "−"
    zoom_out.custom_minimum_size = Vector2(54.0, 32.0)
    GridFlowUITheme.apply_button(zoom_out)
    zoom_out.pressed.connect(func(): simulation.zoom_by(0.86))
    zoom_row.add_child(zoom_out)

    var zoom_in := Button.new()
    zoom_in.text = "+"
    zoom_in.custom_minimum_size = Vector2(54.0, 32.0)
    GridFlowUITheme.apply_button(zoom_in)
    zoom_in.pressed.connect(func(): simulation.zoom_by(1.16))
    zoom_row.add_child(zoom_in)

    var reset_view := Button.new()
    reset_view.text = "VER MAPA"
    reset_view.custom_minimum_size = Vector2(113.0, 31.0)
    reset_view.add_theme_font_size_override("font_size", 10)
    GridFlowUITheme.apply_button(reset_view)
    reset_view.pressed.connect(simulation.reset_view)
    view_column.add_child(reset_view)

    var bottom_panel := PanelContainer.new()
    bottom_panel.position = Vector2(16.0, 600.0)
    bottom_panel.size = Vector2(1248.0, 105.0)
    GridFlowUITheme.apply_panel(bottom_panel, Color("#142125"), 16)
    canvas.add_child(bottom_panel)

    var bottom_margin := MarginContainer.new()
    bottom_margin.add_theme_constant_override("margin_left", 12)
    bottom_margin.add_theme_constant_override("margin_right", 12)
    bottom_margin.add_theme_constant_override("margin_top", 10)
    bottom_margin.add_theme_constant_override("margin_bottom", 10)
    bottom_panel.add_child(bottom_margin)

    var bottom_row := HBoxContainer.new()
    bottom_row.add_theme_constant_override("separation", 6)
    bottom_margin.add_child(bottom_row)

    _add_mode_button(bottom_row, "ESTRADA\nx0", "road")
    _add_mode_button(bottom_row, "REMOVER", "erase")
    _add_mode_button(bottom_row, "SEMÁFORO\nx0", "signal")
    _add_mode_button(bottom_row, "ROTUNDA\nx0", "roundabout")
    _add_mode_button(bottom_row, "ALARGAR\nx0", "lanes")
    _add_mode_button(bottom_row, "SENTIDO\nÚNICO", "oneway")
    _add_mode_button(bottom_row, "PONTE\nx0", "bridge")
    _add_mode_button(bottom_row, "MOVER\nMAPA", "pan")

    var separator := VSeparator.new()
    separator.custom_minimum_size = Vector2(8.0, 66.0)
    bottom_row.add_child(separator)

    var help_column := VBoxContainer.new()
    help_column.custom_minimum_size = Vector2(440.0, 70.0)
    help_column.add_theme_constant_override("separation", 1)
    bottom_row.add_child(help_column)

    var tool_caption := Label.new()
    tool_caption.text = "FERRAMENTA ATIVA"
    tool_caption.add_theme_font_size_override("font_size", 9)
    tool_caption.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    help_column.add_child(tool_caption)

    help_label = Label.new()
    help_label.custom_minimum_size = Vector2(440.0, 52.0)
    help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help_label.add_theme_font_size_override("font_size", 11)
    GridFlowUITheme.apply_label(help_label, true)
    help_column.add_child(help_label)

    toast_label = Label.new()
    toast_label.position = Vector2(340.0, 128.0)
    toast_label.size = Vector2(600.0, 38.0)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    toast_label.add_theme_font_size_override("font_size", 15)
    toast_label.add_theme_color_override("font_color", Color("#F6F8F5"))
    toast_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
    toast_label.add_theme_constant_override("shadow_offset_x", 1)
    toast_label.add_theme_constant_override("shadow_offset_y", 2)
    toast_label.modulate.a = 0.0
    canvas.add_child(toast_label)

    _build_upgrade_panel(canvas)
    _build_game_over_panel(canvas)

func _build_upgrade_panel(canvas: CanvasLayer) -> void:
    upgrade_panel = PanelContainer.new()
    upgrade_panel.position = Vector2(365.0, 190.0)
    upgrade_panel.size = Vector2(550.0, 330.0)
    upgrade_panel.visible = false
    GridFlowUITheme.apply_panel(upgrade_panel, Color("#152428"), 18)
    canvas.add_child(upgrade_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 30)
    margin.add_theme_constant_override("margin_right", 30)
    margin.add_theme_constant_override("margin_top", 26)
    margin.add_theme_constant_override("margin_bottom", 26)
    upgrade_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    margin.add_child(column)

    var eyebrow := Label.new()
    eyebrow.text = "PLANEAMENTO DA CIDADE"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 10)
    eyebrow.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    column.add_child(eyebrow)

    var title := Label.new()
    title.text = "MELHORIA SEMANAL"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 27)
    GridFlowUITheme.apply_label(title)
    column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Escolhe um conjunto de recursos para manter Lisboa em movimento."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 12)
    GridFlowUITheme.apply_label(subtitle, true)
    column.add_child(subtitle)

    for index: int in range(2):
        var button := Button.new()
        button.text = "MELHORIA"
        button.custom_minimum_size = Vector2(0.0, 72.0)
        button.add_theme_font_size_override("font_size", 14)
        GridFlowUITheme.apply_button(button, index == 0)
        button.pressed.connect(_choose_upgrade.bind(index))
        column.add_child(button)
        upgrade_buttons.append(button)

func _build_game_over_panel(canvas: CanvasLayer) -> void:
    game_over_panel = PanelContainer.new()
    game_over_panel.position = Vector2(410.0, 225.0)
    game_over_panel.size = Vector2(460.0, 245.0)
    game_over_panel.visible = false
    GridFlowUITheme.apply_panel(game_over_panel, Color("#1D2325"), 18)
    canvas.add_child(game_over_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 30)
    margin.add_theme_constant_override("margin_right", 30)
    margin.add_theme_constant_override("margin_top", 25)
    margin.add_theme_constant_override("margin_bottom", 25)
    game_over_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    margin.add_child(column)

    var title := Label.new()
    title.name = "GameTitle"
    title.text = "COLAPSO DO TRÂNSITO"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", GridFlowUITheme.DANGER)
    column.add_child(title)

    var stats := Label.new()
    stats.name = "GameStats"
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 14)
    GridFlowUITheme.apply_label(stats, true)
    column.add_child(stats)

    var restart := Button.new()
    restart.text = "RECOMEÇAR LISBOA"
    restart.custom_minimum_size = Vector2(0.0, 52.0)
    GridFlowUITheme.apply_button(restart, true)
    restart.pressed.connect(func(): get_tree().reload_current_scene())
    column.add_child(restart)

func _add_mode_button(parent: HBoxContainer, text: String, mode: String) -> void:
    var button := Button.new()
    button.text = text
    button.toggle_mode = true
    button.custom_minimum_size = Vector2(82.0, 70.0)
    button.add_theme_font_size_override("font_size", 10)
    GridFlowUITheme.apply_toggle(button)
    button.pressed.connect(_set_mode.bind(mode))
    parent.add_child(button)
    mode_buttons[mode] = button

func _set_mode(mode: String) -> void:
    simulation.set_mode(mode)
    for raw_mode: Variant in mode_buttons.keys():
        var button: Button = mode_buttons[raw_mode] as Button
        button.button_pressed = String(raw_mode) == mode

    match mode:
        "erase":
            help_label.text = "Arrasta sobre as estradas para as remover. Os recursos instalados são devolvidos."
        "signal":
            help_label.text = "Toca num cruzamento com 3 ou 4 acessos para instalar ou retirar um semáforo."
        "roundabout":
            help_label.text = "Toca num cruzamento com 3 ou 4 acessos. A rotunda aumenta o fluxo e os veículos cedem à entrada."
        "lanes":
            help_label.text = "Toca numa estrada para a alargar de 1 para 2 e depois 3 vias."
        "oneway":
            help_label.text = "Toca repetidamente numa estrada para escolher o sentido único ou voltar a dois sentidos."
        "bridge":
            help_label.text = "Toca numa célula do Tejo para construir uma travessia. Cada travessia consome uma ponte."
        "pan":
            help_label.text = "Arrasta para mover o mapa. Usa +/−, a roda do rato ou o gesto de pinça para ampliar."
        _:
            help_label.text = "Arrasta entre pontos para construir estradas. As casas ligam-se automaticamente à estrada adjacente."

func _toggle_pause() -> void:
    simulation.set_paused(not simulation.paused)
    pause_button.text = "RETOMAR" if simulation.paused else "PAUSA"

func _cycle_speed() -> void:
    simulation.cycle_speed()
    speed_button.text = "%dx" % int(simulation.time_scale)

func _on_hud_updated(snapshot: Dictionary) -> void:
    if status_label == null:
        return

    var rush_text: String = "  •  HORA DE PONTA" if bool(snapshot.rush) else ""
    status_label.text = "%s%s  •  SEMANA %d  •  POP. %s" % [
        String(snapshot.time),
        rush_text,
        int(snapshot.week),
        _compact_number(int(snapshot.population))
    ]

    resource_label.text = "VIAGENS %d   VEÍCULOS %d   PENDENTES %d   EMERGÊNCIAS %d" % [
        int(snapshot.trips),
        int(snapshot.vehicles),
        int(snapshot.pending),
        int(snapshot.emergency_active)
    ]

    var flow: int = int(snapshot.flow)
    flow_bar.value = float(flow)
    _update_flow_bar_style(flow)
    speed_button.text = "%dx" % int(snapshot.speed)
    pause_button.text = "RETOMAR" if bool(snapshot.paused) else "PAUSA"
    pause_button.disabled = bool(snapshot.upgrade_pending)

    green_button.text = "CORREDOR VERDE\nx%d" % int(snapshot.green)
    green_button.disabled = int(snapshot.green) <= 0 or int(snapshot.emergency_active) <= 0 or bool(snapshot.upgrade_pending)

    _update_item_buttons(snapshot)

func _update_item_buttons(snapshot: Dictionary) -> void:
    (mode_buttons["road"] as Button).text = "ESTRADA\nx%d" % int(snapshot.roads)
    (mode_buttons["signal"] as Button).text = "SEMÁFORO\nx%d" % int(snapshot.signals)
    (mode_buttons["roundabout"] as Button).text = "ROTUNDA\nx%d" % int(snapshot.roundabouts)
    (mode_buttons["lanes"] as Button).text = "ALARGAR\nx%d" % int(snapshot.lane_upgrades)
    (mode_buttons["bridge"] as Button).text = "PONTE\nx%d" % int(snapshot.bridges)

func _compact_number(value: int) -> String:
    if value >= 1000000:
        return "%.1fM" % (float(value) / 1000000.0)
    if value >= 1000:
        return "%.1fK" % (float(value) / 1000.0)
    return str(value)

func _update_flow_bar_style(flow: int) -> void:
    var color := GridFlowUITheme.ACCENT
    if flow < 30:
        color = GridFlowUITheme.DANGER
    elif flow < 65:
        color = GridFlowUITheme.WARNING

    var fill := StyleBoxFlat.new()
    fill.bg_color = color
    fill.corner_radius_top_left = 6
    fill.corner_radius_top_right = 6
    fill.corner_radius_bottom_left = 6
    fill.corner_radius_bottom_right = 6
    flow_bar.add_theme_stylebox_override("fill", fill)

func _show_toast(message: String) -> void:
    toast_label.text = message
    if _toast_tween != null and _toast_tween.is_valid():
        _toast_tween.kill()
    toast_label.modulate.a = 1.0
    _toast_tween = create_tween()
    _toast_tween.tween_interval(1.35)
    _toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)

func _on_upgrade_requested(options: Array[Dictionary]) -> void:
    if options.size() < 2:
        return
    for index: int in range(2):
        var option: Dictionary = options[index]
        _upgrade_ids[index] = String(option.get("id", "roads"))
        upgrade_buttons[index].text = "%s\n%s" % [
            String(option.get("title", "MELHORIA")),
            String(option.get("detail", ""))
        ]
    upgrade_panel.visible = true

func _choose_upgrade(index: int) -> void:
    if index < 0 or index >= _upgrade_ids.size():
        return
    upgrade_panel.visible = false
    simulation.apply_upgrade(_upgrade_ids[index])

func _on_game_over(snapshot: Dictionary) -> void:
    upgrade_panel.visible = false
    game_over_panel.visible = true
    var stats: Label = game_over_panel.find_child("GameStats", true, false) as Label
    stats.text = "População %s  •  Viagens %d  •  Emergências %d\nSemana %d  •  Pontuação final %d" % [
        _compact_number(int(snapshot.population)),
        int(snapshot.trips),
        int(snapshot.emergency_completed),
        int(snapshot.week),
        int(snapshot.score)
    ]
