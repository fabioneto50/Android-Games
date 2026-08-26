extends RefCounted
class_name CityBuilding

var cell: Vector2i
var building_type: String
var color: Color

func _init(p_cell: Vector2i, p_type: String, p_color: Color) -> void:
    cell = p_cell
    building_type = p_type
    color = p_color
