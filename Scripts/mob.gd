extends PathFollow2D

signal reached_goal(mob: PathFollow2D)
signal died(mob: PathFollow2D)

@export var speed: float = 90.0
@export var max_health: int = 10
@export var visual_angle_offset_degrees: float = 90.0
@export var troop_type: String = "grunt"
@export var hit_flash_duration: float = 0.12

@onready var visual: Node2D = $Visual as Node2D
@onready var placeholder: Polygon2D = $Visual/Placeholder as Polygon2D

var health: int
var is_moving: bool = false
var base_color: Color = Color.WHITE
var hit_flash_remaining: float = 0.0
var has_taken_damage: bool = false

func _ready() -> void:
	health = max_health
	rotates = true
	loop = false
	visual.rotation_degrees = visual_angle_offset_degrees
	apply_troop_type(troop_type)
	add_to_group("attackers")

func start_moving() -> void:
	progress = 0.0
	is_moving = true

func configure(troop_data: Dictionary) -> void:
	troop_type = troop_data.get("id", troop_type)
	speed = troop_data.get("speed", speed)
	max_health = troop_data.get("health", max_health)
	health = max_health
	has_taken_damage = false
	apply_troop_type(troop_type)
	queue_redraw()

func apply_troop_type(type_id: String) -> void:
	if placeholder == null:
		return

	match type_id:
		"runner":
			base_color = Color(0.2, 0.55, 1.0, 1.0)
			visual.scale = Vector2(0.85, 0.85)
		"brute":
			base_color = Color(0.55, 0.25, 0.85, 1.0)
			visual.scale = Vector2(1.2, 1.2)
		_:
			base_color = Color(0.760784, 0.2, 0.145098, 1.0)
			visual.scale = Vector2.ONE
	placeholder.color = base_color

func _process(delta: float) -> void:
	update_hit_flash(delta)

	if not is_moving:
		return

	progress += speed * delta

	if progress_ratio >= 1.0:
		is_moving = false
		reached_goal.emit(self)

func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health -= amount
	has_taken_damage = true
	hit_flash_remaining = hit_flash_duration
	update_hit_flash(0.0)
	queue_redraw()

	if health <= 0:
		is_moving = false
		died.emit(self)
		queue_free()

func update_hit_flash(delta: float) -> void:
	if hit_flash_remaining <= 0.0:
		return

	hit_flash_remaining = maxf(hit_flash_remaining - delta, 0.0)
	var flash_strength: float = hit_flash_remaining / hit_flash_duration
	placeholder.color = base_color.lerp(Color.WHITE, flash_strength)

	if hit_flash_remaining <= 0.0:
		placeholder.color = base_color

	queue_redraw()

func _draw() -> void:
	if not has_taken_damage or max_health <= 0:
		return

	var health_ratio: float = clampf(float(health) / float(max_health), 0.0, 1.0)
	var bar_position: Vector2 = Vector2(-20.0, -44.0)
	var bar_size: Vector2 = Vector2(40.0, 6.0)
	draw_rect(Rect2(bar_position, bar_size), Color(0.08, 0.02, 0.02, 0.9), true)
	draw_rect(Rect2(bar_position, Vector2(bar_size.x * health_ratio, bar_size.y)), Color(0.18, 0.95, 0.3, 0.95), true)
	draw_rect(Rect2(bar_position, bar_size), Color(0.95, 0.95, 0.95, 0.85), false, 1.0)
