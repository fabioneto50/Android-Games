extends GridFlowAccountGateBootstrap
class_name GridFlowAccountGateNavigation

var return_to_menu_button: Button

func _ready() -> void:
    super._ready()
    _build_return_to_menu_button()

func _build_return_to_menu_button() -> void:
    return_to_menu_button = Button.new()
    return_to_menu_button.text = "MENU"
    return_to_menu_button.position = Vector2(1150.0, 548.0)
    return_to_menu_button.size = Vector2(110.0, 40.0)
    return_to_menu_button.visible = false
    return_to_menu_button.add_theme_font_size_override("font_size", 11)
    GridFlowUITheme.apply_button(return_to_menu_button)
    return_to_menu_button.pressed.connect(_return_to_main_menu)
    add_child(return_to_menu_button)

func _show_main_menu() -> void:
    if return_to_menu_button != null:
        return_to_menu_button.visible = false
    super._show_main_menu()

func _start_from_menu() -> void:
    super._start_from_menu()
    if return_to_menu_button != null and _authenticated:
        return_to_menu_button.visible = true

func _logout() -> void:
    if return_to_menu_button != null:
        return_to_menu_button.visible = false
    super._logout()

func _return_to_main_menu() -> void:
    if not _authenticated or simulation == null:
        return

    _save_current_game()
    _had_existing_save = true
    simulation.set_paused(true)
    _show_main_menu()

func _unhandled_input(event: InputEvent) -> void:
    if not _authenticated or simulation == null:
        return
    if menu_root != null and menu_root.visible:
        return
    if event.is_action_pressed("ui_cancel"):
        _return_to_main_menu()
        get_viewport().set_input_as_handled()
