extends CharacterBody3D

@onready var camera_mount: Node3D = $camera_mount
@onready var animation_player: AnimationPlayer = $visuals/mixamo_base/AnimationPlayer
@onready var visuals: Node3D = $visuals
@onready var hand_position: Node3D = $camera_mount/HandPosition

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

var inventory: Array = []
var hotbar: Array = []
var hotbar_index: int = 0
var nearby_item: Area3D = null
var held_item: MeshInstance3D = null

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
	
	hotbar.resize(5)
	hotbar.fill(-1)
	
func set_nearby_item(item: Area3D):
	nearby_item = item
	if hud and hud.has_method("show_pickup_prompt"):
		hud.show_pickup_prompt(item != null)

func pickup_item():
	if nearby_item:
		var item_data = {
			"id": nearby_item.item_id,
			"name": nearby_item.item_name,
			"mesh": nearby_item.get_node("MeshInstance3D").mesh
		}
		inventory.append(item_data)
		print("Picked up item: ", item_data)
		
		var empty_slot = hotbar.find(-1)
		if empty_slot != -1:
			hotbar[empty_slot] = item_data.id
			update_hotbar()
		nearby_item.queue_free()
		nearby_item = null
		if hud:
			hud.show_pickup_prompt(false)

func update_hotbar():
	if hud and hud.has_method("update_hotbar"):
		hud.update_hotbar(hotbar, hotbar_index)
	update_held_item()
	
func update_held_item():
	if held_item:
		held_item.queue_free()
		held_item = null
	var selected_item_id = hotbar[hotbar_index]
	if selected_item_id != -1:
		var item_data = inventory.filter(func(item): return item.id == selected_item_id)[0]
		held_item = MeshInstance3D.new()
		held_item.mesh = item_data.mesh
		hand_position.add_child(held_item)
		held_item.transform = Transform3D.IDENTITY
		held_item.scale = Vector3(0.5, 0.5, 0.5) #scale item down when holding


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
	elif event is InputEventKey and event.pressed:
		# Pickup item with E key
		if event.keycode == KEY_E and nearby_item:
			pickup_item()
		# Toggle inventory with I key
		if event.keycode == KEY_I:
			if hud and hud.has_method("toggle_inventory"):
				hud.toggle_inventory()
		# Hotbar selection with number keys
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var new_index = event.keycode - KEY_1
			if new_index != hotbar_index:
				hotbar_index = new_index
				update_hotbar()
	# Mouse wheel for hotbar selection
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			hotbar_index = (hotbar_index - 1 + hotbar.size()) % hotbar.size()
			update_hotbar()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			hotbar_index = (hotbar_index + 1) % hotbar.size()
			update_hotbar()

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
