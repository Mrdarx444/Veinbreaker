extends Node
class_name FlipComponent

@export var component_owner: Node2D = null
@export var disabled: bool = false

var flippable_nodes: Array[Node2D] = []
var current_direction: int = 1

func _ready() -> void:
	if disabled: return
	if not component_owner:
		push_warning("'%s': Can't find owner setting manually")
		component_owner = owner
	update_flipable_nodes()

func flip(dir: int = -current_direction) -> void:
	if disabled: return
	
	for node in flippable_nodes:
		if "flip_h" in node:
			node.flip_h = true if dir < 0 else false
		else :
			node.scale.x = abs(node.scale.x) * dir

func update_flipable_nodes():
	if disabled: return
	var all_grouped_nodes = get_tree().get_nodes_in_group("Flippable")
	if all_grouped_nodes.is_empty(): print("Empty")
	for node in all_grouped_nodes:
		if node.owner == component_owner or node == component_owner:
			flippable_nodes.append(node)
