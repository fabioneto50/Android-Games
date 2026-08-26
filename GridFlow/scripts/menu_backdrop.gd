extends Control
class_name GridFlowMenuBackdrop

var _phase: float = 0.0

const BG_TOP := Color("#071215")
const BG_BOTTOM := Color("#0C2024")
const ROAD := Color(0.42, 0.66, 0.64, 0.18)
const ROAD_SOFT := Color(0.42, 0.66, 0.64, 0.08)
const NODE := Color(0.43, 0.86, 0.66, 0.42)
const WATER := Color(0.14, 0.39, 0.46, 0.42)
const WATER_LINE := Color(0.43, 0.75, 0.79, 0.16)
const BUILDING := Color(0.61, 0.76, 0.74, 0.065)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)

func _process(delta: float) -> void:
    _phase += delta
    queue_redraw()

func _draw() -> void:
    var viewport_size := size
    if viewport_size.x < 100.0 or viewport_size.y < 100.0:
        viewport_size = Vector2(1280.0, 720.0)

    draw_rect(Rect2(Vector2.ZERO, viewport_size), BG_TOP, true)
    draw_rect(Rect2(Vector2(0.0, viewport_size.y * 0.43), Vector2(viewport_size.x, viewport_size.y * 0.57)), BG_BOTTOM, true)

    _draw_glows(viewport_size)
    _draw_city_blocks(viewport_size)
    _draw_river(viewport_size)
    _draw_network(viewport_size)
    _draw_live_traffic()

func _draw_glows(viewport_size: Vector2) -> void:
    draw_circle(Vector2(viewport_size.x * 0.18, viewport_size.y * 0.20), 240.0, Color(0.16, 0.52, 0.44, 0.045))
    draw_circle(Vector2(viewport_size.x * 0.82, viewport_size.y * 0.78), 300.0, Color(0.13, 0.39, 0.47, 0.055))
    draw_circle(Vector2(viewport_size.x * 0.57, viewport_size.y * 0.36), 160.0, Color(0.43, 0.86, 0.66, 0.025))

func _draw_city_blocks(viewport_size: Vector2) -> void:
    for x: int in range(18):
        for y: int in range(10):
            var seed: int = abs(x * 71 + y * 137 + x * y * 11)
            if seed % 3 == 0:
                continue
            var px: float = 28.0 + float(x) * 74.0 + float(seed % 15)
            var py: float = 24.0 + float(y) * 72.0 + float((seed / 7) % 13)
            if px > viewport_size.x or py > viewport_size.y:
                continue
            var width: float = 22.0 + float(seed % 26)
            var height: float = 10.0 + float((seed / 5) % 20)
            draw_rect(Rect2(Vector2(px, py), Vector2(width, height)), BUILDING, true)
            if seed % 5 == 0:
                draw_rect(Rect2(Vector2(px + 4.0, py + 4.0), Vector2(maxf(5.0, width - 8.0), 2.0)), Color(0.60, 0.84, 0.77, 0.045), true)

func _draw_river(viewport_size: Vector2) -> void:
    var start := Vector2(-80.0, viewport_size.y * 0.73)
    var end := Vector2(viewport_size.x + 80.0, viewport_size.y * 0.61)
    draw_line(start, end, WATER, 92.0, true)
    for index: int in range(7):
        var offset: float = -28.0 + float(index) * 9.0
        var drift: float = fmod(_phase * 11.0 + float(index) * 23.0, 82.0)
        var direction := (end - start).normalized()
        var normal := Vector2(-direction.y, direction.x)
        var cursor: float = -drift
        var length: float = start.distance_to(end)
        while cursor < length:
            var a := start + direction * cursor + normal * offset
            var b := start + direction * minf(cursor + 34.0, length) + normal * offset
            draw_line(a, b, WATER_LINE, 1.2, true)
            cursor += 82.0

func _draw_network(_viewport_size: Vector2) -> void:
    var roads: Array[PackedVector2Array] = [
        PackedVector2Array([Vector2(-40, 128), Vector2(220, 128), Vector2(360, 208), Vector2(615, 208), Vector2(790, 132), Vector2(1320, 132)]),
        PackedVector2Array([Vector2(92, -30), Vector2(92, 330), Vector2(215, 412), Vector2(215, 760)]),
        PackedVector2Array([Vector2(430, -20), Vector2(430, 148), Vector2(560, 280), Vector2(560, 760)]),
        PackedVector2Array([Vector2(790, -20), Vector2(790, 132), Vector2(720, 310), Vector2(720, 760)]),
        PackedVector2Array([Vector2(1010, -20), Vector2(1010, 240), Vector2(890, 340), Vector2(890, 760)]),
        PackedVector2Array([Vector2(-30, 338), Vector2(215, 338), Vector2(330, 292), Vector2(560, 292), Vector2(720, 340), Vector2(1010, 340), Vector2(1320, 300)]),
        PackedVector2Array([Vector2(-20, 520), Vector2(180, 520), Vector2(330, 450), Vector2(600, 450), Vector2(780, 510), Vector2(1320, 510)])
    ]

    for road: PackedVector2Array in roads:
        for index: int in range(road.size() - 1):
            draw_line(road[index], road[index + 1], ROAD_SOFT, 9.0, true)
            draw_line(road[index], road[index + 1], ROAD, 1.6, true)

    var nodes := [Vector2(92, 128), Vector2(215, 338), Vector2(430, 208), Vector2(560, 292), Vector2(720, 340), Vector2(790, 132), Vector2(890, 340), Vector2(1010, 240)]
    for node: Vector2 in nodes:
        var pulse: float = 3.0 + sin(_phase * 2.1 + node.x * 0.01) * 0.8
        draw_circle(node, pulse + 5.0, Color(NODE, 0.045))
        draw_circle(node, pulse, NODE)

func _draw_live_traffic() -> void:
    var routes: Array[Array] = [
        [Vector2(92, 128), Vector2(790, 132)],
        [Vector2(215, 338), Vector2(1010, 340)],
        [Vector2(430, 208), Vector2(560, 450)],
        [Vector2(790, 132), Vector2(890, 510)]
    ]

    for index: int in range(routes.size()):
        var route: Array = routes[index]
        var a: Vector2 = route[0]
        var b: Vector2 = route[1]
        var speed: float = 0.065 + float(index) * 0.013
        var t: float = fmod(_phase * speed + float(index) * 0.21, 1.0)
        var p := a.lerp(b, t)
        draw_circle(p, 5.5, Color(0.43, 0.86, 0.66, 0.055))
        draw_circle(p, 2.0, Color("#85E2B5"))
