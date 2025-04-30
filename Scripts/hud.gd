extends Control

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var death_screen: PanelContainer = $DeathScreen

var player: Node

func _ready():
	if not health_bar:
		push_error("HealthBar not assigned in inspector.")
		return
	if not health_label:
		push_error("HealthLabel not assigned in inspector.")
		return
	if not death_screen:
		push_error("DeathScreen not assigned in inspector.")
		return
		
	if player:
		health_bar.max_value = player.max_health
		health_bar.value = player.health
		update_health_label()
	var respawn_button: Button = $DeathScreen/VBoxContainer/RespawnButton
	if respawn_button:
			respawn_button.pressed.connect(_on_respawn_button_pressed)
	else:
		push_error("RespawnButton not found.")

func update_health(health: float):
	if health_bar:
		health_bar.value = health
		update_health_label()
	else:
		push_error("Cannot update health: HealthBar is null.")
		
func update_health_label():
	if health_bar and health_label:
		health_label.text = "%d/%d" % [health_bar.value, health_bar.max_value]
	else:
		push_error("Cannot update health label: HealthBar or HealthLabel is null.")

func show_death_screen():
	if death_screen:
		death_screen.visible = true
		get_tree().paused = true
	else:
		push_error("Cannot show death screen: DeathScreen is null.")

func _on_respawn_button_pressed():
	if player and player.has_method("respawn"):
		player.respawn()
	if death_screen:
		death_screen.visible = false
		get_tree().paused = false
