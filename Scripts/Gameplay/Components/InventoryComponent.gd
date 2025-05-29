class_name InventoryComponent
extends Component

var items: Array[Weapon] = []

func add_item(item: Weapon) -> void:
	items.append(item)

func remove_item(item: Weapon) -> void:
	items.erase(item)

func get_weapon(index: int) -> Weapon:
	return items[index] if index >= 0 and index < items.size() else null
