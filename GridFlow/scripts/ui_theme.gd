extends RefCounted
class_name GridFlowUITheme

const BG := Color("#0E171A")
const PANEL := Color("#172327")
const PANEL_ALT := Color("#1E2D31")
const BORDER := Color("#314348")
const TEXT := Color("#F1F5F2")
const MUTED := Color("#9FB0B2")
const ACCENT := Color("#6FD0A0")
const ACCENT_DARK := Color("#245A45")
const WARNING := Color("#F2C36B")
const DANGER := Color("#EE706A")

static func panel_style(background: Color = PANEL, radius: int = 12, border_color: Color = BORDER, border_width: int = 1) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border_color
    style.set_border_width_all(border_width)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
    style.shadow_size = 8
    style.shadow_offset = Vector2(0.0, 3.0)
    return style

static func button_style(background: Color, border_color: Color = BORDER, radius: int = 10) -> StyleBoxFlat:
    var style := panel_style(background, radius, border_color, 1)
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.12)
    style.shadow_size = 4
    style.shadow_offset = Vector2(0.0, 2.0)
    style.content_margin_left = 10.0
    style.content_margin_right = 10.0
    style.content_margin_top = 7.0
    style.content_margin_bottom = 7.0
    return style

static func apply_panel(panel: PanelContainer, background: Color = PANEL, radius: int = 12) -> void:
    panel.add_theme_stylebox_override("panel", panel_style(background, radius))

static func apply_button(button: Button, accent: bool = false, danger: bool = false) -> void:
    var normal_bg := PANEL_ALT
    var hover_bg := Color("#293B40")
    var pressed_bg := Color("#344A4F")
    var border := BORDER
    var font := TEXT

    if accent:
        normal_bg = ACCENT_DARK
        hover_bg = Color("#2F7358")
        pressed_bg = Color("#398665")
        border = ACCENT.darkened(0.12)
    elif danger:
        normal_bg = Color("#552D2D")
        hover_bg = Color("#6A3635")
        pressed_bg = Color("#7A3F3D")
        border = DANGER.darkened(0.18)

    button.add_theme_stylebox_override("normal", button_style(normal_bg, border))
    button.add_theme_stylebox_override("hover", button_style(hover_bg, border))
    button.add_theme_stylebox_override("pressed", button_style(pressed_bg, ACCENT if accent else border))
    button.add_theme_stylebox_override("focus", button_style(pressed_bg, ACCENT if accent else border))
    button.add_theme_stylebox_override("disabled", button_style(Color("#1B2528"), Color("#28363A")))
    button.add_theme_color_override("font_color", font)
    button.add_theme_color_override("font_hover_color", TEXT)
    button.add_theme_color_override("font_pressed_color", TEXT)
    button.add_theme_color_override("font_disabled_color", Color("#607174"))

static func apply_toggle(button: Button) -> void:
    apply_button(button)
    button.add_theme_stylebox_override("pressed", button_style(ACCENT_DARK, ACCENT))
    button.add_theme_stylebox_override("focus", button_style(ACCENT_DARK, ACCENT))

static func apply_label(label: Label, muted: bool = false) -> void:
    label.add_theme_color_override("font_color", MUTED if muted else TEXT)

static func apply_progress(bar: ProgressBar) -> void:
    var background := StyleBoxFlat.new()
    background.bg_color = Color("#243338")
    background.corner_radius_top_left = 6
    background.corner_radius_top_right = 6
    background.corner_radius_bottom_left = 6
    background.corner_radius_bottom_right = 6

    var fill := StyleBoxFlat.new()
    fill.bg_color = ACCENT
    fill.corner_radius_top_left = 6
    fill.corner_radius_top_right = 6
    fill.corner_radius_bottom_left = 6
    fill.corner_radius_bottom_right = 6

    bar.add_theme_stylebox_override("background", background)
    bar.add_theme_stylebox_override("fill", fill)
