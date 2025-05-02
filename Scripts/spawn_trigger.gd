extends Area3D
@export var enemy_scene: PackedScene 
@export var spawn_position: Node3D 
var has_spawned = false

func _ready(): 
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node): 
	if body.is_in_group("player") and not has_spawned:
		spawn_enemy()
		has_spawned = true

func spawn_enemy():
	if enemy_scene and spawn_position: 
		var enemy = enemy_scene.instantiate() 
		get_tree().current_scene.add_child(enemy) 
		enemy.global_transform.origin = spawn_position.global_transform.origin

func reset():
	has_spawned = false
