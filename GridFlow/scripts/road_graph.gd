extends RefCounted
class_name RoadGraph

const DIRECTIONS: Array[Vector2i] = [
    Vector2i.UP,
    Vector2i.RIGHT,
    Vector2i.DOWN,
    Vector2i.LEFT
]

var _cells: Dictionary = {}
var _one_way: Dictionary = {}

func clear() -> void:
    _cells.clear()
    _one_way.clear()

func has_cell(cell: Vector2i) -> bool:
    return _cells.has(cell)

func add_cell(cell: Vector2i) -> void:
    _cells[cell] = true

func remove_cell(cell: Vector2i) -> void:
    _cells.erase(cell)
    _one_way.erase(cell)

func degree(cell: Vector2i) -> int:
    if not _cells.has(cell):
        return 0

    var total: int = 0
    for direction: Vector2i in DIRECTIONS:
        if _cells.has(cell + direction):
            total += 1
    return total

func set_one_way(cell: Vector2i, direction: Vector2i) -> void:
    if not _cells.has(cell):
        return
    if direction == Vector2i.ZERO:
        _one_way.erase(cell)
    else:
        _one_way[cell] = direction

func get_one_way(cell: Vector2i) -> Vector2i:
    if not _one_way.has(cell):
        return Vector2i.ZERO
    return _one_way[cell] as Vector2i

func get_path_cells(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:
    var empty_result: Array[Vector2i] = []
    if not _cells.has(start_cell) or not _cells.has(end_cell):
        return empty_result
    if start_cell == end_cell:
        return [start_cell]

    var open_set: Array[Vector2i] = [start_cell]
    var came_from: Dictionary = {}
    var g_score: Dictionary = {start_cell: 0.0}
    var f_score: Dictionary = {start_cell: _heuristic(start_cell, end_cell)}

    while not open_set.is_empty():
        var best_index: int = 0
        var best_score: float = float(f_score.get(open_set[0], INF))

        for index: int in range(1, open_set.size()):
            var candidate: Vector2i = open_set[index]
            var candidate_score: float = float(f_score.get(candidate, INF))
            if candidate_score < best_score:
                best_index = index
                best_score = candidate_score

        var current: Vector2i = open_set[best_index]
        if current == end_cell:
            return _reconstruct_path(came_from, current)

        open_set.remove_at(best_index)

        for neighbor: Vector2i in _neighbors(current):
            var tentative_g: float = float(g_score.get(current, INF)) + 1.0
            var known_g: float = float(g_score.get(neighbor, INF))
            if tentative_g >= known_g:
                continue

            came_from[neighbor] = current
            g_score[neighbor] = tentative_g
            f_score[neighbor] = tentative_g + _heuristic(neighbor, end_cell)
            if not open_set.has(neighbor):
                open_set.append(neighbor)

    return empty_result

func _neighbors(cell: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var exit_direction: Vector2i = get_one_way(cell)

    for direction: Vector2i in DIRECTIONS:
        if exit_direction != Vector2i.ZERO and direction != exit_direction:
            continue

        var neighbor: Vector2i = cell + direction
        if not _cells.has(neighbor):
            continue
        result.append(neighbor)

    return result

func _heuristic(a: Vector2i, b: Vector2i) -> float:
    return float(abs(a.x - b.x) + abs(a.y - b.y))

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = [current]
    var cursor: Vector2i = current

    while came_from.has(cursor):
        cursor = came_from[cursor] as Vector2i
        result.push_front(cursor)

    return result
