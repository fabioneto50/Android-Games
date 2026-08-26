extends RefCounted
class_name RoadGraph

var _astar := AStar2D.new()
var _cell_to_id: Dictionary = {}
var _id_to_cell: Dictionary = {}
var _next_id: int = 1

func clear() -> void:
    _astar.clear()
    _cell_to_id.clear()
    _id_to_cell.clear()
    _next_id = 1

func has_cell(cell: Vector2i) -> bool:
    return _cell_to_id.has(cell)

func add_cell(cell: Vector2i) -> void:
    if _cell_to_id.has(cell):
        return

    var point_id := _next_id
    _next_id += 1
    _cell_to_id[cell] = point_id
    _id_to_cell[point_id] = cell
    _astar.add_point(point_id, Vector2(cell.x, cell.y))

    for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
        var neighbor: Vector2i = cell + direction
        if not _cell_to_id.has(neighbor):
            continue
        var neighbor_id: int = _cell_to_id[neighbor]
        if not _astar.are_points_connected(point_id, neighbor_id):
            _astar.connect_points(point_id, neighbor_id, true)

func remove_cell(cell: Vector2i) -> void:
    if not _cell_to_id.has(cell):
        return
    var point_id: int = _cell_to_id[cell]
    _astar.remove_point(point_id)
    _cell_to_id.erase(cell)
    _id_to_cell.erase(point_id)

func degree(cell: Vector2i) -> int:
    if not _cell_to_id.has(cell):
        return 0
    var total := 0
    for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
        if _cell_to_id.has(cell + direction):
            total += 1
    return total

func get_path_cells(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not _cell_to_id.has(start_cell) or not _cell_to_id.has(end_cell):
        return result

    var start_id: int = _cell_to_id[start_cell]
    var end_id: int = _cell_to_id[end_cell]
    var id_path: PackedInt64Array = _astar.get_id_path(start_id, end_id)
    for raw_id in id_path:
        var point_id := int(raw_id)
        if _id_to_cell.has(point_id):
            result.append(_id_to_cell[point_id])
    return result
