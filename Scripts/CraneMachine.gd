extends Node2D


func _on_drop_zone_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	if area.is_in_group("box"):
		area.queue_free()
		print("masuk")
