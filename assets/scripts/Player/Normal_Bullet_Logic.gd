extends CharacterBody2D

@export var speed: float = 500.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 3.0

func _ready():
	velocity = direction * speed
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	move_and_slide()

func _on_body_entered(body):
	if body.is_in_group("enemies"):  # Asegúrate de agregar los enemigos a este grupo
		body.queue_free()  # O cualquier lógica de daño
	queue_free()
