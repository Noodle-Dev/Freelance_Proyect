extends CharacterBody2D

# Constants
const MAX_SPEED = 450.0
const ACCELERATION = 2500.0  
const DECELERATION = 1700.0  
const JUMP_VELOCITY = -600.0
const GRAVITY = 1300.0
const BOUNCE_FORCE = -200.0  
const CAMERA_SMOOTHNESS = 0.1  
const MAX_JUMPS = 2  
const KNOCKBACK_FORCE_X = 2000.0  
const KNOCKBACK_FORCE_Y = -1500.0  
const INVULNERABILITY_DURATION = 1.0  
const PROJECTILE_SCENE = preload("res://assets/prefabs/Player/Bullet_Dorito_Balta.tscn")  
const SHIELD_DURATION = 5.0  
const DAMAGE_BOOST_DURATION = 5.0  

# Variables
@export var is_player_one: bool = true  # Variable editable desde el inspector para elegir el jugador
var is_invulnerable = false  
var is_damage_boosted = false  
var jump_count = 0  
var current_speed = 0.0  
var is_crouching = false  
var is_shooting = false  
var is_walking = false  # Para controlar el sonido de caminar

@onready var camera_2d = $"../Camera2D"
@onready var walk_sound = $WalkSound  # Nodo de audio para el sonido de caminar

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Definir controles dinámicamente según el jugador
	var player_prefix = "P1" if is_player_one else "P2"
	var jump_action = "jump_" + player_prefix
	var left_action = "left_" + player_prefix
	var right_action = "right_" + player_prefix
	var crouch_action = "crouch_" + player_prefix
	var shoot_action = "shoot_" + player_prefix

	# Manejar agachado
	if Input.is_action_pressed(crouch_action):
		if not is_crouching:
			is_crouching = true
			$Sprite2D.play("crouch")
		velocity.x = 0  
	else:
		is_crouching = false

	# Movimiento horizontal
	var direction = Input.get_axis(left_action, right_action)
	if direction != 0 and not is_crouching:
		current_speed = lerp(current_speed, float(direction * MAX_SPEED), ACCELERATION * delta / MAX_SPEED)
		
		# Sonido de caminar
		if not is_walking:
			is_walking = true
			walk_sound.play()  # Inicia el sonido de caminar
	else:
		current_speed = lerp(current_speed, 0.0, DECELERATION * delta / MAX_SPEED)
		
		# Detener sonido al dejar de caminar
		if is_walking:
			is_walking = false
			walk_sound.stop()

	velocity.x = current_speed

	# Voltear sprite según dirección
	if direction != 0:
		$Sprite2D.flip_h = direction < 0

	# Manejar saltos
	if Input.is_action_just_pressed(jump_action) and jump_count < MAX_JUMPS and not is_crouching:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	# Resetear salto al tocar el suelo
	if is_on_floor():
		jump_count = 0

	# Manejar disparos
	if Input.is_action_just_pressed(shoot_action):
		_shoot_projectile()
		is_shooting = true
		$Sprite2D.play("shoot")
	elif $Sprite2D.animation == "shoot" and not $Sprite2D.is_playing():
		is_shooting = false

	# Actualizar animaciones y cámara
	_update_animations(direction)
	_update_camera()

	# Mover al jugador
	move_and_slide()

func _update_animations(direction):
	if is_shooting:
		return  
	
	if is_invulnerable:
		$Sprite2D.play("shield")  
		return
	
	if is_crouching:
		if is_damage_boosted:
			$Sprite2D.play("crouch_boost")  
		else:
			$Sprite2D.play("crouch")
		return

	if not is_on_floor():
		if is_damage_boosted:
			$Sprite2D.play("jump_boost")  
		else:
			$Sprite2D.play("jump")
	elif direction != 0:
		if is_damage_boosted:
			$Sprite2D.play("run_boost")  
		else:
			$Sprite2D.play("run")
	else:
		if is_damage_boosted:
			$Sprite2D.play("idle_boost")  
		else:
			$Sprite2D.play("idle")

func _update_camera():
	if camera_2d:
		var target_position = position
		camera_2d.position = camera_2d.position.lerp(target_position, CAMERA_SMOOTHNESS)

func _shoot_projectile():
	var projectile = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(30 if not $Sprite2D.flip_h else -30, 0)  
	projectile.velocity = Vector2(600 if not $Sprite2D.flip_h else -600, 0)  
	if is_damage_boosted:
		projectile.damage *= 2  

# Power-Up Functions
func activate_shield():
	print("Shield activated!")
	is_invulnerable = true
	$Sprite2D.play("shield")
	await get_tree().create_timer(SHIELD_DURATION).timeout
	_deactivate_shield()

func _deactivate_shield():
	is_invulnerable = false
	$Sprite2D.play("shield_end")  # Animación cuando termina el escudo
	print("Shield ended!")

func activate_damage_boost():
	print("Damage Boost activated!")
	is_damage_boosted = true
	$Sprite2D.play("boost_start")  # Animación al activar el boost
	await get_tree().create_timer(DAMAGE_BOOST_DURATION).timeout
	_deactivate_damage_boost()

func _deactivate_damage_boost():
	is_damage_boosted = false
	$Sprite2D.play("boost_end")  # Animación al terminar el boost
	print("Damage Boost ended!")
