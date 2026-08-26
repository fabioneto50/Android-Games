extends "res://scripts/main_pt.gd"
class_name GridFlowMainPremium

var flow_value_label: Label
var hud_canvas: CanvasLayer

func _ready() -> void:
    simulation = CitySimulationPT.new()
    add_child(simulation)
    city_overlay = CityVisualOverlayPremium.new(simulation)
    simulation.add_child(city_overlay)
    _build_interface()

    simulation.hud_updated.connect(_on_hud_updated)
    simulation.toast_requested.connect(_show_toast)
    simulation.game_over.connect(_on_game_over)
    simulation.upgrade_requested.connect(_on_upgrade_requested)

    _set_mode("road")
    _on_hud_updated(simulation.get_snapshot())

func _build_interface() -> void:
    hud_canvas = CanvasLayer.new()
    hud_canvas.layer = 35
    add_child(hud_canvas)

    _build_brand_card()
    _build_status_card()
    _build_control_card()
    _build_view_card()
    _build_help_card()
    _build_tool_dock()
    _build_toast()
    _build_upgrade_panel(hud_canvas)
    _build_game_over_panel(hud_canvas)

func _build_brand_card() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(16.0, 16.0)
    panel.size = Vector2(222.0, 78.0)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.045, 0.095, 0.105, 0.94), 18, GridFlowUITheme.ACCENT.darkened(0.45)))
    hud_canvas.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 9)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", -1)
    margin.add_child(column)

    var title := Label.new()
    title.text = "GRIDFLOW"
    title.add_theme_font_size_override("font_size", 26)
    title.add_theme_color_override("font_color", Color("#ECF8F1"))
    column.add_child(title)

    var city := Label.new()
    city.text = "LISBOA  /  REDE ATIVA"
    city.add_theme_font_size_override("font_size", 10)
    city.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    column.add_child(city)

    var line := HSeparator.new()
    line.custom_minimum_size = Vector2(0.0, 6.0)
    column.add_child(line)

    var mission := Label.new()
    mission.text = "MANTÉM A CIDADE EM MOVIMENTO"
    mission.add_theme_font_size_override("font_size", 9)
    mission.add_theme_color_override("font_color", Color("#829997"))
    column.add_child(mission)

func _build_status_card() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(252.0, 16.0)
    panel.size = Vector2(620.0, 78.0)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.055, 0.10, 0.11, 0.94), 18, Color("#294147")))
    hud_canvas.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_top", 10)
    margin.add_theme_constant_override("margin_bottom", 9)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 3)
    margin.add_child(column)

    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 12)
    column.add_child(top)

    status_label = Label.new()
    status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_label.add_theme_font_size_override("font_size", 14)
    status_label.add_theme_color_override("font_color", Color("#F1F5F2"))
    top.add_child(status_label)

    flow_value_label = Label.new()
    flow_value_label.text = "100%"
    flow_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    flow_value_label.custom_minimum_size = Vector2(62.0, 20.0)
    flow_value_label.add_theme_font_size_override("font_size", 14)
    flow_value_label.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    top.add_child(flow_value_label)

    resource_label = Label.new()
    resource_label.add_theme_font_size_override("font_size", 10)
    resource_label.add_theme_color_override("font_color", Color("#8FA5A3"))
    column.add_child(resource_label)

    var flow_row := HBoxContainer.new()
    flow_row.add_theme_constant_override("separation", 8)
    column.add_child(flow_row)

    var flow_caption := Label.new()
    flow_caption.text = "FLUXO"
    flow_caption.custom_minimum_size = Vector2(44.0, 12.0)
    flow_caption.add_theme_font_size_override("font_size", 9)
    flow_caption.add_theme_color_override("font_color", Color("#7E9694"))
    flow_row.add_child(flow_caption)

    flow_bar = ProgressBar.new()
    flow_bar.min_value = 0.0
    flow_bar.max_value = 100.0
    flow_bar.value = 100.0
    flow_bar.show_percentage = false
    flow_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    flow_bar.custom_minimum_size = Vector2(0.0, 9.0)
    GridFlowUITheme.apply_progress(flow_bar)
    flow_row.add_child(flow_bar)

