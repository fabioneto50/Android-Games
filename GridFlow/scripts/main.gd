extends Node

var simulation: CitySimulation
var status_label: Label
var help_label: Label
var toast_label: Label
var speed_button: Button
var pause_button: Button
var flow_bar: ProgressBar
var mode_buttons: Dictionary = {}
var game_over_panel: PanelContainer
var upgrade_panel: PanelContainer
var upgrade_buttons: Array[Button] = []
var _upgrade_ids: Array[String] = ["", ""]
var _toast_tween: Tween

func _ready() -> void:
    simulation = CitySimulation.new()
    add_child(simulation)
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
    top_panel.size = Vector2(1248.0, 72.0)
    canvas.add_child(top_panel)

    var top_margin := MarginContainer.new()
    top_margin.add_theme_constant_override("margin_left", 12)
    top_margin.add_theme_constant_override("margin_right", 12)
    top_margin.add_theme_constant_override("margin_top", 8)
    top_margin.add_theme_constant_override("margin_bottom", 8)
    top_panel.add_child(top_margin)

    var top_row := HBoxContainer.new()
    top_row.add_theme_constant_override("separation", 8)
    top_margin.add_child(top_row)

    var title := Label.new()
    title.text = "GRIDFLOW / LISBON"
    title.add_theme_font_size_override("font_size", 17)
    title.custom_minimum_size = Vector2(176.0, 48.0)
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    top_row.add_child(title)

    var status_column := VBoxContainer.new()
    status_column.custom_minimum_size = Vector2(604.0, 48.0)
    status_column.add_theme_constant_override("separation", 2)
    top_row.add_child(status_column)

    status_label = Label.new()
    status_label.add_theme_font_size_override("font_size", 13)
    status_label.custom_minimum_size = Vector2(604.0, 24.0)
    status_column.add_child(status_label)

    flow_bar = ProgressBar.new()
    flow_bar.min_value = 0.0
    flow_bar.max_value = 100.0
    flow_bar.value = 100.0
    flow_bar.show_percentage = false
    flow_bar.custom_minimum_size = Vector2(604.0, 12.0)
    status_column.add_child(flow_bar)

    pause_button = Button.new()
    pause_button.text = "PAUSE"
    pause_button.custom_minimum_size = Vector2(82.0, 48.0)
    pause_button.pressed.connect(_toggle_pause)
    top_row.add_child(pause_button)

    speed_button = Button.new()
    speed_button.text = "1x"
    speed_button.custom_minimum_size = Vector2(54.0, 48.0)
    speed_button.pressed.connect(_cycle_speed)
    top_row.add_child(speed_button)

    var zoom_out := Button.new()
    zoom_out.text = "−"
    zoom_out.custom_minimum_size = Vector2(48.0, 48.0)
    zoom_out.pressed.connect(func(): simulation.zoom_by(0.86))
    top_row.add_child(zoom_out)

    var zoom_in := Button.new()
    zoom_in.text = "+"
    zoom_in.custom_minimum_size = Vector2(48.0, 48.0)
    zoom_in.pressed.connect(func(): simulation.zoom_by(1.16))
    top_row.add_child(zoom_in)

    var reset_view := Button.new()
    reset_view.text = "FIT"
    reset_view.custom_minimum_size = Vector2(62.0, 48.0)
    reset_view.pressed.connect(simulation.reset_view)
    top_row.add_child(reset_view)

    var bottom_panel := PanelContainer.new()
    bottom_panel.position = Vector2(16.0, 622.0)
    bottom_panel.size = Vector2(1248.0, 82.0)
    canvas.add_child(bottom_panel)

    var bottom_margin := MarginContainer.new()
    bottom_margin.add_theme_constant_override("margin_left", 10)
    bottom_margin.add_theme_constant_override("margin_right", 10)
    bottom_margin.add_theme_constant_override("margin_top", 8)
    bottom_margin.add_theme_constant_override("margin_bottom", 8)
    bottom_panel.add_child(bottom_margin)

    var bottom_row := HBoxContainer.new()
    bottom_row.add_theme_constant_override("separation", 5)
    bottom_margin.add_child(bottom_row)

    _add_mode_button(bottom_row, "ROAD", "road")
    _add_mode_button(bottom_row, "ERASE", "erase")
    _add_mode_button(bottom_row, "LIGHT", "signal")
    _add_mode_button(bottom_row, "ROUND", "roundabout")
    _add_mode_button(bottom_row, "LANES", "lanes")
    _add_mode_button(bottom_row, "1-WAY", "oneway")
    _add_mode_button(bottom_row, "BRIDGE", "bridge")
    _add_mode_button(bottom_row, "PAN", "pan")

    help_label = Label.new()
    help_label.custom_minimum_size = Vector2(565.0, 56.0)
    help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help_label.add_theme_font_size_override("font_size", 12)
    bottom_row.add_child(help_label)

    toast_label = Label.new()
    toast_label.position = Vector2(340.0, 98.0)
    toast_label.size = Vector2(600.0, 42.0)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    toast_label.add_theme_font_size_override("font_size", 18)
    toast_label.modulate.a = 0.0
    canvas.add_child(toast_label)

    _build_upgrade_panel(canvas)
    _build_game_over_panel(canvas)

