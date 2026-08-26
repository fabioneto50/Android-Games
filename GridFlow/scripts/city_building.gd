extends RefCounted
class_name CityBuilding

var cell: Vector2i
var building_type: String
var color: Color

var demand: int = 0
var demand_capacity: int = 0
var home_vehicle_capacity: int = 0
var mobility_group: String = "red"
var upgrade_level: int = 1

func _init(p_cell: Vector2i, p_type: String, p_color: Color, p_group: String = "red") -> void:
    cell = p_cell
    building_type = p_type
    color = p_color
    mobility_group = p_group
    _configure_mobility_role()

func _configure_mobility_role() -> void:
    match building_type:
        "residential":
            home_vehicle_capacity = 2
            demand_capacity = 0
        "office":
            home_vehicle_capacity = 0
            demand_capacity = 7
        "shop":
            home_vehicle_capacity = 0
            demand_capacity = 6
        "hospital":
            home_vehicle_capacity = 0
            demand_capacity = 8
        _:
            home_vehicle_capacity = 0
            demand_capacity = 6

func is_home() -> bool:
    return building_type == "residential"

func is_destination() -> bool:
    return building_type != "residential"

func pressure() -> float:
    if demand_capacity <= 0:
        return 0.0
    return clampf(float(demand) / float(demand_capacity), 0.0, 2.0)

func group_matches(other: CityBuilding) -> bool:
    return other != null and mobility_group == other.mobility_group

func apply_upgrade() -> void:
    upgrade_level += 1
    if is_home():
        home_vehicle_capacity += 1
    else:
        demand_capacity += 3
        demand = maxi(0, demand - 1)
