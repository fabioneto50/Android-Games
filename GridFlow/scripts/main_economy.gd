extends GridFlowMainPremium
class_name GridFlowMainEconomy

var coin_label: Label
var shop_panel: PanelContainer
var shop_level_label: Label
var shop_upgrade_button: Button
var shop_buttons: Dictionary = {}
var building_panel: PanelContainer
var building_title: Label
var building_info: Label
var building_upgrade_button: Button
var selected_building_cell := Vector2i(-999, -999)
var _pause_before_modal: bool = false

func _ready() -> void:
    simulation = CitySimulationEconomy.new()
    add_child(simulation)
    city_overlay = CityVisualOverlayPremium.new(simulation)
    simulation.add_child(city_overlay)
    _build_interface()

    simulation.hud_updated.connect(_on_hud_updated)
    simulation.toast_requested.connect(_show_toast)
    simulation.game_over.connect(_on_game_over)
    simulation.upgrade_requested.connect(_on_upgrade_requested)
    (simulation as CitySimulationEconomy).building_selected.connect(_open_building_panel)

    _set_mode("road")
    _on_hud_updated(simulation.get_snapshot())

func _build_interface() -> void:
    super._build_interface()
    _build_economy_card()
    _build_shop_panel()
    _build_building_panel()

func _build_economy_card() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(84.0, 112.0)
    panel.size = Vector2(168.0, 116.0)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.05, 0.10, 0.105, 0.94), 16, Color("#3D5B58")))
    hud_canvas.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 9)
    margin.add_theme_constant_override("margin_bottom", 9)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 5)
    margin.add_child(column)

    var caption := Label.new()
    caption.text = "ECONOMIA"
    caption.add_theme_font_size_override("font_size", 8)
    caption.add_theme_color_override("font_color", Color("#75918D"))
    column.add_child(caption)

    coin_label = Label.new()
    coin_label.text = "◈ 30 MOEDAS"
    coin_label.add_theme_font_size_override("font_size", 14)
    coin_label.add_theme_color_override("font_color", Color("#F1CF72"))
    column.add_child(coin_label)

    var shop := Button.new()
    shop.text = "ABRIR LOJA"
    shop.custom_minimum_size = Vector2(0.0, 44.0)
    shop.add_theme_font_size_override("font_size", 9)
    GridFlowUITheme.apply_button(shop, true)
    shop.pressed.connect(_open_shop)
    column.add_child(shop)

# Só aparecem no dock os recursos que o jogador possui. Remover, sentido único
# e mover mapa são ferramentas-base e permanecem sempre disponíveis.
func _build_tool_dock() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(205.0, 626.0)
    panel.size = Vector2(870.0, 78.0)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.035, 0.075, 0.083, 0.97), 19, Color("#2A474A")))
    hud_canvas.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 7)
    margin.add_theme_constant_override("margin_bottom", 7)
    panel.add_child(margin)

    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_CENTER
    row.add_theme_constant_override("separation", 6)
    margin.add_child(row)

    _add_inventory_mode_button(row, "ESTRADA\nx0", "road")
    _add_inventory_mode_button(row, "SEMÁFORO\nx0", "signal")
    _add_inventory_mode_button(row, "ROTUNDA\nx0", "roundabout")
    _add_inventory_mode_button(row, "ALARGAR\nx0", "lanes")
    _add_inventory_mode_button(row, "PONTE\nx0", "bridge")
    _add_inventory_mode_button(row, "REMOVER", "erase")
    _add_inventory_mode_button(row, "SENTIDO\nÚNICO", "oneway")
    _add_inventory_mode_button(row, "MOVER\nMAPA", "pan")

func _add_inventory_mode_button(parent: HBoxContainer, text: String, mode: String) -> void:
    var button := Button.new()
    button.text = text
    button.toggle_mode = true
    button.custom_minimum_size = Vector2(98.0, 62.0)
    button.add_theme_font_size_override("font_size", 9)
    GridFlowUITheme.apply_toggle(button)
    button.pressed.connect(_set_mode.bind(mode))
    parent.add_child(button)
    mode_buttons[mode] = button

