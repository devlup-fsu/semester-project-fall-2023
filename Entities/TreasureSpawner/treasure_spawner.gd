## Will spawn 
class_name TreasureSpawner
extends Node2D

signal spawn_requested(position: Vector2, to_spawn: Node2D)

## Determines how much treasure is spawned, and where. Dependent on the [spawn_markers] array.
enum SpawnStrategy {
	## Each call to spawn() will place the newly created treasure in the next Marker2D's location,
	## as found in the [spawn_markers] array.
	Sequential,
	## Each call to spawn() will place the newly created treasure in a random Marker2D's location.
	Random,
	## Treasure will be spawned for every Marker2D in [spawn_markers]. Each Treasure will be in their
	## respective Marker2D's position.
	All
}

@export var spawn_strategy: SpawnStrategy = SpawnStrategy.Random
@export var is_timed := true
@export var wait_time := 3

@onready var spawn_timer: Timer = $SpawnTimer
@onready var treasure: PackedScene = preload("res://Entities/Treasure/treasure.tscn")
@onready var spawn_markers: Array[Marker2D]

## Used with TreasureSpawnerStrategy.Sequential to track which is next.
var index := 0


# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is Marker2D:
			spawn_markers.append(child)
	
	assert(spawn_markers.size() > 0, "TreasureSpawner: Add Marker2D children or set spawn_strategy to Self")
	
	spawn_timer.wait_time = wait_time
	
	if is_timed:
		spawn_timer.start()


func enable_timer() -> void:
	spawn_timer.start()


func disable_timer() -> void:
	spawn_timer.stop()


func _on_spawn_timer_timeout():
	print("TreasureSpawner: Timer went off.")
	spawn_treasure(1)


## Will spawn treasurea according to [spawn_strategy]
## Note that TreasureSpawnerStrategy.All will ignore [count]
func spawn_treasure(count: int) -> void:
	print("TreasureSpawner: Attempting to spawn " + str(count) + " treasures.")
	match spawn_strategy:
		SpawnStrategy.Sequential:
			_spawn_sequential(count)
		SpawnStrategy.Random:
			_spawn_random(count)
		SpawnStrategy.All:
			_spawn_all()
		_:
			assert(false, "TreasureSpawner: Unknown spawn strategy")


func _spawn_sequential(count: int) -> void:
	for i in range(count):
		var selected_marker: Marker2D = spawn_markers[index % spawn_markers.size()]
		var treasure_instance: Treasure = treasure.instantiate()
		emit_signal("spawn_requested", selected_marker.global_position, treasure_instance)
		index += 1


func _spawn_random(count: int) -> void:
	for i in range(count):
		var selected_marker: Marker2D = spawn_markers.pick_random()
		var treasure_instance: Treasure = treasure.instantiate()
		emit_signal("spawn_requested", selected_marker.global_position, treasure_instance)


func _spawn_all() -> void:
	for i in range(spawn_markers.size()):
		var selected_marker: Marker2D = spawn_markers[i]
		var treasure_instance: Treasure = treasure.instantiate()
		emit_signal("spawn_requested", selected_marker.global_position, treasure_instance)
