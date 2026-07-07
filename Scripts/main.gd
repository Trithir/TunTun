extends Node2D

@onready var path_points: Node2D = $Map/Path/PathPoints
@onready var start_point: Marker2D = $Map/StartPoint
@onready var end_point: Marker2D = $Map/EndPoint
@onready var build_zones: Node2D = $Map/BuildZones

func _ready() -> void:
	var points := get_path_points()
	print("Map ready: %s path points, %s build zones" % [points.size(), build_zones.get_child_count()])

func get_path_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for child in path_points.get_children():
		if child is Marker2D:
			points.append(child.global_position)
	return points
