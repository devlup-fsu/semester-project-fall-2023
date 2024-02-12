class_name Player
extends CharacterBody2D

@export var max_speed := 300.0
@export var turn_speed := deg_to_rad(90)
@export var strunned_speed := max_speed * 0.40
@export var speed_degredation := 0.9

@export var player := 0
@export var cannon_ball_parent: Node
@export var shoot_delay := 0.5

@onready var treasure_collector: PickupCollector = $PickupCollector
@onready var vulnerability_timer: Timer = $VulnerabilityTimer
@onready var left_cannon: Marker2D = $LeftCannon
@onready var left_cannon_timer: Timer = $LeftCannon/Timer
@onready var right_cannon: Marker2D = $RightCannon
@onready var right_cannon_timer: Timer = $RightCannon/Timer

var speed: float = 0
var current_speed: float = max_speed 

var current_pickup: Pickup = null

func _ready() -> void:
	assert(cannon_ball_parent != null, "Player: property [cannon_parent] must not be null.")
	
	$AnimatedSprite2D.play("player" + str(self.player))


func _physics_process(delta: float) -> void:
	var input := InputManager.get_gamepad(player)
	
	var input_dir := Vector2()
	input_dir.x = input.get_turning()
	input_dir.y = 1
	
	speed = clamp((input_dir.y * 30) + (speed), 0, current_speed)
	
	var target := Vector2(cos(rotation), sin(rotation)).rotated(input_dir.x * turn_speed * delta * (1 + speed / max_speed * 24))
	var direction = lerp(target, velocity.normalized(), speed / current_speed * 0.9)
	
	if input_dir:
		velocity = direction * speed
		look_at(global_position + direction)    # Rotate the player to face the direction they are moving.

	move_and_collide(velocity * delta)
	
	# Loop around the screen.
	if global_position.x <= -1190:
		global_position.x = 1189
	elif global_position.x >= 1190:
		global_position.x = -1189
	
	if global_position.y <= -598:
		global_position.y = 691
	elif global_position.y >= 692:
		global_position.y = -597


func _process(_delta: float) -> void:
	var input: InputManager.InputProxy = InputManager.get_gamepad(player)
	
	if input.is_shoot_left_pressed():
		if left_cannon_timer.is_stopped():
			CannonBall.create(cannon_ball_parent, left_cannon.global_position, Vector2.UP.rotated(rotation))
			left_cannon_timer.start(shoot_delay)
	
	if input.is_shoot_right_pressed():
		if right_cannon_timer.is_stopped():
			CannonBall.create(cannon_ball_parent, right_cannon.global_position, Vector2.DOWN.rotated(rotation))
			right_cannon_timer.start(shoot_delay)


func score_treasure() -> void:
	#var score = treasure_collector.score_treasure()
	var score = 1
	Scores.add_player_score(player, score)


func accept_pickup(pickup: Pickup) -> void:
	if current_pickup != null and pickup.is_powerup: 
		current_pickup.remove_from(self)
		current_pickup = pickup
	pickup.apply_to(self)


func hit() -> void:
	treasure_collector.drop_treasure()
	current_speed = strunned_speed
	treasure_collector.disable()
	
	vulnerability_timer.start()
	await vulnerability_timer.timeout
	
	current_speed = max_speed
	treasure_collector.enable()