func _build_control_card() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(886.0, 16.0)
    panel.size = Vector2(378.0, 78.0)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.045, 0.085, 0.095, 0.95), 18, Color("#294147")))
    hud_canvas.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 9)
    margin.add_theme_constant_override("margin_bottom", 9)
    panel.add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 7)
    margin.add_child(row)

    green_button = Button.new()
    green_button.text = "CORREDOR VERDE\nx1"
    green_button.custom_minimum_size = Vector2(126.0, 58.0)
    green_button.add_theme_font_size_override("font_size", 10)
    GridFlowUITheme.apply_button(green_button, true)
    green_button.pressed.connect(simulation.activate_green_corridor)
    row.add_child(green_button)

    pause_button = Button.new()
    pause_button.text = "PAUSA"
    pause_button.custom_minimum_size = Vector2(82.0, 58.0)
    pause_button.add_theme_font_size_override("font_size", 10)
    GridFlowUITheme.apply_button(pause_button)
    pause_button.pressed.connect(_toggle_pause)
    row.add_child(pause_button)

    speed_button = Button.new()
    speed_button.text = "1x"
    speed_button.custom_minimum_size = Vector2(54.0, 58.0)
    speed_button.add_theme_font_size_override("font_size", 12)
    GridFlowUITheme.apply_button(speed_button)
    speed_button.pressed.connect(_cycle_speed)
    row.add_child(speed_button)

    var fit := Button.new()
    fit.text = "CENTRAR"
    fit.custom_minimum_size = Vector2(78.0, 58.0)
    fit.add_theme_font_size_override("font_size", 9)
    GridFlowUITheme.apply_button(fit)
    fit.pressed.connect(simulation.reset_view)
    row.add_child(fit)

func _build_view_card() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(18.0, 112.0)
    panel.size = Vector2(54.0, 116.0)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.05, 0.09, 0.10, 0.88), 15, Color("#294147")))
    hud_canvas.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 7)
    margin.add_theme_constant_override("margin_right", 7)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 5)
    margin.add_child(column)

    var zoom_in := Button.new()
    zoom_in.text = "+"
    zoom_in.custom_minimum_size = Vector2(40.0, 44.0)
    zoom_in.add_theme_font_size_override("font_size", 18)
    GridFlowUITheme.apply_button(zoom_in)
    zoom_in.pressed.connect(func(): simulation.zoom_by(1.16))
    column.add_child(zoom_in)

    var zoom_out := Button.new()
    zoom_out.text = "−"
    zoom_out.custom_minimum_size = Vector2(40.0, 44.0)
    zoom_out.add_theme_font_size_override("font_size", 18)
    GridFlowUITheme.apply_button(zoom_out)
    zoom_out.pressed.connect(func(): simulation.zoom_by(0.86))
    column.add_child(zoom_out)

func _build_help_card() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(18.0, 530.0)
    panel.size = Vector2(344.0, 76.0)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.045, 0.085, 0.095, 0.90), 16, Color("#294147")))
    hud_canvas.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 13)
    margin.add_theme_constant_override("margin_right", 13)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 1)
    margin.add_child(column)

    var caption := Label.new()
    caption.text = "FERRAMENTA ATIVA"
    caption.add_theme_font_size_override("font_size", 8)
    caption.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    column.add_child(caption)

    help_label = Label.new()
    help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help_label.custom_minimum_size = Vector2(316.0, 48.0)
    help_label.add_theme_font_size_override("font_size", 10)
    help_label.add_theme_color_override("font_color", Color("#B1C1BE"))
    column.add_child(help_label)

func _build_tool_dock() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(158.0, 626.0)
    panel.size = Vector2(964.0, 78.0)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.035, 0.075, 0.083, 0.97), 19, Color("#2A474A")))
    hud_canvas.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 7)
    margin.add_theme_constant_override("margin_bottom", 7)
    panel.add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    margin.add_child(row)

    _add_premium_mode_button(row, "ESTRADA\nx0", "road")
    _add_premium_mode_button(row, "REMOVER", "erase")
    _add_premium_mode_button(row, "SEMÁFORO\nx0", "signal")
    _add_premium_mode_button(row, "ROTUNDA\nx0", "roundabout")
    _add_premium_mode_button(row, "ALARGAR\nx0", "lanes")
    _add_premium_mode_button(row, "SENTIDO\nÚNICO", "oneway")
    _add_premium_mode_button(row, "PONTE\nx0", "bridge")
    _add_premium_mode_button(row, "MOVER\nMAPA", "pan")

func _add_premium_mode_button(parent: HBoxContainer, text: String, mode: String) -> void:
    var button := Button.new()
    button.text = text
    button.toggle_mode = true
    button.custom_minimum_size = Vector2(111.0, 62.0)
    button.add_theme_font_size_override("font_size", 9)
    GridFlowUITheme.apply_toggle(button)
    button.pressed.connect(_set_mode.bind(mode))
    parent.add_child(button)
    mode_buttons[mode] = button

