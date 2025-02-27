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
@export var is_player_one: bool = true  
var is_invulnerable = false  
var is_damage_boosted = false  
var jump_count = 0  
var current_speed = 0.0  
var is_crouching = false  
var is_shooting = false  
var is_walking = false  

@onready var camera_2d = $"../Camera2D"
@onready var walk_sound = $WalkSound  
@onready var sprite = $Sprite2D  

# Estados del jugador
enum PlayerState {
	IDLE,
	RUN,
	JUMP,
	CROUCH,
	SHOOT,
	SHIELD,
	DAMAGE_BOOST
}

var current_state = PlayerState.IDLE
var previous_state = PlayerState.IDLE  # Para manejar transiciones

func _physics_process(delta):
	apply_gravity(delta)
	handle_player_input(delta)
	update_animations()
	update_camera()
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func handle_player_input(delta):
	var player_prefix = "P1" if is_player_one else "P2"
	var jump_action = "jump_" + player_prefix
	var left_action = "left_" + player_prefix
	var right_action = "right_" + player_prefix
	var crouch_action = "crouch_" + player_prefix
	var shoot_action = "shoot_" + player_prefix

	handle_crouch(crouch_action)
	handle_movement(delta, left_action, right_action)
	handle_jump(jump_action)
	handle_shooting(shoot_action)

func handle_crouch(crouch_action):
	if Input.is_action_pressed(crouch_action):
		if not is_crouching:
			is_crouching = true
			change_state(PlayerState.CROUCH)
		velocity.x = 0  
	else:
		is_crouching = false
		if current_state == PlayerState.CROUCH:
			change_state(PlayerState.IDLE)

func handle_movement(delta, left_action, right_action):
	var direction = Input.get_axis(left_action, right_action)
	if direction != 0 and not is_crouching:
		current_speed = lerp(current_speed, float(direction * MAX_SPEED), ACCELERATION * delta / MAX_SPEED)

		if is_on_floor() and not is_walking:
			is_walking = true
			walk_sound.play()  
		change_state(PlayerState.RUN)
	else:
		current_speed = lerp(current_speed, 0.0, DECELERATION * delta / MAX_SPEED)

		if is_walking and (direction == 0 or not is_on_floor()):
			is_walking = false
			walk_sound.stop()
		if current_state == PlayerState.RUN:
			change_state(PlayerState.IDLE)

	velocity.x = current_speed

	if direction != 0:
		sprite.flip_h = direction < 0

func handle_jump(jump_action):
	if Input.is_action_just_pressed(jump_action) and jump_count < MAX_JUMPS and not is_crouching:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
		change_state(PlayerState.JUMP)

	if is_on_floor():
		jump_count = 0
		if current_state == PlayerState.JUMP:
			change_state(PlayerState.IDLE)

func handle_shooting(shoot_action):
	if Input.is_action_just_pressed(shoot_action) and not is_shooting:
		_shoot_projectile()
		is_shooting = true
		change_state(PlayerState.SHOOT)
		await sprite.animation_finished
		is_shooting = false
		change_state(previous_state)  # Volver al estado anterior después de disparar

func update_animations():
	match current_state:
		PlayerState.IDLE:
			_set_animation("idle_boost" if is_damage_boosted else "idle")
		PlayerState.RUN:
			_set_animation("run_boost" if is_damage_boosted else "run")
		PlayerState.JUMP:
			_set_animation("jump_boost" if is_damage_boosted else "jump")
		PlayerState.CROUCH:
			_set_animation("crouch_boost" if is_damage_boosted else "crouch")
		PlayerState.SHOOT:
			_set_animation("shoot")
		PlayerState.SHIELD:
			_set_animation("shield")
		PlayerState.DAMAGE_BOOST:
			_set_animation("boost_start")

func _set_animation(anim_name):
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func update_camera():
	if camera_2d:
		camera_2d.position = camera_2d.position.lerp(position, CAMERA_SMOOTHNESS)

func _shoot_projectile():
	var projectile = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(30 if not sprite.flip_h else -30, 0)  
	projectile.velocity = Vector2(600 if not sprite.flip_h else -600, 0)  
	if is_damage_boosted:
		projectile.damage *= 2  

# Cambiar de estado
func change_state(new_state):
	if current_state != new_state:
		previous_state = current_state
		current_state = new_state
		update_animations()

# Power-Up Functions
func activate_shield():
	print("Shield activated!")
	is_invulnerable = true
	change_state(PlayerState.SHIELD)
	await get_tree().create_timer(SHIELD_DURATION).timeout
	_deactivate_shield()

func _deactivate_shield():
	is_invulnerable = false
	change_state(previous_state)
	print("Shield ended!")

func activate_damage_boost():
	print("Damage Boost activated!")
	is_damage_boosted = true
	change_state(PlayerState.DAMAGE_BOOST)
	await get_tree().create_timer(DAMAGE_BOOST_DURATION).timeout
	_deactivate_damage_boost()

func _deactivate_damage_boost():
	is_damage_boosted = false
	change_state(previous_state)
	print("Damage Boost ended!")
