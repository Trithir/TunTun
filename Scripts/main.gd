extends Node2D

const TROOP_TYPES: Dictionary = {
	"grunt": {
		"id": "grunt",
		"name": "Grunt",
		"short_name": "G",
		"speed": 90.0,
		"health": 10,
		"color": Color(0.760784, 0.2, 0.145098, 1.0),
	},
	"runner": {
		"id": "runner",
		"name": "Runner",
		"short_name": "R",
		"speed": 135.0,
		"health": 6,
		"color": Color(0.2, 0.55, 1.0, 1.0),
	},
	"brute": {
		"id": "brute",
		"name": "Brute",
		"short_name": "B",
		"speed": 62.0,
		"health": 24,
		"color": Color(0.55, 0.25, 0.85, 1.0),
	},
}

@export var troops_required_to_advance: int = 5
@export var castle_damage_per_troop: int = 5

@onready var mob_path: Path2D = get_node_or_null("Map/Path/MobPath") as Path2D
@onready var build_zones: Node2D = get_node_or_null("Map/BuildZones") as Node2D
@onready var defender_manager: Node = get_node_or_null("Map/Defenders/DefenderManager")
@onready var assault_manager: AssaultManager = get_node_or_null("AssaultManager") as AssaultManager
@onready var hud: CanvasLayer = get_node_or_null("UI") as CanvasLayer

var current_stage: int = 1
var troops_through: int = 0
var castle_health: int = 100

func _ready() -> void:
	print("Map ready: path length %s, %s build zones" % [get_path_length(), get_build_zone_count()])
	setup_assault_manager()
	connect_hud()
	setup_defenders()
	update_hud()

func connect_hud() -> void:
	if hud == null:
		return

	hud.connect("launch_assault_requested", Callable(self, "_on_launch_assault_pressed"))
	hud.connect("retreat_requested", Callable(self, "_on_retreat_pressed"))
	hud.connect("troop_requested", Callable(self, "_on_troop_requested"))
	hud.connect("queue_icon_pressed", Callable(self, "_on_queue_icon_pressed"))

func setup_assault_manager() -> void:
	if assault_manager == null:
		return

	assault_manager.configure(TROOP_TYPES, current_stage)
	assault_manager.state_changed.connect(_on_assault_state_changed)
	assault_manager.troop_reached_goal.connect(_on_assault_troop_reached_goal)
	assault_manager.ensure_default_queue()

func get_path_length() -> float:
	if mob_path == null or mob_path.curve == null:
		return 0.0
	return mob_path.curve.get_baked_length()

func get_build_zone_count() -> int:
	if build_zones == null:
		return 0
	return build_zones.get_child_count()

func setup_defenders() -> void:
	if defender_manager == null:
		return

	defender_manager.call("setup_stage", current_stage)

func _on_assault_troop_reached_goal() -> void:
	troops_through += 1
	castle_health = maxi(castle_health - castle_damage_per_troop, 0)

	if troops_through >= troops_required_to_advance:
		advance_stage()

	update_hud()

func _on_assault_state_changed() -> void:
	rebuild_queue_ui()
	update_hud()

func _on_launch_assault_pressed() -> void:
	if assault_manager == null:
		return

	assault_manager.start_assault()

func _on_retreat_pressed() -> void:
	retreat()

func _on_troop_requested(troop_type: String) -> void:
	if assault_manager == null:
		return

	assault_manager.add_troop(troop_type)

func _on_queue_icon_pressed(index: int) -> void:
	if assault_manager == null:
		return

	assault_manager.handle_queue_icon_pressed(index)

func advance_stage() -> void:
	current_stage += 1
	troops_through = 0
	if assault_manager != null:
		assault_manager.reset_for_stage(current_stage)
	print("Stage advanced to %s. Future work: reveal the next map section." % current_stage)

func retreat() -> void:
	if assault_manager == null:
		return
	if not assault_manager.assault_active and current_stage <= 1:
		return

	troops_through = 0

	if current_stage > 1:
		current_stage -= 1

	assault_manager.retreat_to_stage(current_stage)
	print("Retreated to stage %s. Future work: shift/reveal the previous map section." % current_stage)
	update_hud()

func update_hud() -> void:
	if hud == null or assault_manager == null:
		return

	hud.call(
		"update_status",
		current_stage,
		assault_manager.current_wave,
		troops_through,
		troops_required_to_advance,
		castle_health,
		assault_manager.assault_active,
		assault_manager.active_mobs,
		assault_manager.troop_queue.size(),
		assault_manager.get_queue_limit()
	)

func rebuild_queue_ui() -> void:
	if hud == null or assault_manager == null:
		return

	hud.call("rebuild_queue", assault_manager.troop_queue, TROOP_TYPES, assault_manager.assault_active)
