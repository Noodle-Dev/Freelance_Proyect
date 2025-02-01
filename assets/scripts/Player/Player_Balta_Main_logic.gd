extends CharacterBody2D

@export var speed: float = 300.0
@export var acceleration: float = 1000.0
@export var jump_force: float = -500.0
@export var gravity: float = 1000.0
@export var coyote_time: float = 0.15
@export var projectile_scene: PackedScene

var is_crouching: bool = false
var coyote_timer: float = 0.0

@onready var anim_player = $Sprite

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
		coyote_timer -= delta
	else:
		coyote_timer = coyote_time
	
	# Get input
	var direction = Input.get_axis("left_P1", "right_P1")
	
	# Move left or right with acceleration
	if direction and not is_crouching:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		$Sprite.flip_h = direction < 0  # Flip sprite based on direction
		anim_player.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		anim_player.play("idle")
	
	# Jump with coyote time
	if Input.is_action_just_pressed("jump_P1") and coyote_timer > 0:
		velocity.y = jump_force
		coyote_timer = 0
		anim_player.play("jump")
	
	# Crouch
	if Input.is_action_pressed("crouch_P1"):
		is_crouching = true
		velocity.x = 0  # Stop horizontal movement when crouching
		anim_player.play("crouch")
	else:
		is_crouching = false
	
	# Shoot projectile
	if Input.is_action_just_pressed("shoot_P1"):
		shoot_projectile()
		anim_player.play("shoot")
	
	move_and_slide()

func shoot_projectile():
	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		projectile.position = global_position
		projectile.direction = Vector2.RIGHT if velocity.x >= 0 else Vector2.LEFT
		get_parent().add_child(projectile)