func _build_shop_panel() -> void:
    shop_panel = PanelContainer.new()
    shop_panel.position = Vector2(304.0, 126.0)
    shop_panel.size = Vector2(672.0, 476.0)
    shop_panel.visible = false
    shop_panel.add_theme_stylebox_override("panel", _glass_style(Color(0.03, 0.07, 0.078, 0.99), 24, Color("#4B746B")))
    hud_canvas.add_child(shop_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    shop_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 11)
    margin.add_child(column)

    var top := HBoxContainer.new()
    column.add_child(top)

    var title := Label.new()
    title.text = "LOJA DE INFRAESTRUTURAS"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("#F0F6F2"))
    top.add_child(title)

    var close := Button.new()
    close.text = "FECHAR"
    close.custom_minimum_size = Vector2(82.0, 34.0)
    close.add_theme_font_size_override("font_size", 8)
    GridFlowUITheme.apply_button(close)
    close.pressed.connect(_close_shop)
    top.add_child(close)

    shop_level_label = Label.new()
    shop_level_label.add_theme_font_size_override("font_size", 11)
    shop_level_label.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    column.add_child(shop_level_label)

    var note := Label.new()
    note.text = "Compra apenas o que precisas. Evoluir a loja desbloqueia infraestruturas mais avançadas."
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_font_size_override("font_size", 10)
    note.add_theme_color_override("font_color", Color("#849C98"))
    column.add_child(note)

    var grid := GridContainer.new()
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 10)
    grid.add_theme_constant_override("v_separation", 10)
    column.add_child(grid)

    var economy := simulation as CitySimulationEconomy
    for item: Dictionary in economy.get_shop_catalog():
        var button := Button.new()
        button.custom_minimum_size = Vector2(294.0, 74.0)
        button.add_theme_font_size_override("font_size", 10)
        GridFlowUITheme.apply_button(button)
        var item_id := String(item.id)
        button.pressed.connect(_buy_shop_item.bind(item_id))
        grid.add_child(button)
        shop_buttons[item_id] = button

    shop_upgrade_button = Button.new()
    shop_upgrade_button.custom_minimum_size = Vector2(0.0, 54.0)
    shop_upgrade_button.add_theme_font_size_override("font_size", 11)
    GridFlowUITheme.apply_button(shop_upgrade_button, true)
    shop_upgrade_button.pressed.connect(_upgrade_shop)
    column.add_child(shop_upgrade_button)

func _build_building_panel() -> void:
    building_panel = PanelContainer.new()
    building_panel.position = Vector2(890.0, 176.0)
    building_panel.size = Vector2(350.0, 300.0)
    building_panel.visible = false
    building_panel.add_theme_stylebox_override("panel", _glass_style(Color(0.035, 0.08, 0.087, 0.985), 22, Color("#46645F")))
    hud_canvas.add_child(building_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 22)
    margin.add_theme_constant_override("margin_bottom", 22)
    building_panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 12)
    margin.add_child(column)

    var tag := Label.new()
    tag.text = "EVOLUÇÃO DO EDIFÍCIO"
    tag.add_theme_font_size_override("font_size", 9)
    tag.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    column.add_child(tag)

    building_title = Label.new()
    building_title.add_theme_font_size_override("font_size", 22)
    building_title.add_theme_color_override("font_color", Color("#F2F6F3"))
    column.add_child(building_title)

    building_info = Label.new()
    building_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    building_info.custom_minimum_size = Vector2(0.0, 118.0)
    building_info.add_theme_font_size_override("font_size", 11)
    building_info.add_theme_color_override("font_color", Color("#B5C6C2"))
    column.add_child(building_info)

    building_upgrade_button = Button.new()
    building_upgrade_button.custom_minimum_size = Vector2(0.0, 50.0)
    building_upgrade_button.add_theme_font_size_override("font_size", 10)
    GridFlowUITheme.apply_button(building_upgrade_button, true)
    building_upgrade_button.pressed.connect(_upgrade_selected_building)
    column.add_child(building_upgrade_button)

    var close := Button.new()
    close.text = "FECHAR"
    close.custom_minimum_size = Vector2(0.0, 36.0)
    close.add_theme_font_size_override("font_size", 8)
    GridFlowUITheme.apply_button(close)
    close.pressed.connect(_close_building_panel)
    column.add_child(close)

func _on_hud_updated(snapshot: Dictionary) -> void:
    super._on_hud_updated(snapshot)
    if coin_label != null:
        coin_label.text = "◈ %d MOEDAS" % int(snapshot.get("coins", 0))
    if green_button != null:
        green_button.visible = int(snapshot.green) > 0
    _refresh_inventory_visibility(snapshot)
    if shop_panel != null and shop_panel.visible:
        _refresh_shop()
    if building_panel != null and building_panel.visible:
        _refresh_building_panel()

func _refresh_inventory_visibility(snapshot: Dictionary) -> void:
    if mode_buttons.is_empty():
        return
    (mode_buttons["road"] as Button).visible = int(snapshot.roads) > 0
    (mode_buttons["signal"] as Button).visible = int(snapshot.signals) > 0
    (mode_buttons["roundabout"] as Button).visible = int(snapshot.roundabouts) > 0
    (mode_buttons["lanes"] as Button).visible = int(snapshot.lane_upgrades) > 0
    (mode_buttons["bridge"] as Button).visible = int(snapshot.bridges) > 0
    (mode_buttons["erase"] as Button).visible = true
    (mode_buttons["oneway"] as Button).visible = true
    (mode_buttons["pan"] as Button).visible = true

