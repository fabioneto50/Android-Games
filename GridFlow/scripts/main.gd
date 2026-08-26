extends Node

var simulation: CitySimulation
var status_label: Label
var help_label: Label
var toast_label: Label
var speed_button: Button
var pause_button: Button
var mode_buttons: Dictionary = {}
var game_over_panel: PanelContainer
var _toast_tween: Tween

func _ready() -> void:
    simulation = CitySimulation.new()
    add_child(simulation)
    _build_interface()

    simulation.hud_updated.connect(_on_hud_updated)
    simulation.toast_requested.connect(_show_toast)
    simulation.game_over.connect(_on_game_over)

    _set_mode("road")
    _on_hud_updated(simulation.get_snapshot())

func _build_interface() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)

    var top_panel := PanelContainer.new()
    top_panel.position = Vector2(16.0, 14.0)
    top_panel.size = Vector2(1248.0, 66.0)
    canvas.add_child(top_panel)

    var top_margin := MarginContainer.new()
    top_margin.add_theme_constant_override("margin_left", 14)
    top_margin.add_theme_constant_override("margin_right", 14)
    top_margin.add_theme_constant_override("margin_top", 8)
    top_margin.add_theme_constant_override("margin_bottom", 8)
    top_panel.add_child(top_margin)

    var top_row := HBoxContainer.new()
    top_row.add_theme_constant_override("separation", 10)
    top_margin.add_child(top_row)

    var title := Label.new()
    title.text = "GRIDFLOW  /  LISBON PROTOTYPE"
    title.add_theme_font_size_override("font_size", 18)
    title.custom_minimum_size = Vector2(250.0, 44.0)
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    top_row.add_child(title)

    status_label = Label.new()
    status_label.custom_minimum_size = Vector2(700.0, 44.0)
    status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 16)
    top_row.add_child(status_label)

    pause_button = Button.new()
    pause_button.text = "PAUSE"
    pause_button.custom_minimum_size = Vector2(90.0, 44.0)
    pause_button.pressed.connect(_toggle_pause)
    top_row.add_child(pause_button)

    speed_button = Button.new()
    speed_button.text = "1x"
    speed_button.custom_minimum_size = Vector2(70.0, 44.0)
    speed_button.pressed.connect(_cycle_speed)
    top_row.add_child(speed_button)

    var bottom_panel := PanelContainer.new()
    bottom_panel.position = Vector2(16.0, 640.0)
    bottom_panel.size = Vector2(1248.0, 64.0)
    canvas.add_child(bottom_panel)

    var bottom_margin := MarginContainer.new()
    bottom_margin.add_theme_constant_override("margin_left", 12)
    bottom_margin.add_theme_constant_override("margin_right", 12)
    bottom_margin.add_theme_constant_override("margin_top", 8)
    bottom_margin.add_theme_constant_override("margin_bottom", 8)
    bottom_panel.add_child(bottom_margin)

    var bottom_row := HBoxContainer.new()
    bottom_row.add_theme_constant_override("separation", 8)
    bottom_margin.add_child(bottom_row)

    _add_mode_button(bottom_row, "ROAD", "road")
    _add_mode_button(bottom_row, "ERASE", "erase")
    _add_mode_button(bottom_row, "SIGNALS", "signal")

    help_label = Label.new()
    help_label.custom_minimum_size = Vector2(760.0, 44.0)
    help_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    help_label.text = "Drag to build roads. Connect every new zone before demand overwhelms the network."
    bottom_row.add_child(help_label)

    toast_label = Label.new()
    toast_label.position = Vector2(390.0, 96.0)
    toast_label.size = Vector2(500.0, 42.0)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    toast_label.add_theme_font_size_override("font_size", 18)
    toast_label.modulate.a = 0.0
    canvas.add_child(toast_label)

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
    button.custom_minimum_size = Vector2(110.0, 44.0)
    button.pressed.connect(func(): _set_mode(mode))
    parent.add_child(button)
    mode_buttons[mode] = button

func _set_mode(mode: String) -> void:
    simulation.set_mode(mode)
    for raw_mode in mode_buttons.keys():
        var button: Button = mode_buttons[raw_mode]
        button.button_pressed = raw_mode == mode

    match mode:
        "erase":
            help_label.text = "Drag over roads to remove them. Removed road segments are refunded."
        "signal":
            help_label.text = "Tap a 3-way or 4-way junction to install or remove a traffic signal."
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
    status_label.text = "FLOW %d%%   WEEK %d   ROADS %d   POP %d   CARS %d   TRIPS %d   SCORE %d" % [
        snapshot.flow,
        snapshot.week,
        snapshot.roads,
        snapshot.population,
        snapshot.vehicles,
        snapshot.trips,
        snapshot.score
    ]
    speed_button.text = "%dx" % snapshot.speed
    pause_button.text = "RESUME" if snapshot.paused else "PAUSE"

func _show_toast(message: String) -> void:
    toast_label.text = message
    if _toast_tween != null and _toast_tween.is_valid():
        _toast_tween.kill()
    toast_label.modulate.a = 1.0
    _toast_tween = create_tween()
    _toast_tween.tween_interval(1.25)
    _toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.45)

func _on_game_over(snapshot: Dictionary) -> void:
    game_over_panel.visible = true
    var stats: Label = game_over_panel.find_child("GameStats", true, false)
    stats.text = "Population %d  |  Trips %d  |  Week %d\nFinal score: %d" % [
        snapshot.population,
        snapshot.trips,
        snapshot.week,
        snapshot.score
    ]
