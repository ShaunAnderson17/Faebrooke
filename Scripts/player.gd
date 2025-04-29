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
var running = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	 

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_horiz))
		visuals.rotate_y(deg_to_rad(event.relative.x * sens_horiz))
		camera_mount.rotate_x(deg_to_rad(-event.relative.y * sens_vert))
		
		var cam_rot = camera_mount.rotation_degrees
		cam_rot.x = clamp(cam_rot.x, -90,90)
		camera_mount.rotation_degrees = cam_rot


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("run"):
		SPEED = running_speed  
		running = true 
	else: 
		SPEED = walking_speed  
		running = false
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		#animation_player.play("jump")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
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
