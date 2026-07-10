extends PathFollow2D

signal reached_goal(mob: PathFollow2D)

@export var speed: float = 90.0
@export var max_health: int = 10
@export var visual_angle_offset_degrees: float = 90.0
@export var troop_type: String = "grunt"

@onready var visual: Node2D = $Visual as Node2D
@onready var placeholder: Polygon2D = $Visual/Placeholder as Polygon2D

var health: int
var is_moving: bool = false

func _ready() -> void:
	health = max_health
	rotates = true
	loop = false
	visual.rotation_degrees = visual_angle_offset_degrees
	apply_troop_type(troop_type)

func start_moving() -> void:
	progress = 0.0
	is_moving = true

func configure(troop_data: Dictionary) -> void:
	troop_type = troop_data.get("id", troop_type)
	speed = troop_data.get("speed", speed)
	max_health = troop_data.get("health", max_health)
	health = max_health
	apply_troop_type(troop_type)

func apply_troop_type(type_id: String) -> void:
	if placeholder == null:
		return

	match type_id:
		"runner":
			placeholder.color = Color(0.2, 0.55, 1.0, 1.0)
			visual.scale = Vector2(0.85, 0.85)
		"brute":
			placeholder.color = Color(0.55, 0.25, 0.85, 1.0)
			visual.scale = Vector2(1.2, 1.2)
		_:
			placeholder.color = Color(0.760784, 0.2, 0.145098, 1.0)
			visual.scale = Vector2.ONE

func _process(delta: float) -> void:
	if not is_moving:
		return

	progress += speed * delta

	if progress_ratio >= 1.0:
		is_moving = false
		reached_goal.emit(self)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()
