extends CharacterBody2D

# Constants
const MAX_SPEED = 450.0
const ACCELERATION = 2500.0  # Acceleration factor for smoother movement
const DECELERATION = 1700.0  # Deceleration factor when stopping
const JUMP_VELOCITY = -600.0
const GRAVITY = 1300.0
const BOUNCE_FORCE = -200.0  # Force applied when bouncing off enemies
const CAMERA_SMOOTHNESS = 0.1  # Lower values = smoother camera follow
const MAX_JUMPS = 2  # Maximum number of jumps (double jump)
const KNOCKBACK_FORCE_X = 2000.0  # Horizontal knockback force
const KNOCKBACK_FORCE_Y = -1500.0  # Vertical knockback force
const INVULNERABILITY_DURATION = 1.0  # Duration of invulnerability after damage
const PROJECTILE_SCENE = preload("res://assets/prefabs/Player/Bullet_Dorito_Balta.tscn")  # Load the projectile scene
const SHIELD_DURATION = 5.0  # Shield lasts 5 seconds
const DAMAGE_BOOST_DURATION = 5.0  # Damage boost lasts 5 seconds

# Variables
var is_invulnerable = false  # Temporarily avoid damage after hitting an enemy
var is_damage_boosted = false  # Double damage effect
var jump_count = 0  # Tracks the number of jumps
var current_speed = 0.0  # Tracks the current horizontal speed
var is_crouching = false  # Check if player is crouching
var is_shooting = false  # Check if player is shooting
@onready var camera_2d = $"../Camera2D"

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle crouching
	if Input.is_action_pressed("crouch_P1"):
		if not is_crouching:
			is_crouching = true
			$Sprite2D.play("crouch")
		velocity.x = 0  # Stop horizontal movement while crouching
	else:
		is_crouching = false

	# Handle horizontal movement with acceleration and deceleration
	var direction = Input.get_axis("left_P1", "right_P1")
	if direction != 0 and not is_crouching:
		current_speed = lerp(current_speed, float(direction * MAX_SPEED), ACCELERATION * delta / MAX_SPEED)
	else:
		current_speed = lerp(current_speed, 0.0, DECELERATION * delta / MAX_SPEED)
	velocity.x = current_speed

	# Flip the sprite based on movement direction
	if direction != 0:
		$Sprite2D.flip_h = direction < 0

	# Handle jumping and double jump
	if Input.is_action_just_pressed("jump_P1") and jump_count < MAX_JUMPS and not is_crouching:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	# Reset jump count when on the floor
	if is_on_floor():
		jump_count = 0

	# Handle shooting
	if Input.is_action_just_pressed("shoot_P1"):
		_shoot_projectile()
		is_shooting = true
		$Sprite2D.play("shoot")
	elif $Sprite2D.animation == "shoot" and not $Sprite2D.is_playing():
		is_shooting = false

	# Play animations based on state
	_update_animations(direction)

	# Smooth camera follow
	_update_camera()

	# Move the player
	move_and_slide()

func _update_animations(direction):
	if is_shooting:
		return  # No interrumpe la animación de disparo
	
	if is_invulnerable:
		$Sprite2D.play("shield")  # Siempre muestra el escudo mientras está activo
		return
	
	if is_crouching:
		if is_damage_boosted:
			$Sprite2D.play("crouch_boost")  # Animación especial para agachado con daño boost
		else:
			$Sprite2D.play("crouch")
		return

	if not is_on_floor():
		if is_damage_boosted:
			$Sprite2D.play("jump_boost")  # Animación especial para salto con daño boost
		else:
			$Sprite2D.play("jump")
	elif direction != 0:
		if is_damage_boosted:
			$Sprite2D.play("run_boost")  # Animación especial para correr con daño boost
		else:
			$Sprite2D.play("run")
	else:
		if is_damage_boosted:
			$Sprite2D.play("idle_boost")  # Animación especial para estar quieto con daño boost
		else:
			$Sprite2D.play("idle")

func _update_camera():
	if camera_2d:
		var target_position = position
		camera_2d.position = camera_2d.position.lerp(target_position, CAMERA_SMOOTHNESS)

func _shoot_projectile():
	var projectile = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(30 if not $Sprite2D.flip_h else -30, 0)  # Adjust spawn position
	projectile.velocity = Vector2(600 if not $Sprite2D.flip_h else -600, 0)  # Adjust velocity direction
	if is_damage_boosted:
		projectile.damage *= 2  # Double the damage if power-up is active

# Power-Up Functions
func activate_shield():
	$Sprite2D.play("shield")
	print("Shield activated!")
	is_invulnerable = true
	#$Sprite2D.modulate = Color(0.5, 0.5, 1.0)  # Change player color to indicate shield
	await get_tree().create_timer(SHIELD_DURATION).timeout
	is_invulnerable = false
	#$Sprite2D.modulate = Color(1, 1, 1)  # Revert player color

func activate_damage_boost():
	print("Damage Boost activated!")
	is_damage_boosted = true
	#$Sprite2D.modulate = Color(1.0, 0.5, 0.5)  # Change player color to indicate damage boost
	await get_tree().create_timer(DAMAGE_BOOST_DURATION).timeout
	is_damage_boosted = false
	#$Sprite2D.modulate = Color(1, 1, 1)  # Revert player color
