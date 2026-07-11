class_name AssaultManager
extends Node

signal state_changed
signal troop_reached_goal

const MOB_SCENE: PackedScene = preload("res://Scenes/Mob.tscn")

@export var base_queue_limit: int = 5
@export var queue_limit_per_stage: int = 5

@onready var mob_path: Path2D = $"../Map/Path/MobPath" as Path2D

var troop_types: Dictionary = {}
var current_stage: int = 1
var current_wave: int = 1
var assault_active: bool = false
var active_mobs: int = 0
var troop_queue: Array[String] = []

func configure(available_troop_types: Dictionary, stage_number: int) -> void:
	troop_types = available_troop_types
	current_stage = stage_number

func ensure_default_queue() -> void:
	if not troop_queue.is_empty():
		return

	for _index in range(get_queue_limit()):
		add_troop("grunt")

func get_queue_limit() -> int:
	return base_queue_limit + ((current_stage - 1) * queue_limit_per_stage)

func add_troop(troop_type: String) -> void:
	if assault_active:
		return
	if not troop_types.has(troop_type):
		return
	if troop_queue.size() >= get_queue_limit():
		return

	troop_queue.append(troop_type)
	state_changed.emit()

func handle_queue_icon_pressed(index: int) -> void:
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
	if assault_active:
		return
	if troop_queue.is_empty():
		push_warning("Add at least one troop to the spawn queue before launching an assault.")
		return

	assault_active = true
	state_changed.emit()

func release_troop_from_queue(index: int) -> void:
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
	if mob_path == null:
		push_warning("Missing Map/Path/MobPath. Add a Path2D there before spawning mobs.")
		return false

	if mob_path.curve == null or mob_path.curve.point_count < 2:
		push_warning("MobPath needs a Curve2D with at least two points before spawning mobs.")
		return false

	var mob: Node = MOB_SCENE.instantiate()
	mob_path.add_child(mob)
	mob.call("configure", troop_types.get(troop_type, troop_types["grunt"]))
	mob.connect("reached_goal", Callable(self, "_on_mob_reached_goal"))
	mob.connect("died", Callable(self, "_on_mob_died"))
	mob.call("start_moving")
	active_mobs += 1
	state_changed.emit()
	return true

func finish_assault_if_ready() -> void:
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

	for child in mob_path.get_children():
		if child is PathFollow2D:
			child.queue_free()

func _on_mob_reached_goal(mob: PathFollow2D) -> void:
	active_mobs = maxi(active_mobs - 1, 0)
	mob.queue_free()
	troop_reached_goal.emit()
	finish_assault_if_ready()
	state_changed.emit()

func _on_mob_died(_mob: PathFollow2D) -> void:
	active_mobs = maxi(active_mobs - 1, 0)
	finish_assault_if_ready()
	state_changed.emit()