func _open_shop() -> void:
    _pause_before_modal = simulation.paused
    simulation.set_paused(true)
    building_panel.visible = false
    shop_panel.visible = true
    _refresh_shop()

func _close_shop() -> void:
    shop_panel.visible = false
    if not _pause_before_modal and not simulation.is_game_over:
        simulation.set_paused(false)

func _refresh_shop() -> void:
    var economy := simulation as CitySimulationEconomy
    if economy == null:
        return
    shop_level_label.text = "LOJA NÍVEL %d  •  CARTEIRA %d MOEDAS" % [economy.shop_level, economy.coins]
    for item: Dictionary in economy.get_shop_catalog():
        var item_id := String(item.id)
        var button: Button = shop_buttons.get(item_id) as Button
        if button == null:
            continue
        var required := int(item.level)
        var cost := int(item.cost)
        if economy.shop_level >= 4:
            cost = int(ceil(float(cost) * 0.85))
        if economy.shop_level < required:
            button.text = "%s\n%s  •  LOJA NÍVEL %d" % [String(item.title), String(item.detail), required]
            button.disabled = true
        else:
            button.text = "%s\n%s  •  ◈ %d" % [String(item.title), String(item.detail), cost]
            button.disabled = economy.coins < cost

    var upgrade_cost := economy.get_shop_upgrade_cost()
    if economy.shop_level >= 4:
        shop_upgrade_button.text = "LOJA NO NÍVEL MÁXIMO  •  15% DESCONTO"
        shop_upgrade_button.disabled = true
    else:
        shop_upgrade_button.text = "EVOLUIR LOJA PARA NÍVEL %d  •  ◈ %d" % [economy.shop_level + 1, upgrade_cost]
        shop_upgrade_button.disabled = economy.coins < upgrade_cost

func _buy_shop_item(item_id: String) -> void:
    var economy := simulation as CitySimulationEconomy
    if economy.buy_shop_item(item_id):
        _refresh_shop()

func _upgrade_shop() -> void:
    var economy := simulation as CitySimulationEconomy
    if economy.upgrade_shop():
        _refresh_shop()

func _open_building_panel(cell: Vector2i) -> void:
    var economy := simulation as CitySimulationEconomy
    var building := economy._building_at_cell(cell)
    if building == null:
        return
    _pause_before_modal = simulation.paused
    simulation.set_paused(true)
    shop_panel.visible = false
    selected_building_cell = cell
    building_panel.visible = true
    _refresh_building_panel()

func _refresh_building_panel() -> void:
    var economy := simulation as CitySimulationEconomy
    var building := economy._building_at_cell(selected_building_cell)
    if building == null:
        building_panel.visible = false
        return

    var group_name := _group_name(building.mobility_group)
    var type_name := _building_type_name(building)
    building_title.text = "%s  •  %s" % [type_name, group_name]

    if building.is_home():
        building_info.text = "NÍVEL %d\nCarros disponíveis: %d / %d\n\nCada nível acrescenta +1 carro à casa e os carros desta origem ficam 5%% mais rápidos. Só servem destinos da mesma cor." % [
            building.upgrade_level,
            economy.get_home_available_cars(building),
            building.home_vehicle_capacity
        ]
    else:
        building_info.text = "NÍVEL %d\nPedidos: %d / capacidade %d\n\nCada nível aumenta a capacidade em +3 e cada chegada a este destino passa a render mais moedas. Só recebe carros da mesma cor." % [
            building.upgrade_level,
            building.demand,
            building.demand_capacity
        ]

    if building.upgrade_level >= 5:
        building_upgrade_button.text = "NÍVEL MÁXIMO"
        building_upgrade_button.disabled = true
    else:
        var cost := economy.get_building_upgrade_cost(building)
        building_upgrade_button.text = "EVOLUIR PARA NÍVEL %d  •  ◈ %d" % [building.upgrade_level + 1, cost]
        building_upgrade_button.disabled = economy.coins < cost

func _upgrade_selected_building() -> void:
    var economy := simulation as CitySimulationEconomy
    if economy.upgrade_building(selected_building_cell):
        _refresh_building_panel()

func _close_building_panel() -> void:
    building_panel.visible = false
    if not _pause_before_modal and not simulation.is_game_over:
        simulation.set_paused(false)

func _group_name(group: String) -> String:
    match group:
        "blue": return "AZUL"
        "yellow": return "AMARELO"
        "green": return "VERDE"
        _: return "VERMELHO"

func _building_type_name(building: CityBuilding) -> String:
    match building.building_type:
        "office": return "ESCRITÓRIOS"
        "shop": return "COMÉRCIO"
        "hospital": return "HOSPITAL"
        _: return "CASA"
