class_name PickupSpawner
extends Node2D


@export var pickup_type: Pickup
var pickup_scene: PackedScene = preload("res://Entities/Pickup/pickup2d.tscn")
## If false, this node must be used manually.
@export var is_timed := true
@export var wait_time := 3
## The maximum number of pickup that is allowed spawned at once without.
## being picked up. Set to 0 to not have a maximum.
@export_range(0, 10) var max_spawned_at_once := 3
## The maximum number of pickup that is allowed on the screen at once.
## Set to 0 to not have a maximum.
@export_range(0, 10) var max_on_screen_at_once := 5

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_markers: Array[Marker2D]


## Used to keep track of pickup that was spawned at a point and not yet moved
## so that more pickup doesn't spawn at that spot.
var blocking_pickup: Array[Pickup2D] = []
## Used to keep track of how many pickup have been spawned that are still on the board.
var pickups_spawned := 0


func _ready():
	for child in get_children():
		if child is Marker2D:
			spawn_markers.append(child)
	assert(spawn_markers.size() > 0, "PickupSpawner: Add Marker2D children")
	assert(pickup_scene != null)
	
	spawn_timer.wait_time = wait_time
	if is_timed:
		spawn_timer.start()


func enable_timer() -> void:
	spawn_timer.start()


func disable_timer() -> void:
	spawn_timer.stop()


func _on_spawn_timer_timeout() -> void:
	spawn_pickup(1)

func spawn_pickup(count: int) -> void:
	for i in range(count):
		for j in range(10):
			var selected_marker: Marker2D = spawn_markers.pick_random()
			
			if _try_spawn(selected_marker.global_position):
				break

func _try_spawn(global_pos: Vector2) -> bool:
	if pickups_spawned >= max_on_screen_at_once:
		return false
	
	if blocking_pickup.size() >= max_spawned_at_once:
		return false
	
	for pickup in blocking_pickup:
		if pickup.global_position == global_pos:
			return false
	
	var new_pickup: Pickup2D = pickup_scene.instantiate()
	
	new_pickup.pickup = pickup_type.duplicate()
	add_sibling(new_pickup)
	new_pickup.global_position = global_pos
	new_pickup.picked_up.connect(_on_pickup_collected)
	new_pickup.tree_exiting.connect(_on_pickup_erased)
	
	blocking_pickup.push_back(new_pickup)
	pickups_spawned += 1
	
	return true


func _on_pickup_collected(pickup: Pickup2D) -> void:
	blocking_pickup.erase(pickup)


func _on_pickup_erased(_pickup: Pickup) -> void:
	pickups_spawned -= 1
