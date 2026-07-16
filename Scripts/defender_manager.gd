extends Node2D

# LEARN_NOTE: DefenderManager chooses which tower scene to place for the current stage.
const STAGE_TOWER_SCENES: Dictionary = {
	1: preload("res://Scenes/Defenders/Stage1Tower.tscn"),
	2: preload("res://Scenes/Defenders/Stage2Tower.tscn"),
	3: preload("res://Scenes/Defenders/Stage3Tower.tscn"),
}

@export var spawn_starting_sentries: bool = true
@export var stage_defender_budgets: Array[int] = [2]
@export var basic_sentry_cost: int = 1

@onready var sentry_container: Node2D = $"../Sentries" as Node2D
@onready var sentry_spawn_root: Node2D = $"../SentrySpawnPoints" as Node2D

func setup_stage(stage_number: int) -> void:
# LEARN_NOTE: Main calls setup_stage; this manager fills allowed marker positions with random defender towers.
	if not spawn_starting_sentries:
		return
	if sentry_container == null:
		push_warning("Missing Sentries sibling node. Add a Node2D there before placing sentries.")
		return
	if sentry_container.get_child_count() > 0:
		return

	var available_spawn_points: Array[Marker2D] = get_sentry_spawn_points_for_stage(stage_number)
	if available_spawn_points.is_empty():
		push_warning("No sentry spawn points found for stage %s." % stage_number)
		return

	available_spawn_points.shuffle()
	var defender_budget: int = get_defender_budget_for_stage(stage_number)
	var sentries_to_spawn: int = get_affordable_sentry_count(defender_budget, available_spawn_points.size())
	var tower_scene: PackedScene = get_tower_scene_for_stage(stage_number)
# LEARN_NOTE: Spawn markers are editor-placeable Marker2D nodes; towers are instantiated at their global positions.
	for index in range(sentries_to_spawn):
		var spawn_point: Marker2D = available_spawn_points[index]
		var sentry: Node2D = tower_scene.instantiate() as Node2D
		sentry.global_position = spawn_point.global_position
		sentry_container.add_child(sentry)

func get_defender_budget_for_stage(stage_number: int) -> int:
# LEARN_NOTE: The budget controls how many towers the computer can afford for a stage.
	if stage_defender_budgets.is_empty():
		return 0

	var budget_index: int = maxi(stage_number - 1, 0)
	if budget_index >= stage_defender_budgets.size():
		return stage_defender_budgets.back()

	return stage_defender_budgets[budget_index]

func get_affordable_sentry_count(defender_budget: int, spawn_point_count: int) -> int:
# LEARN_NOTE: For now every basic tower costs the same amount, so budget converts directly into tower count.
	if basic_sentry_cost <= 0:
		return spawn_point_count

	var affordable_count: int = floori(float(defender_budget) / float(basic_sentry_cost))
	return mini(affordable_count, spawn_point_count)

func get_tower_scene_for_stage(stage_number: int) -> PackedScene:
# LEARN_NOTE: If we ask for a stage beyond the scenes we have, reuse the strongest current tower as a fallback.
	if STAGE_TOWER_SCENES.has(stage_number):
		return STAGE_TOWER_SCENES[stage_number]

	return STAGE_TOWER_SCENES[3]

func get_sentry_spawn_points_for_stage(stage_number: int) -> Array[Marker2D]:
# LEARN_NOTE: Spawn points live under SentrySpawnPoints/Stage1, Stage2, etc. so each stage can have its own allowed tower spots.
	var spawn_points: Array[Marker2D] = []
	if sentry_spawn_root == null:
		return spawn_points

	var stage_folder: Node = sentry_spawn_root.get_node_or_null("Stage%s" % stage_number)
	if stage_folder == null:
		return spawn_points

	for child: Node in stage_folder.get_children():
		var marker: Marker2D = child as Marker2D
		if marker != null:
			spawn_points.append(marker)

	return spawn_points
