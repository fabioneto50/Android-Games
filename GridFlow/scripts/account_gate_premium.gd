extends GridFlowAccountGateNavigation
class_name GridFlowAccountGatePremium

func _ready() -> void:
    super._ready()
    if return_to_menu_button != null:
        return_to_menu_button.text = "MENU PRINCIPAL"
        return_to_menu_button.position = Vector2(1115.0, 545.0)
        return_to_menu_button.size = Vector2(145.0, 44.0)
        return_to_menu_button.add_theme_font_size_override("font_size", 9)
        GridFlowUITheme.apply_button(return_to_menu_button)

func _build_login() -> void:
    login_root = Control.new()
    login_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(login_root)

    var backdrop := GridFlowMenuBackdrop.new()
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    login_root.add_child(backdrop)

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.01, 0.025, 0.03, 0.28)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    login_root.add_child(shade)

    var brand_panel := PanelContainer.new()
    brand_panel.position = Vector2(90.0, 104.0)
    brand_panel.size = Vector2(520.0, 500.0)
    brand_panel.add_theme_stylebox_override("panel", _premium_panel(Color(0.035, 0.075, 0.082, 0.72), 28, Color(0.30, 0.66, 0.57, 0.22)))
    login_root.add_child(brand_panel)

    var brand_margin := MarginContainer.new()
    brand_margin.add_theme_constant_override("margin_left", 38)
    brand_margin.add_theme_constant_override("margin_right", 38)
    brand_margin.add_theme_constant_override("margin_top", 38)
    brand_margin.add_theme_constant_override("margin_bottom", 38)
    brand_panel.add_child(brand_margin)

    var brand := VBoxContainer.new()
    brand.add_theme_constant_override("separation", 13)
    brand_margin.add_child(brand)

    var tag := Label.new()
    tag.text = "CENTRO DE CONTROLO URBANO"
    tag.add_theme_font_size_override("font_size", 10)
    tag.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    brand.add_child(tag)

    var title := Label.new()
    title.text = "GRIDFLOW"
    title.add_theme_font_size_override("font_size", 58)
    title.add_theme_color_override("font_color", Color("#F2F8F4"))
    brand.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Constrói a rede. Controla o trânsito.\nMantém a cidade viva."
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.custom_minimum_size = Vector2(430.0, 74.0)
    subtitle.add_theme_font_size_override("font_size", 18)
    subtitle.add_theme_color_override("font_color", Color("#B8C9C5"))
    brand.add_child(subtitle)

    var divider := HSeparator.new()
    divider.custom_minimum_size = Vector2(0.0, 12.0)
    brand.add_child(divider)

    var city := Label.new()
    city.text = "LISBOA  /  07:00  /  REDE EM CRESCIMENTO"
    city.add_theme_font_size_override("font_size", 11)
    city.add_theme_color_override("font_color", Color("#7FA09C"))
    brand.add_child(city)

    var description := Label.new()
    description.text = "Casas com frota própria, destinos com procura, rotundas, pontes sobre o Tejo e emergências que obrigam a redesenhar a cidade em tempo real."
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.custom_minimum_size = Vector2(430.0, 90.0)
    description.add_theme_font_size_override("font_size", 13)
    description.add_theme_color_override("font_color", Color("#9CB2AE"))
    brand.add_child(description)

    var footer := Label.new()
    footer.text = "O progresso é guardado automaticamente por jogador."
    footer.add_theme_font_size_override("font_size", 10)
    footer.add_theme_color_override("font_color", Color("#66827E"))
    brand.add_child(footer)

    var panel := PanelContainer.new()
    panel.position = Vector2(715.0, 104.0)
    panel.size = Vector2(475.0, 500.0)
    panel.add_theme_stylebox_override("panel", _premium_panel(Color(0.035, 0.075, 0.082, 0.96), 28, Color(0.36, 0.67, 0.59, 0.30)))
    login_root.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 40)
    margin.add_theme_constant_override("margin_right", 40)
    margin.add_theme_constant_override("margin_top", 36)
    margin.add_theme_constant_override("margin_bottom", 34)
    panel.add_child(margin)

    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 13)
    margin.add_child(column)

    var eyebrow := Label.new()
    eyebrow.text = "PERFIL DO JOGADOR"
    eyebrow.add_theme_font_size_override("font_size", 10)
    eyebrow.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    column.add_child(eyebrow)

    var login_title := Label.new()
    login_title.text = "Entra na tua cidade"
    login_title.add_theme_font_size_override("font_size", 27)
    login_title.add_theme_color_override("font_color", Color("#F1F6F3"))
    column.add_child(login_title)

    var login_subtitle := Label.new()
    login_subtitle.text = "Usa o teu nome de utilizador ou e-mail."
    login_subtitle.add_theme_font_size_override("font_size", 11)
    login_subtitle.add_theme_color_override("font_color", Color("#829A96"))
    column.add_child(login_subtitle)

    var gap := Control.new()
    gap.custom_minimum_size = Vector2(0.0, 8.0)
    column.add_child(gap)

    identifier_input = LineEdit.new()
    identifier_input.placeholder_text = "Utilizador ou e-mail"
    identifier_input.text = account_manager.get_last_identifier()
    identifier_input.custom_minimum_size = Vector2(0.0, 54.0)
    identifier_input.add_theme_font_size_override("font_size", 14)
    _style_input(identifier_input)
    column.add_child(identifier_input)

    password_input = LineEdit.new()
    password_input.placeholder_text = "Palavra-passe"
    password_input.secret = true
    password_input.custom_minimum_size = Vector2(0.0, 54.0)
    password_input.add_theme_font_size_override("font_size", 14)
    _style_input(password_input)
    password_input.text_submitted.connect(func(_value: String): _try_login())
    column.add_child(password_input)

    feedback_label = Label.new()
    feedback_label.text = "A conta e o progresso ficam guardados neste navegador/dispositivo."
    feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    feedback_label.custom_minimum_size = Vector2(0.0, 48.0)
    feedback_label.add_theme_font_size_override("font_size", 10)
    feedback_label.add_theme_color_override("font_color", Color("#78918D"))
    column.add_child(feedback_label)

    var login_button := Button.new()
    login_button.text = "ENTRAR NO GRIDFLOW"
    login_button.custom_minimum_size = Vector2(0.0, 58.0)
    login_button.add_theme_font_size_override("font_size", 13)
    GridFlowUITheme.apply_button(login_button, true)
    login_button.pressed.connect(_try_login)
    column.add_child(login_button)

    var create_button := Button.new()
    create_button.text = "CRIAR NOVO PERFIL"
    create_button.custom_minimum_size = Vector2(0.0, 50.0)
    create_button.add_theme_font_size_override("font_size", 11)
    GridFlowUITheme.apply_button(create_button)
    create_button.pressed.connect(_try_create_account)
    column.add_child(create_button)

