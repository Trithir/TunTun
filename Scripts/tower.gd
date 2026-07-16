class_name Tower
extends Node2D

# LEARN_NOTE: TowerBase scenes use this script on a Node2D root; stage-specific tower scenes override these exported values.
@export var tower_type: String = "stage_1_tower"
@export var display_name: String = "Stage 1 Tower"
@export var attack_range: float = 150.0
@export var damage: int = 2
@export var fire_interval: float = 0.8
@export var shot_flash_duration: float = 0.12
@export var barrel_length: float = 18.0
@export var recoil_distance: float = 5.0
@export var base_color: Color = Color(0.95, 0.65, 0.15, 1.0)
@export var sprite_texture: Texture2D

@onready var visual: Node2D = $Visual as Node2D
@onready var sprite: Sprite2D = $Visual/Sprite2D as Sprite2D
@onready var placeholder: Polygon2D = $Visual/Placeholder as Polygon2D
@onready var muzzle: Marker2D = $Muzzle as Marker2D
@onready var range_shape: CollisionShape2D = $AttackRange/CollisionShape2D as CollisionShape2D

# LEARN_NOTE: These runtime values handle firing cooldown and the brief visible shot animation.
var cooldown_remaining: float = 0.0
var shot_flash_remaining: float = 0.0
var shot_line_end: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	apply_visuals()
	update_range_shape()
	queue_redraw()

func apply_visuals() -> void:
# LEARN_NOTE: Like attackers, towers can use a real Sprite2D when assigned, or fall back to a simple drawn placeholder.
	if sprite != null and sprite_texture != null:
		sprite.texture = sprite_texture
		sprite.visible = true
		sprite.modulate = base_color
		if placeholder != null:
			placeholder.visible = false
	elif placeholder != null:
		placeholder.visible = true
		placeholder.color = base_color

func update_range_shape() -> void:
# LEARN_NOTE: AttackRange is an Area2D child for future collision/range features; right now drawing/targeting still use attack_range directly.
	if range_shape == null:
		return

	var circle_shape: CircleShape2D = range_shape.shape as CircleShape2D
	if circle_shape == null:
		circle_shape = CircleShape2D.new()
		range_shape.shape = circle_shape
	circle_shape.radius = attack_range

func _process(delta: float) -> void:
# LEARN_NOTE: Each frame, the tower counts down its cooldown, then searches for an attacker if it is ready to fire.
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)
	var was_showing_shot: bool = shot_flash_remaining > 0.0
	shot_flash_remaining = maxf(shot_flash_remaining - delta, 0.0)
	if was_showing_shot:
		queue_redraw()

	if cooldown_remaining > 0.0:
		return

	var target: PathFollow2D = find_target()
	if target == null:
		return

	fire_at(target)
	cooldown_remaining = fire_interval

func fire_at(target: PathFollow2D) -> void:
# LEARN_NOTE: The shot is instant for now: draw a flash line, then call take_damage on the chosen attacker.
	var shot_origin: Vector2 = Vector2.ZERO
	if muzzle != null:
		shot_origin = muzzle.position

	shot_line_end = to_local(target.global_position)
	var aim_vector: Vector2 = shot_line_end - shot_origin
	if not aim_vector.is_zero_approx():
		aim_direction = aim_vector.normalized()
	shot_flash_remaining = shot_flash_duration
	target.call("take_damage", damage)
	queue_redraw()

func find_target() -> PathFollow2D:
# LEARN_NOTE: This scans the "attackers" group and chooses the closest attacker inside attack_range.
	var closest_target: PathFollow2D = null
	var closest_distance: float = attack_range

	for node: Node in get_tree().get_nodes_in_group("attackers"):
		var attacker: PathFollow2D = node as PathFollow2D
		if attacker == null:
			continue

		var distance_to_attacker: float = global_position.distance_to(attacker.global_position)
		if distance_to_attacker <= closest_distance:
			closest_target = attacker
			closest_distance = distance_to_attacker

	return closest_target

func _draw() -> void:
# LEARN_NOTE: _draw is used for prototype visuals: range circle, shot flash, and placeholder tower art.
	draw_circle(Vector2.ZERO, attack_range, Color(1.0, 0.75, 0.2, 0.12))
	var shot_progress: float = 0.0
	var shot_origin: Vector2 = Vector2.ZERO
	if muzzle != null:
		shot_origin = muzzle.position

	if shot_flash_remaining > 0.0:
		shot_progress = shot_flash_remaining / shot_flash_duration
		draw_line(shot_origin, shot_line_end, Color(1.0, 0.95, 0.35, shot_progress), 4.0)

	if sprite != null and sprite.visible:
		if shot_progress > 0.0:
			draw_circle(shot_origin, 4.0 + (7.0 * shot_progress), Color(1.0, 0.95, 0.35, 0.6 * shot_progress))
		return

	var recoil_offset: Vector2 = -aim_direction * recoil_distance * shot_progress
	var barrel_start: Vector2 = recoil_offset
	var barrel_end: Vector2 = recoil_offset + (aim_direction * barrel_length)
	var muzzle_radius: float = 4.0 + (7.0 * shot_progress)

	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.85, 0.25, 0.25 * shot_progress))
	draw_line(barrel_start, barrel_end, Color(0.24, 0.14, 0.06, 1.0), 7.0)
	draw_line(barrel_start, barrel_end, Color(0.95, 0.7, 0.25, 1.0), 3.0)
	if shot_progress > 0.0:
		draw_circle(barrel_end, muzzle_radius, Color(1.0, 0.95, 0.35, 0.6 * shot_progress))
	draw_circle(Vector2.ZERO, 6.0, Color(0.2, 0.12, 0.05, 1.0))
	draw_circle(Vector2.ZERO, 12.0, base_color)
