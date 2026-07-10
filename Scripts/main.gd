extends Node2D

const MOB_SCENE: PackedScene = preload("res://Scenes/Mob.tscn")
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
@export var spawn_interval: float = 1.1
@export var castle_damage_per_troop: int = 5

@onready var mob_path: Path2D = get_node_or_null("Map/Path/MobPath") as Path2D
@onready var build_zones: Node2D = get_node_or_null("Map/BuildZones") as Node2D
@onready var progress_label: Label = get_node_or_null("UI/ProgressLabel") as Label
@onready var castle_label: Label = get_node_or_null("UI/CastleLabel") as Label
@onready var wave_label: Label = get_node_or_null("UI/WaveLabel") as Label
@onready var assault_status_label: Label = get_node_or_null("UI/AssaultStatusLabel") as Label
@onready var launch_assault_button: Button = get_node_or_null("UI/LaunchAssaultButton") as Button
@onready var retreat_button: Button = get_node_or_null("UI/RetreatButton") as Button
@onready var grunt_button: Button = get_node_or_null("UI/GruntButton") as Button
@onready var runner_button: Button = get_node_or_null("UI/RunnerButton") as Button
@onready var brute_button: Button = get_node_or_null("UI/BruteButton") as Button
@onready var queue_count_label: Label = get_node_or_null("UI/QueueCountLabel") as Label
@onready var queue_list: VBoxContainer = get_node_or_null("UI/QueuePanel/QueueList") as VBoxContainer

var current_stage: int = 1
var current_wave: int = 1
var troops_through: int = 0
var castle_health: int = 100
var assault_active: bool = false
var is_spawning_wave: bool = false
var active_mobs: int = 0
var troop_queue: Array[String] = []

func _ready() -> void:
	print("Map ready: path length %s, %s build zones" % [get_path_length(), get_build_zone_count()])
	if launch_assault_button != null:
		launch_assault_button.pressed.connect(_on_launch_assault_pressed)
	if retreat_button != null:
		retreat_button.pressed.connect(_on_retreat_pressed)
	if grunt_button != null:
		grunt_button.pressed.connect(func() -> void: add_troop_to_queue("grunt"))
	if runner_button != null:
		runner_button.pressed.connect(func() -> void: add_troop_to_queue("runner"))
	if brute_button != null:
		brute_button.pressed.connect(func() -> void: add_troop_to_queue("brute"))
	if troop_queue.is_empty():
		for index in range(5):
			add_troop_to_queue("grunt")
	update_hud()

func get_path_length() -> float:
	if mob_path == null or mob_path.curve == null:
		return 0.0
	return mob_path.curve.get_baked_length()

func get_build_zone_count() -> int:
	if build_zones == null:
		return 0
	return build_zones.get_child_count()

func spawn_mob(troop_type: String) -> bool:
	if mob_path == null:
		push_warning("Missing Map/Path/MobPath. Add a Path2D there before spawning mobs.")
		return false

	if mob_path.curve == null or mob_path.curve.point_count < 2:
		push_warning("MobPath needs a Curve2D with at least two points before spawning mobs.")
		return false

	var mob: Node = MOB_SCENE.instantiate()
	mob_path.add_child(mob)
	mob.call("configure", TROOP_TYPES.get(troop_type, TROOP_TYPES["grunt"]))
	mob.connect("reached_goal", Callable(self, "_on_mob_reached_goal"))
	mob.call("start_moving")
	active_mobs += 1
	update_hud()
	return true

func _on_mob_reached_goal(mob: PathFollow2D) -> void:
	troops_through += 1
	castle_health = maxi(castle_health - castle_damage_per_troop, 0)
	mob.queue_free()
	active_mobs = maxi(active_mobs - 1, 0)

	if troops_through >= troops_required_to_advance:
		advance_stage()
	else:
		finish_assault_if_ready()

	update_hud()

func _on_launch_assault_pressed() -> void:
	if assault_active:
		return
	start_assault()

func _on_retreat_pressed() -> void:
	retreat()

