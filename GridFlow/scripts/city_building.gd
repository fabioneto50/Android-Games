extends RefCounted
class_name CityBuilding

var cell: Vector2i
var building_type: String
var color: Color

# Morfologia de mobilidade do GRIDFLOW.
# As zonas residenciais possuem carros; os restantes edifícios acumulam procura.
var demand: int = 0
var demand_capacity: int = 0
var home_vehicle_capacity: int = 0

func _init(p_cell: Vector2i, p_type: String, p_color: Color) -> void:
    cell = p_cell
    building_type = p_type
    color = p_color
    _configure_mobility_role()

func _configure_mobility_role() -> void:
    match building_type:
        "residential":
            home_vehicle_capacity = 2
            demand_capacity = 0
        "office":
            home_vehicle_capacity = 0
            demand_capacity = 6
        "shop":
            home_vehicle_capacity = 0
            demand_capacity = 5
        "hospital":
            home_vehicle_capacity = 0
            demand_capacity = 7
        _:
            home_vehicle_capacity = 0
            demand_capacity = 5

func is_home() -> bool:
    return building_type == "residential"

func is_destination() -> bool:
    return building_type != "residential"

func pressure() -> float:
    if demand_capacity <= 0:
        return 0.0
    return clampf(float(demand) / float(demand_capacity), 0.0, 2.0)
