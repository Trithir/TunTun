extends Node2D

@export var attack_range: float = 150.0
@export var damage: int = 2
@export var fire_interval: float = 0.8
@export var shot_flash_duration: float = 0.12
@export var barrel_length: float = 18.0
@export var recoil_distance: float = 5.0

var cooldown_remaining: float = 0.0
var shot_flash_remaining: float = 0.0
var shot_line_end: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
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
	shot_line_end = to_local(target.global_position)
	if not shot_line_end.is_zero_approx():
		aim_direction = shot_line_end.normalized()
	shot_flash_remaining = shot_flash_duration
	target.call("take_damage", damage)
	queue_redraw()

func find_target() -> PathFollow2D:
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
	draw_circle(Vector2.ZERO, attack_range, Color(1.0, 0.75, 0.2, 0.12))
	var shot_progress: float = 0.0
	if shot_flash_remaining > 0.0:
		shot_progress = shot_flash_remaining / shot_flash_duration
		draw_line(Vector2.ZERO, shot_line_end, Color(1.0, 0.95, 0.35, shot_progress), 4.0)

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
	draw_circle(Vector2.ZERO, 12.0, Color(0.95, 0.65 + (0.25 * shot_progress), 0.15, 1.0))