func add_troop_to_queue(troop_type: String) -> void:
	if assault_active:
		return
	if not TROOP_TYPES.has(troop_type):
		return

	troop_queue.append(troop_type)
	rebuild_queue_ui()
	update_hud()

func remove_troop_from_queue(index: int) -> void:
	if assault_active:
		return
	if index < 0 or index >= troop_queue.size():
		return

	troop_queue.remove_at(index)
	rebuild_queue_ui()
	update_hud()

func _on_queue_icon_pressed(index: int) -> void:
	remove_troop_from_queue(index)

func start_assault() -> void:
	if troop_queue.is_empty():
		push_warning("Add at least one troop to the spawn queue before launching an assault.")
		return

	assault_active = true
	is_spawning_wave = true
	update_hud()
	_spawn_assault_wave()

func _spawn_assault_wave() -> void:
	while not troop_queue.is_empty():
		if not assault_active:
			break

		var troop_type: String = troop_queue.pop_front()
		rebuild_queue_ui()
		spawn_mob(troop_type)

		if not troop_queue.is_empty():
			await get_tree().create_timer(spawn_interval).timeout
			if not assault_active:
				break

	is_spawning_wave = false
	finish_assault_if_ready()

func finish_assault_if_ready() -> void:
	if is_spawning_wave or active_mobs > 0:
		return

	assault_active = false
	current_wave += 1
	update_hud()

func advance_stage() -> void:
	clear_active_mobs()

	current_stage += 1
	current_wave = 1
	troops_through = 0
	assault_active = false
	is_spawning_wave = false
	active_mobs = 0
	print("Stage advanced to %s. Future work: reveal the next map section." % current_stage)

func retreat() -> void:
	if not assault_active and current_stage <= 1:
		return

	clear_active_mobs()
	assault_active = false
	is_spawning_wave = false
	active_mobs = 0
	troops_through = 0
	current_wave = 1
	rebuild_queue_ui()

	if current_stage > 1:
		current_stage -= 1

	print("Retreated to stage %s. Future work: shift/reveal the previous map section." % current_stage)
	update_hud()

func clear_active_mobs() -> void:
	if mob_path == null:
		return

	for child in mob_path.get_children():
		if child is PathFollow2D:
			child.queue_free()

func update_hud() -> void:
	if progress_label != null:
		progress_label.text = "Troops Through: %s / %s" % [troops_through, troops_required_to_advance]
	if castle_label != null:
		castle_label.text = "Castle: %s%%" % castle_health
	if wave_label != null:
		wave_label.text = "Stage %s  Wave %s" % [current_stage, current_wave]
	if assault_status_label != null:
		if assault_active:
			assault_status_label.text = "Assault active: %s mobs on path" % active_mobs
		else:
			assault_status_label.text = "Plan your assault, then launch."
	if launch_assault_button != null:
		launch_assault_button.disabled = assault_active or troop_queue.is_empty()
	if retreat_button != null:
		retreat_button.disabled = not assault_active and current_stage <= 1
	if queue_count_label != null:
		queue_count_label.text = "Queue: %s" % troop_queue.size()
	if grunt_button != null:
		grunt_button.disabled = assault_active
	if runner_button != null:
		runner_button.disabled = assault_active
	if brute_button != null:
		brute_button.disabled = assault_active

func rebuild_queue_ui() -> void:
	if queue_list == null:
		return

	for child in queue_list.get_children():
		child.queue_free()

	for index in range(troop_queue.size()):
		var troop_type: String = troop_queue[index]
		var troop_data: Dictionary = TROOP_TYPES.get(troop_type, TROOP_TYPES["grunt"])
		var icon: Button = Button.new()
		icon.custom_minimum_size = Vector2(40, 32)
		icon.text = troop_data["short_name"]
		icon.tooltip_text = "Remove %s from queue" % troop_data["name"]
		icon.modulate = troop_data["color"]
		icon.disabled = assault_active
		icon.pressed.connect(_on_queue_icon_pressed.bind(index))
		queue_list.add_child(icon)
