extends CharacterBody3D

@onready var camera_mount: Node3D = $camera_mount
@onready var animation_player: AnimationPlayer = $visuals/mixamo_base/AnimationPlayer
@onready var visuals: Node3D = $visuals

var SPEED = 3.0
const JUMP_VELOCITY = 4.5

@export var walking_speed = 3.0
@export var running_speed = 7.0
@export var sens_horiz = 0.5
@export var sens_vert = 0.5
@export var max_health: float = 100.0

var running = false
var health: float
var hud: Control
var initial_position: Vector3
var respawn_point: Node3D

func _ready():
	health = max_health
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	initial_position = global_transform.origin
	hud = get_tree().current_scene.get_node("CanvasLayer/Hud")
	if not hud:
		push_error("HUD node not found in scene tree.")
	respawn_point = get_tree().current_scene.get_node("RespawnPoint")
	if respawn_point:
		print("RespawnPoint found at: ", respawn_point.global_transform.origin)
	else:
		push_error("RespawnPoint node not found in scene tree.")

func take_damage(damage: float):
	health -= damage
	health = clamp(health, 0, max_health)
	if hud:
		hud.update_health(health)
	print("Player took %s damage. Health: %s" % [damage, health])
	if health <= 0:
		die()

func die():
	print("Player died! Mouse mode: ", Input.MOUSE_MODE_VISIBLE)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if hud and hud.has_method("show_death_screen"):
		hud.show_death_screen()

func respawn():
	print("Respawning player...")
	health = max_health
	if respawn_point:
		global_transform.origin = respawn_point.global_transform.origin
		print("Respawned at RespawnPoint: ", global_transform.origin)
	else:
		push_error("Cannot respawn: RespawnPoint is null.")
		global_transform.origin = Vector3.ZERO
		print("Respawned at fallback position: ", global_transform.origin)
	if hud:
		hud.update_health(health)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var enemy = get_tree().get_first_node_in_group("enemy")
	if enemy:
		print("Removing enemy: ", enemy)
		enemy.queue_free()
	var trigger = get_tree().current_scene.get_node("SpawnTrigger")
	if trigger and trigger.has_method("reset"):
		print("Resetting SpawnTrigger")
		trigger.reset()

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_horiz))
		visuals.rotate_y(deg_to_rad(event.relative.x * sens_horiz))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * sens_vert))
		var cam_rot = camera_mount.rotation_degrees
		cam_rot.x = clamp(cam_rot.x, -90, 90)
		camera_mount.rotation_degrees = cam_rot
	elif event is InputEventMouseMotion:
		print("Mouse left click detected at ", event.position)

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("run"):
		SPEED = running_speed
		running = true
	else:
		SPEED = walking_speed
		running = false

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		if running:
			if animation_player.current_animation != "running":
				animation_player.play("running")
		else:
			if animation_player.current_animation != "walking":
				animation_player.play("walking")
		visuals.look_at(position + direction)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
