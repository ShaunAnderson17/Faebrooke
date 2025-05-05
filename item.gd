extends Area3D

@export var item_name: String = "Item"
@export var item_id: int = 0
@export var hotbar_icon = Texture2D

func _ready():
	add_to_group("item")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		body.set_nearby_item(self)
	
func _on_body_exited(body: Node):
	if body.is_in_group("player"):
		body.set_nearby_item(null)
