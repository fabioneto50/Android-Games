extends GridFlowMainEconomy
class_name GridFlowMainGameplay

var score_label: Label

func _ready() -> void:
    simulation = CitySimulationGameplay.new()
    add_child(simulation)
    city_overlay = CityVisualOverlayPremium.new(simulation)
    simulation.add_child(city_overlay)
    _build_interface()

    simulation.hud_updated.connect(_on_hud_updated)
    simulation.toast_requested.connect(_show_toast)
    simulation.game_over.connect(_on_game_over)
    simulation.upgrade_requested.connect(_on_upgrade_requested)
    (simulation as CitySimulationGameplay).building_selected.connect(_open_building_panel)

    _set_mode("road")
    _on_hud_updated(simulation.get_snapshot())

# Replace the economy card with a clearer progress card: score and coins are
# both always visible instead of the score being hidden in the snapshot only.
func _build_economy_card() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(84.0, 112.0)
    panel.size = Vector2(184.0, 154.0)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.05, 0.10, 0.105, 0.96), 16, Color("#3D5B58")))
    hud_canvas.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 11)
    margin.add_theme_constant_override("margin_right", 11)
    margin.add_theme_constant_override("margin_top", 9)
    margin.add_theme_constant_override("margin_bottom", 9)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 5)
    margin.add_child(column)

    var caption := Label.new()
    caption.text = "PROGRESSO"
    caption.add_theme_font_size_override("font_size", 8)
    caption.add_theme_color_override("font_color", Color("#75918D"))
    column.add_child(caption)

    score_label = Label.new()
    score_label.text = "★ 0 PONTOS"
    score_label.add_theme_font_size_override("font_size", 15)
    score_label.add_theme_color_override("font_color", Color("#F4F7F3"))
    column.add_child(score_label)

    coin_label = Label.new()
    coin_label.text = "◈ 30 MOEDAS"
    coin_label.add_theme_font_size_override("font_size", 13)
    coin_label.add_theme_color_override("font_color", Color("#F1CF72"))
    column.add_child(coin_label)

    var hint := Label.new()
    hint.text = "TOCA NUM EDIFÍCIO PARA EVOLUIR"
    hint.add_theme_font_size_override("font_size", 7)
    hint.add_theme_color_override("font_color", Color("#86A09C"))
    column.add_child(hint)

    var shop := Button.new()
    shop.text = "ABRIR LOJA"
    shop.custom_minimum_size = Vector2(0.0, 42.0)
    shop.add_theme_font_size_override("font_size", 9)
    GridFlowUITheme.apply_button(shop, true)
    shop.pressed.connect(_open_shop)
    column.add_child(shop)

func _on_hud_updated(snapshot: Dictionary) -> void:
    super._on_hud_updated(snapshot)
    if score_label != null:
        score_label.text = "★ %d PONTOS" % int(snapshot.get("score", 0))

func _open_building_panel(cell: Vector2i) -> void:
    super._open_building_panel(cell)
    if building_panel != null and building_panel.visible:
        _show_toast("Edifício selecionado  •  escolhe a evolução")

func _close_building_panel() -> void:
    super._close_building_panel()
    var gameplay := simulation as CitySimulationGameplay
    if gameplay != null:
        gameplay.clear_building_selection()
