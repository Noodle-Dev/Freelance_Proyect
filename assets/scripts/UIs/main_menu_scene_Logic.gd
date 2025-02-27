extends Node2D


func _on_play_button_pressed():
	$Control/Transition/Trans_Player.play_backwards("Trans")
	await $Control/Transition/Trans_Player.animation_finished
	get_tree().change_scene_to_file("res://assets/scenes/Menus/Character_Selector.tscn")
	
func _on_how_to_play_button_pressed():
	pass # Replace with function body.
