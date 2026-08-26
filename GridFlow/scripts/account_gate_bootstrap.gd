extends GridFlowAccountGate
class_name GridFlowAccountGateBootstrap

var _simulation_resolved: bool = false

func _ready() -> void:
    layer = 120
    _build_login()
    _build_session_badge()
    _try_resolve_simulation()

func _process(delta: float) -> void:
    if not _simulation_resolved:
        _try_resolve_simulation()
        if not _simulation_resolved:
            return

    super._process(delta)

func _try_resolve_simulation() -> void:
    if simulation != null:
        _simulation_resolved = true
        simulation.set_paused(true)
        return

    var parent_node := get_parent()
    if parent_node == null:
        return

    var candidate: Variant = parent_node.get("simulation")
    if candidate is CitySimulationPT:
        simulation = candidate as CitySimulationPT
        _simulation_resolved = true
        simulation.set_paused(true)

func _try_login() -> void:
    if not _simulation_resolved:
        _try_resolve_simulation()
    if simulation == null:
        _set_feedback("O jogo ainda está a iniciar. Tenta novamente.", true)
        return
    super._try_login()

func _try_create_account() -> void:
    if not _simulation_resolved:
        _try_resolve_simulation()
    if simulation == null:
        _set_feedback("O jogo ainda está a iniciar. Tenta novamente.", true)
        return
    super._try_create_account()
