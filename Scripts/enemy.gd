extends CharacterBody3D

@export var speed: float = 5.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0
 
var player: Node3D 
var attack_timer: float = 0.0 
var can_attack: bool = true

func _ready():
	# Find the player in the scene 
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player and is_instance_valid(player):
		# Move toward the player
		var direction = (player.global_transform.origin - global_transform.origin).normalized()
		velocity = direction * speed
		move_and_slide()

		# Check for collision with player to deal damage
		if can_attack and is_colliding_with_player():
			deal_damage()
			start_attack_cooldown(delta)

	# Update attack cooldown
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true

func is_colliding_with_player() -> bool:
	# Check if the enemy is colliding with the player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() and collision.get_collider().is_in_group("player"):
			return true
	return false

func deal_damage():
	# Apply damage to the player 
	if player.has_method("take_damage"):
		player.take_damage(damage)

func start_attack_cooldown(_delta):
	can_attack = false
	attack_timer = attack_cooldown
