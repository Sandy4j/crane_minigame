extends Node

## Format JSON: array of [name, rarity, weight]
const REWARDS_PATH := "res://Scripts/Autoload/rewards.json"

var _items: Array[Dictionary] = []
var _total_weight: float = 0.0

func _ready() -> void:
	_load_from_json()

func _load_from_json() -> void:
	if not FileAccess.file_exists(REWARDS_PATH):
		push_error("PoolsRewards: file tidak ditemukan → " + REWARDS_PATH)
		return

	var file := FileAccess.open(REWARDS_PATH, FileAccess.READ)
	if file == null:
		push_error("PoolsRewards: gagal membuka file → " + REWARDS_PATH)
		return

	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if not data is Array:
		push_error("PoolsRewards: format JSON tidak valid, harus berupa Array")
		return

	_items.clear()
	_total_weight = 0.0

	for entry in data:
		if not entry is Array or entry.size() < 3:
			push_error("PoolsRewards: entry tidak valid (butuh [name, rarity, weight]) → " + str(entry))
			continue

		var item_name: String = str(entry[0])
		var rarity: int = int(entry[1])
		var weight: float = float(entry[2])

		if weight <= 0.0:
			push_error("PoolsRewards: weight harus > 0 untuk item '%s'" % item_name)
			continue

		_items.append({
			"name": item_name,
			"rarity": rarity,
			"weight": weight,
		})
		_total_weight += weight

	if _items.is_empty():
		push_error("PoolsRewards: tidak ada item valid yang berhasil dimuat")

func get_random_reward() -> Dictionary:
	if _items.is_empty() or _total_weight <= 0.0:
		push_error("PoolsRewards: pool kosong, tidak bisa mengambil reward")
		return {}

	var roll := randf() * _total_weight
	var cumulative := 0.0

	for item in _items:
		cumulative += item["weight"]
		if roll <= cumulative:
			return {
				"name": item["name"],
				"rarity": item["rarity"],
				"texture_path": "res://Asset/item hadiah/decorations_wall_" + item["name"] + ".png"
			}

	## Fallback: kembalikan item terakhir jika terjadi kesalahan perhitungan
	var last: Dictionary = _items.back()
	return {
		"name": last["name"],
		"rarity": last["rarity"],
		"texture_path": "res://Asset/item hadiah/decorations_wall_" + last["name"] + ".png"
	}
