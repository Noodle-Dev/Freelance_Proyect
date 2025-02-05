extends Node2D

func _on_area_2d_body_entered(body):
	if body is CharacterBody2D:
		body.activate_damage_boost()  # Llama a la función del jugador
		queue_free()  # Elimina el pickup después de recogerlo