func _build_session_badge() -> void:
    session_panel = PanelContainer.new()
    session_panel.position = Vector2(1020.0, 108.0)
    session_panel.size = Vector2(240.0, 44.0)
    session_panel.visible = false
    session_panel.add_theme_stylebox_override("panel", _premium_panel(Color(0.035, 0.075, 0.082, 0.91), 14, Color(0.24, 0.45, 0.44, 0.55)))
    add_child(session_panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 7)
    margin.add_theme_constant_override("margin_top", 5)
    margin.add_theme_constant_override("margin_bottom", 5)
    session_panel.add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 7)
    margin.add_child(row)

    session_label = Label.new()
    session_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    session_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    session_label.add_theme_font_size_override("font_size", 9)
    session_label.add_theme_color_override("font_color", Color("#BFD0CC"))
    row.add_child(session_label)

    var logout := Button.new()
    logout.text = "SAIR"
    logout.custom_minimum_size = Vector2(54.0, 30.0)
    logout.add_theme_font_size_override("font_size", 8)
    GridFlowUITheme.apply_button(logout)
    logout.pressed.connect(_logout)
    row.add_child(logout)

func _build_main_menu() -> void:
    menu_root = Control.new()
    menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_root.visible = false
    add_child(menu_root)

    var backdrop := GridFlowMenuBackdrop.new()
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    menu_root.add_child(backdrop)

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.01, 0.025, 0.03, 0.22)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    menu_root.add_child(shade)

    var top_tag := Label.new()
    top_tag.position = Vector2(82.0, 56.0)
    top_tag.size = Vector2(500.0, 30.0)
    top_tag.text = "GRIDFLOW  /  CENTRO DE CONTROLO"
    top_tag.add_theme_font_size_override("font_size", 11)
    top_tag.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    menu_root.add_child(top_tag)

    var shell := PanelContainer.new()
    shell.position = Vector2(76.0, 96.0)
    shell.size = Vector2(1128.0, 548.0)
    shell.add_theme_stylebox_override("panel", _premium_panel(Color(0.035, 0.075, 0.082, 0.88), 28, Color(0.34, 0.61, 0.56, 0.24)))
    menu_root.add_child(shell)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 34)
    margin.add_theme_constant_override("margin_right", 34)
    margin.add_theme_constant_override("margin_top", 30)
    margin.add_theme_constant_override("margin_bottom", 30)
    shell.add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 30)
    margin.add_child(row)

    var hero := VBoxContainer.new()
    hero.custom_minimum_size = Vector2(650.0, 0.0)
    hero.add_theme_constant_override("separation", 10)
    row.add_child(hero)

    var profile := Label.new()
    profile.name = "ProfileLabel"
    profile.text = "JOGADOR"
    profile.add_theme_font_size_override("font_size", 10)
    profile.add_theme_color_override("font_color", Color("#77938F"))
    hero.add_child(profile)

    var title := Label.new()
    title.text = "LISBOA"
    title.add_theme_font_size_override("font_size", 46)
    title.add_theme_color_override("font_color", Color("#F2F7F3"))
    hero.add_child(title)

    var city_sub := Label.new()
    city_sub.text = "TEJO  •  PONTES  •  HORA DE PONTA  •  EMERGÊNCIAS"
    city_sub.add_theme_font_size_override("font_size", 10)
    city_sub.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    hero.add_child(city_sub)

    var city_card := PanelContainer.new()
    city_card.custom_minimum_size = Vector2(0.0, 280.0)
    city_card.add_theme_stylebox_override("panel", _premium_panel(Color(0.05, 0.115, 0.125, 0.92), 22, Color(0.30, 0.62, 0.56, 0.34)))
    hero.add_child(city_card)

    var card_margin := MarginContainer.new()
    card_margin.add_theme_constant_override("margin_left", 24)
    card_margin.add_theme_constant_override("margin_right", 24)
    card_margin.add_theme_constant_override("margin_top", 22)
    card_margin.add_theme_constant_override("margin_bottom", 22)
    city_card.add_child(card_margin)

    var card := VBoxContainer.new()
    card.add_theme_constant_override("separation", 12)
    card_margin.add_child(card)

    var live := Label.new()
    live.text = "●  CIDADE ATIVA"
    live.add_theme_font_size_override("font_size", 10)
    live.add_theme_color_override("font_color", GridFlowUITheme.ACCENT)
    card.add_child(live)

    var description := Label.new()
    description.text = "As casas alimentam a rede com carros próprios. Os destinos acumulam procura e obrigam-te a equilibrar distância, capacidade e congestionamento."
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.custom_minimum_size = Vector2(0.0, 68.0)
    description.add_theme_font_size_override("font_size", 13)
    description.add_theme_color_override("font_color", Color("#B8C9C5"))
    card.add_child(description)

    var divider := HSeparator.new()
    card.add_child(divider)

    menu_stats = Label.new()
    menu_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    menu_stats.custom_minimum_size = Vector2(0.0, 104.0)
    menu_stats.add_theme_font_size_override("font_size", 15)
    menu_stats.add_theme_color_override("font_color", Color("#E0EAE6"))
    card.add_child(menu_stats)

    var coming := Label.new()
    coming.text = "PRÓXIMAS CIDADES  /  PORTO  •  MADRID  •  AMESTERDÃO"
    coming.add_theme_font_size_override("font_size", 9)
    coming.add_theme_color_override("font_color", Color("#617C78"))
    hero.add_child(coming)

    var actions := VBoxContainer.new()
    actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    actions.add_theme_constant_override("separation", 12)
    row.add_child(actions)

    var actions_tag := Label.new()
    actions_tag.text = "SESSÃO DE JOGO"
    actions_tag.add_theme_font_size_override("font_size", 9)
    actions_tag.add_theme_color_override("font_color", Color("#77928F"))
    actions.add_child(actions_tag)

    continue_button = Button.new()
    continue_button.text = "CONTINUAR LISBOA"
    continue_button.custom_minimum_size = Vector2(0.0, 72.0)
    continue_button.add_theme_font_size_override("font_size", 15)
    GridFlowUITheme.apply_button(continue_button, true)
    continue_button.pressed.connect(_start_from_menu)
    actions.add_child(continue_button)

    new_game_button = Button.new()
    new_game_button.text = "NOVO JOGO"
    new_game_button.custom_minimum_size = Vector2(0.0, 58.0)
    new_game_button.add_theme_font_size_override("font_size", 12)
    GridFlowUITheme.apply_button(new_game_button)
    new_game_button.pressed.connect(_new_game_from_menu)
    actions.add_child(new_game_button)

    var how_to := Button.new()
    how_to.text = "COMO JOGAR"
    how_to.custom_minimum_size = Vector2(0.0, 54.0)
    how_to.add_theme_font_size_override("font_size", 11)
    GridFlowUITheme.apply_button(how_to)
    how_to.pressed.connect(_toggle_guide)
    actions.add_child(how_to)

    var logout := Button.new()
    logout.text = "TERMINAR SESSÃO"
    logout.custom_minimum_size = Vector2(0.0, 48.0)
    logout.add_theme_font_size_override("font_size", 10)
    GridFlowUITheme.apply_button(logout)
    logout.pressed.connect(_logout)
    actions.add_child(logout)

    menu_note = Label.new()
    menu_note.text = ""
    menu_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    menu_note.custom_minimum_size = Vector2(0.0, 68.0)
    menu_note.add_theme_font_size_override("font_size", 10)
    menu_note.add_theme_color_override("font_color", Color("#748D89"))
    actions.add_child(menu_note)

    _build_guide_panel()

func _style_input(input: LineEdit) -> void:
    var normal := _input_style(Color(0.045, 0.09, 0.10, 0.95), Color("#2B4648"))
    var focus := _input_style(Color(0.055, 0.11, 0.115, 0.98), GridFlowUITheme.ACCENT.darkened(0.10))
    input.add_theme_stylebox_override("normal", normal)
    input.add_theme_stylebox_override("focus", focus)
    input.add_theme_color_override("font_color", Color("#EFF5F1"))
    input.add_theme_color_override("font_placeholder_color", Color("#68817E"))
    input.add_theme_color_override("caret_color", GridFlowUITheme.ACCENT)

func _input_style(background: Color, border_color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border_color
    style.set_border_width_all(1)
    style.corner_radius_top_left = 13
    style.corner_radius_top_right = 13
    style.corner_radius_bottom_left = 13
    style.corner_radius_bottom_right = 13
    style.content_margin_left = 16.0
    style.content_margin_right = 16.0
    style.content_margin_top = 10.0
    style.content_margin_bottom = 10.0
    return style

func _premium_panel(background: Color, radius: int, border_color: Color) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border_color
    style.set_border_width_all(1)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
    style.shadow_size = 16
    style.shadow_offset = Vector2(0.0, 7.0)
    return style
