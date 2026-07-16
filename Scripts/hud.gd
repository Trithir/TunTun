@tool
extends CanvasLayer

# LEARN_NOTE: HUD emits signals instead of changing gameplay directly; Main listens and decides what happens.
signal launch_assault_requested
signal retreat_requested
signal troop_requested(troop_type: String)
signal queue_icon_pressed(index: int)

@export var hide_in_editor: bool = false:
	set(value):
		hide_in_editor = value
		update_editor_visibility()

# LEARN_NOTE: These @onready paths must match node names in Scenes/HUD.tscn.
@onready var progress_label: Label = $ProgressLabel as Label
@onready var castle_label: Label = $CastleLabel as Label
@onready var castle_health_bar: ProgressBar = $CastleHealthBar as ProgressBar
@onready var wave_label: Label = $WaveLabel as Label
@onready var assault_status_label: Label = $AssaultStatusLabel as Label
@onready var launch_assault_button: Button = $LaunchAssaultButton as Button
@onready var retreat_button: Button = $RetreatButton as Button
@onready var grunt_button: Button = $GruntButton as Button
@onready var runner_button: Button = $RunnerButton as Button
@onready var brute_button: Button = $BruteButton as Button
@onready var ranged_button: Button = $RangedButton as Button
@onready var queue_count_label: Label = $QueueCountLabel as Label
@onready var queue_list: GridContainer = $QueuePanel/QueueList as GridContainer

func _ready() -> void:
# LEARN_NOTE: @tool lets the HUD hide itself in the editor when instanced in Main, but still show when editing HUD.tscn directly.
	update_editor_visibility()
	if Engine.is_editor_hint():
		return

# LEARN_NOTE: Button presses become signals that Main connects to gameplay actions.
	launch_assault_button.pressed.connect(func() -> void: launch_assault_requested.emit())
	retreat_button.pressed.connect(func() -> void: retreat_requested.emit())
	grunt_button.pressed.connect(func() -> void: troop_requested.emit("grunt"))
	runner_button.pressed.connect(func() -> void: troop_requested.emit("runner"))
	brute_button.pressed.connect(func() -> void: troop_requested.emit("brute"))
	ranged_button.pressed.connect(func() -> void: troop_requested.emit("ranged"))

func update_editor_visibility() -> void:
	if Engine.is_editor_hint():
		visible = not hide_in_editor
	else:
		visible = true

func update_status(
# LEARN_NOTE: Main calls update_status whenever visible HUD numbers/buttons may need to change.
	stage_number: int,
	wave_number: int,
	troops_through: int,
	troops_required: int,
	castle_health: int,
	assault_active: bool,
	active_mobs: int,
	queue_size: int,
	queue_limit: int
) -> void:
	progress_label.text = "Troops Through: %s / %s" % [troops_through, troops_required]
	castle_label.text = "Castle Health: %s%%" % castle_health
	castle_health_bar.value = castle_health
	wave_label.text = "Stage: %s" % stage_number

	if assault_active:
		assault_status_label.text = "Wave %s: click queued troops to release. %s on path." % [wave_number, active_mobs]
	else:
		assault_status_label.text = "Ready to plan."

	launch_assault_button.disabled = assault_active or queue_size == 0
	retreat_button.disabled = not assault_active
	queue_count_label.text = "Queue: %s / %s" % [queue_size, queue_limit]

	var queue_full: bool = queue_size >= queue_limit
# LEARN_NOTE: Troop buttons are locked during an assault because assault mode uses queue clicks to release units.
	grunt_button.disabled = assault_active or queue_full
	runner_button.disabled = assault_active or queue_full
	brute_button.disabled = assault_active or queue_full
	ranged_button.disabled = assault_active or queue_full

func rebuild_queue(queue: Array[String], troop_types: Dictionary, assault_active: bool) -> void:
# LEARN_NOTE: Queue buttons are created dynamically so the UI always mirrors the current planned/releasable troop order.
	for child in queue_list.get_children():
		child.queue_free()

	for index in range(queue.size()):
		var troop_type: String = queue[index]
		var troop_data: Dictionary = troop_types.get(troop_type, troop_types["grunt"])
		var icon: Button = Button.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.text = troop_data["short_name"]
		if assault_active:
			icon.tooltip_text = "Release %s" % troop_data["name"]
		else:
			icon.tooltip_text = "Remove %s from queue" % troop_data["name"]
		icon.modulate = troop_data["color"]
		icon.disabled = false
		icon.pressed.connect(func() -> void: queue_icon_pressed.emit(index))
		queue_list.add_child(icon)
