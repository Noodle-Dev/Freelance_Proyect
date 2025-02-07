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

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Player controls dynamically assigned
	var player_prefix = "P1" if is_player_one else "P2"
	var jump_action = "jump_" + player_prefix
	var left_action = "left_" + player_prefix
	var right_action = "right_" + player_prefix
	var crouch_action = "crouch_" + player_prefix
	var shoot_action = "shoot_" + player_prefix

	# Crouch handling
	if Input.is_action_pressed(crouch_action):
		if not is_crouching:
			is_crouching = true
			_set_animation("crouch")
		velocity.x = 0  
	else:
		is_crouching = false

	# Horizontal movement
	var direction = Input.get_axis(left_action, right_action)
	if direction != 0 and not is_crouching:
		current_speed = lerp(current_speed, float(direction * MAX_SPEED), ACCELERATION * delta / MAX_SPEED)

		if is_on_floor() and not is_walking:
			is_walking = true
			walk_sound.play()  
	else:
		current_speed = lerp(current_speed, 0.0, DECELERATION * delta / MAX_SPEED)

		if is_walking and (direction == 0 or not is_on_floor()):
			is_walking = false
			walk_sound.stop()

	velocity.x = current_speed

	# Flip sprite direction
	if direction != 0:
		sprite.flip_h = direction < 0

	# Jump handling
	if Input.is_action_just_pressed(jump_action) and jump_count < MAX_JUMPS and not is_crouching:
		velocity.y = JUMP_VELOCITY
		jump_count += 1

	if is_on_floor():
		jump_count = 0

	# Shooting handling
	if Input.is_action_just_pressed(shoot_action) and not is_shooting:
		_shoot_projectile()
		is_shooting = true
		_set_animation("shoot")

	# Update animations and camera
	_update_animations(direction)
	_update_camera()

	move_and_slide()

func _update_animations(direction):
	if is_shooting:
		return  

	if is_invulnerable:
		_set_animation("shield")  
		return
	
	if is_crouching:
		_set_animation("crouch_boost" if is_damage_boosted else "crouch")
		return

	if not is_on_floor():
		_set_animation("jump_boost" if is_damage_boosted else "jump")
	elif direction != 0:
		_set_animation("run_boost" if is_damage_boosted else "run")
	else:
		_set_animation("idle_boost" if is_damage_boosted else "idle")

func _set_animation(anim_name):
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _update_camera():
	if camera_2d:
		camera_2d.position = camera_2d.position.lerp(position, CAMERA_SMOOTHNESS)

func _shoot_projectile():
	var projectile = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(30 if not sprite.flip_h else -30, 0)  
	projectile.velocity = Vector2(600 if not sprite.flip_h else -600, 0)  
	if is_damage_boosted:
		projectile.damage *= 2  

# Power-Up Functions
func activate_shield():
	print("Shield activated!")
	is_invulnerable = true
	_set_animation("shield")
	await get_tree().create_timer(SHIELD_DURATION).timeout
	_deactivate_shield()

func _deactivate_shield():
	is_invulnerable = false
	_set_animation("shield_end")  
	print("Shield ended!")

func activate_damage_boost():
	print("Damage Boost activated!")
	is_damage_boosted = true
	_set_animation("boost_start")  
	await get_tree().create_timer(DAMAGE_BOOST_DURATION).timeout
	_deactivate_damage_boost()

func _deactivate_damage_boost():
	is_damage_boosted = false
	_set_animation("boost_end")  
	print("Damage Boost ended!")
