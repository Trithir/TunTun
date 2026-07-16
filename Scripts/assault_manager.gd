class_name AssaultManager
extends Node

# LEARN_NOTE: AssaultManager owns the player's planned queue and spawns attackers onto the active Path2D.
signal state_changed
signal troop_reached_goal

# LEARN_NOTE: This dictionary maps the troop id used by the HUD/queue to the scene that should be spawned.
const ATTACKER_SCENES: Dictionary = {
	"grunt": preload("res://Scenes/Attackers/Grunt.tscn"),
	"runner": preload("res://Scenes/Attackers/Runner.tscn"),
	"brute": preload("res://Scenes/Attackers/Brute.tscn"),
	"ranged": preload("res://Scenes/Attackers/Ranged.tscn"),
}

@export var base_queue_limit: int = 5
@export var queue_limit_per_stage: int = 5

@onready var mob_path: Path2D = $"../Map/Path/MobPath" as Path2D

# LEARN_NOTE: troop_queue stores ids like "grunt"; active_mobs tracks spawned attackers still on the map.
var troop_types: Dictionary = {}
var current_stage: int = 1
var current_wave: int = 1
var assault_active: bool = false
var active_mobs: int = 0
var troop_queue: Array[String] = []

func configure(available_troop_types: Dictionary, stage_number: int) -> void:
# LEARN_NOTE: Main passes in troop UI data and the current stage when the game starts or changes stage.
	troop_types = available_troop_types
	current_stage = stage_number

func ensure_default_queue() -> void:
# LEARN_NOTE: This fills the first planning queue so pressing play immediately shows a working example.
	if not troop_queue.is_empty():
		return

	for _index in range(get_queue_limit()):
		add_troop("grunt")

func get_queue_limit() -> int:
# LEARN_NOTE: Queue size grows by stage; later this can be replaced or combined with an army point pool.
	return base_queue_limit + ((current_stage - 1) * queue_limit_per_stage)

func add_troop(troop_type: String) -> void:
# LEARN_NOTE: Adding troops is only allowed while planning, not once the assault has launched.
	if assault_active:
		return
	if not troop_types.has(troop_type):
		return
	if troop_queue.size() >= get_queue_limit():
		return

	troop_queue.append(troop_type)
	state_changed.emit()

func handle_queue_icon_pressed(index: int) -> void:
# LEARN_NOTE: The same queue icon removes a troop before launch, then releases a troop after launch.
	if assault_active:
		release_troop_from_queue(index)
	else:
		remove_troop_from_queue(index)

func remove_troop_from_queue(index: int) -> void:
	if assault_active:
		return
	if index < 0 or index >= troop_queue.size():
		return

	troop_queue.remove_at(index)
	state_changed.emit()

func start_assault() -> void:
# LEARN_NOTE: Launching does not spawn everything at once; it switches the queue into manual-release mode.
	if assault_active:
		return
	if troop_queue.is_empty():
		push_warning("Add at least one troop to the spawn queue before launching an assault.")
		return

	assault_active = true
	state_changed.emit()

func release_troop_from_queue(index: int) -> void:
# LEARN_NOTE: During an assault, clicking a queued troop spawns exactly that one troop onto the path.
	if not assault_active:
		return
	if index < 0 or index >= troop_queue.size():
		return

	var troop_type: String = troop_queue[index]
	if spawn_mob(troop_type):
		troop_queue.remove_at(index)
		finish_assault_if_ready()
		state_changed.emit()

func spawn_mob(troop_type: String) -> bool:
# LEARN_NOTE: "mob" is still used as an old variable name here; it now instantiates one of the new attacker scenes.
	if mob_path == null:
		push_warning("Missing Map/Path/MobPath. Add a Path2D there before spawning mobs.")
		return false

	if mob_path.curve == null or mob_path.curve.point_count < 2:
		push_warning("MobPath needs a Curve2D with at least two points before spawning mobs.")
		return false

	var attacker_scene: PackedScene = ATTACKER_SCENES.get(troop_type, ATTACKER_SCENES["grunt"])
	var mob: Node = attacker_scene.instantiate()
	mob_path.add_child(mob)
	if mob.has_method("configure"):
		mob.call("configure", troop_types.get(troop_type, troop_types["grunt"]))
	mob.connect("reached_goal", Callable(self, "_on_mob_reached_goal"))
	mob.connect("died", Callable(self, "_on_mob_died"))
	mob.call("start_moving")
	active_mobs += 1
	state_changed.emit()
	return true

func finish_assault_if_ready() -> void:
# LEARN_NOTE: The assault ends only when the queue is empty and every spawned attacker has either died or reached the goal.
	if not assault_active:
		return
	if active_mobs > 0:
		return
	if not troop_queue.is_empty():
		return

	assault_active = false
	current_wave += 1
	state_changed.emit()

func reset_for_stage(stage_number: int) -> void:
# LEARN_NOTE: Stage reset clears live attackers and returns the assault state to planning mode.
	clear_active_mobs()
	current_stage = stage_number
	current_wave = 1
	assault_active = false
	active_mobs = 0
	state_changed.emit()

func retreat_to_stage(stage_number: int) -> void:
	reset_for_stage(stage_number)

func clear_active_mobs() -> void:
	if mob_path == null:
		return

# LEARN_NOTE: Spawned attackers are children of MobPath, so clearing that Path2D removes active attackers.
	for child in mob_path.get_children():
		if child is PathFollow2D:
			child.queue_free()

func _on_mob_reached_goal(mob: PathFollow2D) -> void:
# LEARN_NOTE: Attackers emit reached_goal; this manager translates it into game progress for Main.
	active_mobs = maxi(active_mobs - 1, 0)
	mob.queue_free()
	troop_reached_goal.emit()
	finish_assault_if_ready()
	state_changed.emit()

func _on_mob_died(_mob: PathFollow2D) -> void:
# LEARN_NOTE: Died attackers reduce the active count but do not count as troops through.
	active_mobs = maxi(active_mobs - 1, 0)
	finish_assault_if_ready()
	state_changed.emit()
