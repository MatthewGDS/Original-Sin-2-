extends Area2D


var entered = false

func _on_Area2D_body_entered(body: PhysicsBody2D):
	entered = true


func _on_Area2D_body_exited(body):
	entered = false


func _process(delta):
	if entered:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().change_scene("res://Battle/Battle 2.tscn")
