extends Control

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var death_screen: PanelContainer = $DeathScreen
@onready var pickup_prompt: Label = $PickupPrompt
@onready var hotbar: HBoxContainer = $Hotbar
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_item_list: VBoxContainer = $InventoryPanel/VBoxContainer/ItemList

var player: Node
var hotbar_slots: Array = []

func _ready():
	print("HUD _ready: Initializing...")
	print("HUD children:")
	for child in get_children():
		print(" - ", child.name, " (", child.get_class(), ")")
	if not health_bar:
		push_error("HealthBar not assigned in inspector.")
		return
	if not health_label:
		push_error("HealthLabel not assigned in inspector.")
		return
	if not death_screen:
		push_error("DeathScreen not assigned in inspector.")
		return

	player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player found: ", player)
		health_bar.max_value = player.max_health
		health_bar.value = player.health
		update_health_label()
	else:
		push_error("Player not found in 'player' group.")
		
	#initialize hotbar slots
	for i in range(5):
		hotbar_slots.append(hotbar.get_node("Slot" + str(i + 1)))
	pickup_prompt.visible = false
	inventory_panel.visible = false
	
func show_pickup_prompt(show: bool):
	pickup_prompt.visible = show
	pickup_prompt.text = "Press E to pickup item"
	
func update_hotbar(hotbar_data: Array, selected_index: int):
	for i in range(hotbar_data.size()):
		var slot = hotbar_slots[i]
		if hotbar_data[i] == -1:
			slot.texture = null
		else:
			slot.texture = preload("res://Assets/Screenshot 2025-05-05 134353.png")
			slot.modulate = Color(1,1,0) if i == selected_index else Color(1,1,1)

func toggle_inventory():
	inventory_panel.visable = !inventory_panel.visable
	if inventory_panel.visible:
		update_inventory_display()

func update_inventory_display():
	for child in inventory_item_list.get_children():
		child.queue_free()
	for item in player.inventory:
		var label = Label.new()
		label.text = "Item: %s (ID: %d)" % [item.name, item.id]
		inventory_item_list.add_child(label)

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
		#get_tree().paused = true
		var respawn_button: Button = $DeathScreen/VBoxContainer/RespawnButton
		if respawn_button:
			respawn_button.grab_focus()
			print("Death screen shown, focus set to RespawnButton")
	else:
		push_error("Cannot show death screen: DeathScreen is null.")

func _on_respawn_button_pressed():
	print("Respawn button pressed: player = ", player)
	if player and player.has_method("respawn"):
		print("Calling player.respawn()")
		player.respawn()
	else:
		push_error("Cannot respawn: Player is null or respawn method not found.")
	if death_screen:
		print("Hiding death screen and unpausing game")
		death_screen.visible = false
		get_tree().paused = false
