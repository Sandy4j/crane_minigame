extends Node

const POOLS = {
	1: {
		"chance": 85.0,
		"items": ["bianlian", "bluespirit", "tengu"]
	},
	2: {
		"chance": 12.0,
		"items": ["dewi", "kitsune"]
	},
	3: {
		"chance": 3.0,
		"items": ["cepot"]
	}
}

func get_random_reward() -> Dictionary:
	var roll = randf() * 100.0
	var rarity = 1
	var cumulative = 0.0

	for r in POOLS:
		cumulative += POOLS[r]["chance"]
		if roll <= cumulative:
			rarity = r
			break

	var pool = POOLS[rarity]["items"]
	var item_name = pool[randi() % pool.size()]

	return {
		"name": item_name,
		"rarity": rarity,
		"texture_path": "res://Asset/item hadiah/decorations_wall_" + item_name + ".png"
	}