func _build_upgrade_panel(canvas: CanvasLayer) -> void:
    upgrade_panel = PanelContainer.new()
    upgrade_panel.position = Vector2(380.0, 208.0)
    upgrade_panel.size = Vector2(520.0, 300.0)
    upgrade_panel.visible = false
    canvas.add_child(upgrade_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    upgrade_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 14)
    margin.add_child(column)

    var title := Label.new()
    title.text = "WEEKLY CITY UPGRADE"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 24)
    column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Choose one resource package. The simulation is paused."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 14)
    column.add_child(subtitle)

    for index: int in range(2):
        var button := Button.new()
        button.text = "UPGRADE"
        button.custom_minimum_size = Vector2(0.0, 72.0)
        button.add_theme_font_size_override("font_size", 16)
        button.pressed.connect(_choose_upgrade.bind(index))
        column.add_child(button)
        upgrade_buttons.append(button)

func _build_game_over_panel(canvas: CanvasLayer) -> void:
    game_over_panel = PanelContainer.new()
    game_over_panel.position = Vector2(420.0, 240.0)
    game_over_panel.size = Vector2(440.0, 220.0)
    game_over_panel.visible = false
    canvas.add_child(game_over_panel)

    var game_margin := MarginContainer.new()
    game_margin.add_theme_constant_override("margin_left", 28)
    game_margin.add_theme_constant_override("margin_right", 28)
    game_margin.add_theme_constant_override("margin_top", 22)
    game_margin.add_theme_constant_override("margin_bottom", 22)
    game_over_panel.add_child(game_margin)

    var game_column := VBoxContainer.new()
    game_column.add_theme_constant_override("separation", 12)
    game_margin.add_child(game_column)

    var game_title := Label.new()
    game_title.name = "GameTitle"
    game_title.text = "CITY GRIDLOCK"
    game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_title.add_theme_font_size_override("font_size", 28)
    game_column.add_child(game_title)

    var game_stats := Label.new()
    game_stats.name = "GameStats"
    game_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    game_stats.add_theme_font_size_override("font_size", 17)
    game_column.add_child(game_stats)

    var restart := Button.new()
    restart.text = "RESTART CITY"
    restart.custom_minimum_size = Vector2(0.0, 48.0)
    restart.pressed.connect(func(): get_tree().reload_current_scene())
    game_column.add_child(restart)

func _add_mode_button(parent: HBoxContainer, text: String, mode: String) -> void:
    var button := Button.new()
    button.text = text
    button.toggle_mode = true
    button.custom_minimum_size = Vector2(77.0, 56.0)
    button.add_theme_font_size_override("font_size", 12)
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
            help_label.text = "Drag over roads to remove them. Roads and installed upgrades are refunded."
        "signal":
            help_label.text = "Tap a 3/4-way junction to install a signal. Signals alternate N/S and E/W flow."
        "roundabout":
            help_label.text = "Tap a 3/4-way junction to install a roundabout and increase junction capacity."
        "lanes":
            help_label.text = "Tap a road to widen it from 1 to 2 to 3 lanes. Wider roads carry more traffic."
        "oneway":
            help_label.text = "Tap repeatedly to cycle valid one-way directions; the routing engine respects them."
        "bridge":
            help_label.text = "Tap a water cell on the Tagus to create a crossing. Each crossing consumes one bridge."
        "pan":
            help_label.text = "Drag the map to move around. Use +/− or the mouse wheel/pinch gesture to zoom."
        _:
            help_label.text = "Drag to build roads. Connect every new zone before demand overwhelms the network."

func _toggle_pause() -> void:
    simulation.set_paused(not simulation.paused)
    pause_button.text = "RESUME" if simulation.paused else "PAUSE"

func _cycle_speed() -> void:
    simulation.cycle_speed()
    speed_button.text = "%dx" % int(simulation.time_scale)

func _on_hud_updated(snapshot: Dictionary) -> void:
    if status_label == null:
        return

    var rush_text: String = " RUSH" if bool(snapshot.rush) else ""
    status_label.text = "%s%s  FLOW %d%%  W%d  ROAD %d  SIG %d  RBT %d  BRG %d  LANE %d  POP %d" % [
        String(snapshot.time),
        rush_text,
        int(snapshot.flow),
        int(snapshot.week),
        int(snapshot.roads),
        int(snapshot.signals),
        int(snapshot.roundabouts),
        int(snapshot.bridges),
        int(snapshot.lane_upgrades),
        int(snapshot.population)
    ]
    flow_bar.value = float(snapshot.flow)
    speed_button.text = "%dx" % int(snapshot.speed)
    pause_button.text = "RESUME" if bool(snapshot.paused) else "PAUSE"
    pause_button.disabled = bool(snapshot.upgrade_pending)

func _show_toast(message: String) -> void:
    toast_label.text = message
    if _toast_tween != null and _toast_tween.is_valid():
        _toast_tween.kill()
    toast_label.modulate.a = 1.0
    _toast_tween = create_tween()
    _toast_tween.tween_interval(1.25)
    _toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.45)

func _on_upgrade_requested(options: Array[Dictionary]) -> void:
    if options.size() < 2:
        return

    for index: int in range(2):
        var option: Dictionary = options[index]
        _upgrade_ids[index] = String(option.get("id", "roads"))
        var title: String = String(option.get("title", "UPGRADE"))
        var detail: String = String(option.get("detail", ""))
        upgrade_buttons[index].text = "%s\n%s" % [title, detail]

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
    stats.text = "Population %d  |  Trips %d  |  Week %d\nFinal score: %d" % [
        int(snapshot.population),
        int(snapshot.trips),
        int(snapshot.week),
        int(snapshot.score)
    ]
