class_name Attacker
extends PathFollow2D

# LEARN_NOTE: This script belongs on attacker scenes whose root is PathFollow2D, because PathFollow2D is the Godot node that moves along Map/Path/MobPath.
signal reached_goal(attacker: PathFollow2D)
signal died(attacker: PathFollow2D)

# LEARN_NOTE: Exported variables show in the Inspector, so each inherited scene can set its own stats/sprite without duplicating this movement code.
@export var troop_type: String = "grunt"
@export var display_name: String = "Grunt"
@export var short_name: String = "G"
@export var speed: float = 90.0
@export var max_health: int = 10
@export var damage: int = 0
@export var army_cost: int = 1
@export var visual_angle_offset_degrees: float = 90.0
@export var base_color: Color = Color(0.760784, 0.2, 0.145098, 1.0)
@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2 = Vector2.ONE
@export var hit_flash_duration: float = 0.12

@onready var visual: Node2D = $Visual as Node2D
@onready var placeholder: Polygon2D = $Visual/Placeholder as Polygon2D
@onready var sprite: Sprite2D = $Visual/Sprite2D as Sprite2D

# LEARN_NOTE: Runtime variables track the current copy of an attacker after it has spawned onto the path.
var health: int
var is_moving: bool = false
var hit_flash_remaining: float = 0.0
var has_taken_damage: bool = false

func _ready() -> void:
	health = max_health
	rotates = true
	loop = false
	visual.rotation_degrees = visual_angle_offset_degrees
	apply_visuals()
# LEARN_NOTE: Towers find targets by asking the SceneTree for nodes in the "attackers" group.
	add_to_group("attackers")

func start_moving() -> void:
	progress = 0.0
	is_moving = true

# LEARN_NOTE: AssaultManager calls configure right after spawning so UI/planning data can override defaults when needed.
func configure(troop_data: Dictionary) -> void:
	troop_type = troop_data.get("id", troop_type)
	display_name = troop_data.get("name", display_name)
	short_name = troop_data.get("short_name", short_name)
	speed = troop_data.get("speed", speed)
	max_health = troop_data.get("health", max_health)
	damage = troop_data.get("damage", damage)
	army_cost = troop_data.get("cost", army_cost)
	base_color = troop_data.get("color", base_color)
	health = max_health
	has_taken_damage = false
	apply_visuals()
	queue_redraw()

func apply_visuals() -> void:
# LEARN_NOTE: If sprite_texture is set in the scene Inspector, the Sprite2D is used; otherwise the colored Polygon2D placeholder stays visible.
	if visual == null:
		return

	visual.scale = sprite_scale

	if sprite != null and sprite_texture != null:
		sprite.texture = sprite_texture
		sprite.visible = true
		sprite.modulate = base_color
		if placeholder != null:
			placeholder.visible = false
	elif placeholder != null:
		placeholder.visible = true
		placeholder.color = base_color

func _process(delta: float) -> void:
	update_hit_flash(delta)

	if not is_moving:
		return

# LEARN_NOTE: PathFollow2D moves by increasing progress along its parent Path2D curve.
	progress += speed * delta

	if progress_ratio >= 1.0:
		is_moving = false
		reached_goal.emit(self)

func take_damage(amount: int) -> void:
# LEARN_NOTE: Towers call take_damage on attackers; dying emits a signal so AssaultManager can update active mob counts.
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
	var flash_color: Color = base_color.lerp(Color.WHITE, flash_strength)

	if sprite != null and sprite.visible:
		sprite.modulate = flash_color
	elif placeholder != null:
		placeholder.color = flash_color

	if hit_flash_remaining <= 0.0:
		if sprite != null and sprite.visible:
			sprite.modulate = base_color
		elif placeholder != null:
			placeholder.color = base_color

	queue_redraw()

func _draw() -> void:
# LEARN_NOTE: This draws the little health bar only after the unit has been hit, keeping fresh units visually clean.
	if not has_taken_damage or max_health <= 0:
		return

	var health_ratio: float = clampf(float(health) / float(max_health), 0.0, 1.0)
	var bar_position: Vector2 = Vector2(-20.0, -44.0)
	var bar_size: Vector2 = Vector2(40.0, 6.0)
	draw_rect(Rect2(bar_position, bar_size), Color(0.08, 0.02, 0.02, 0.9), true)
	draw_rect(Rect2(bar_position, Vector2(bar_size.x * health_ratio, bar_size.y)), Color(0.18, 0.95, 0.3, 0.95), true)
	draw_rect(Rect2(bar_position, bar_size), Color(0.95, 0.95, 0.95, 0.85), false, 1.0)