func _build_toast() -> void:
    toast_label = Label.new()
    toast_label.position = Vector2(360.0, 110.0)
    toast_label.size = Vector2(560.0, 38.0)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    toast_label.add_theme_font_size_override("font_size", 13)
    toast_label.add_theme_color_override("font_color", Color("#F3F7F3"))
    toast_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.80))
    toast_label.add_theme_constant_override("shadow_offset_x", 1)
    toast_label.add_theme_constant_override("shadow_offset_y", 2)
    toast_label.modulate.a = 0.0
    hud_canvas.add_child(toast_label)

func _build_upgrade_panel(canvas: CanvasLayer) -> void:
    upgrade_panel = PanelContainer.new()
    upgrade_panel.position = Vector2(350.0, 176.0)
    upgrade_panel.size = Vector2(580.0, 360.0)
    upgrade_panel.visible = false
    upgrade_panel.add_theme_stylebox_override("panel", _glass_style(Color(0.045, 0.09, 0.10, 0.985), 24, GridFlowUITheme.ACCENT.darkened(0.30)))
    canvas.add_child(upgrade_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_top", 28)
    margin.add_theme_constant_override("margin_bottom", 28)
    upgrade_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    margin.add_child(column)

    var eyebrow := Label.new()
    eyebrow.text = "PLANEAMENTO URBANO  /  NOVA SEMANA"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 9)
    eyebrow.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    column.add_child(eyebrow)

    var title := Label.new()
    title.text = "ESCOLHE A PRÓXIMA MELHORIA"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 24)
    title.add_theme_color_override("font_color", Color("#F2F6F3"))
    column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "A cidade cresceu. Reforça a rede antes da próxima vaga de procura."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 11)
    subtitle.add_theme_color_override("font_color", Color("#8EA5A2"))
    column.add_child(subtitle)

    for index: int in range(2):
        var button := Button.new()
        button.text = "MELHORIA"
        button.custom_minimum_size = Vector2(0.0, 82.0)
        button.add_theme_font_size_override("font_size", 13)
        GridFlowUITheme.apply_button(button, index == 0)
        button.pressed.connect(_choose_upgrade.bind(index))
        column.add_child(button)
        upgrade_buttons.append(button)

func _build_game_over_panel(canvas: CanvasLayer) -> void:
    game_over_panel = PanelContainer.new()
    game_over_panel.position = Vector2(398.0, 205.0)
    game_over_panel.size = Vector2(484.0, 285.0)
    game_over_panel.visible = false
    game_over_panel.add_theme_stylebox_override("panel", _glass_style(Color(0.07, 0.08, 0.085, 0.985), 24, GridFlowUITheme.DANGER.darkened(0.35)))
    canvas.add_child(game_over_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_top", 28)
    margin.add_theme_constant_override("margin_bottom", 28)
    game_over_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    margin.add_child(column)

    var eyebrow := Label.new()
    eyebrow.text = "REDE SATURADA"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 9)
    eyebrow.add_theme_color_override("font_color", GridFlowUITheme.DANGER)
    column.add_child(eyebrow)

    var title := Label.new()
    title.name = "GameTitle"
    title.text = "LISBOA PAROU"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 31)
    title.add_theme_color_override("font_color", Color("#F6EEEE"))
    column.add_child(title)

    var stats := Label.new()
    stats.name = "GameStats"
    stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stats.add_theme_font_size_override("font_size", 13)
    stats.add_theme_color_override("font_color", Color("#B7C3C1"))
    column.add_child(stats)

    var restart := Button.new()
    restart.text = "RECOMEÇAR LISBOA"
    restart.custom_minimum_size = Vector2(0.0, 54.0)
    GridFlowUITheme.apply_button(restart, true)
    restart.pressed.connect(func(): get_tree().reload_current_scene())
    column.add_child(restart)

func _on_hud_updated(snapshot: Dictionary) -> void:
    super._on_hud_updated(snapshot)
    if flow_value_label != null:
        var flow: int = int(snapshot.flow)
        flow_value_label.text = "%d%%" % flow
        var color := GridFlowUITheme.ACCENT
        if flow < 30:
            color = GridFlowUITheme.DANGER
        elif flow < 65:
            color = GridFlowUITheme.WARNING
        flow_value_label.add_theme_color_override("font_color", color)

func _glass_style(background: Color, radius: int, border_color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border_color
    style.set_border_width_all(1)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
    style.shadow_size = 12
    style.shadow_offset = Vector2(0.0, 5.0)
    return style
