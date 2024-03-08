extends CharacterBody3D

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const sensitivity = 0.0007
const gravity = 9.8
const walk_speed = 3.0
const crouch_speed = 1.5
const sprint_speed = 5.5
const jump_velocity = 6.8
const head_height = 0.558

var speed
var crouch_depth = -0.7
# var prone_depth = -1.4

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ONREADY VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var standing_collision_shape = $Standing_CollisionShape3D
@onready var crouching_collision_shape = $Crouching_CollisionShape3D
@onready var player_raycast = $RayCast3D

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
func _ready():
	# Disable cursor 
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# F3 to get debug stats
	Engine.get_frames_per_second()


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# when mouse up/down -> control y angle: rotate about x axis
		head.rotate_y(-event.relative.x * sensitivity)
		# when mouse left/right -> control x angle: rotate about y axis
		camera.rotate_x(-event.relative.y * sensitivity)
		# limit y angle rotation by clamping camera.rotation.x
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(50))


func _physics_process(delta):
	# Add Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta * 1.8

	# Jump Handling
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement & Speed Handling
	# Crouching State
	if Input.is_action_pressed("crouch"):
		speed = crouch_speed
		head.position.y = lerp(head.position.y, head_height + crouch_depth, delta * 4.5)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false

	# Standing State
	elif !player_raycast.is_colliding():
		head.position.y = lerp(head.position.y, head_height, delta * 4.5)
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true

		# Sprinting
		if Input.is_action_pressed("sprint"):
			speed = sprint_speed
		# Walking
		else:
			speed = walk_speed

	# Movement Handling
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Add Inertia
	if is_on_floor():
		# Starting Speed
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 8.0)
			velocity.y = lerp(velocity.y, direction.y * speed, delta * 8.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 8.0)
		# Stopping Speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 11.0)
			velocity.y = lerp(velocity.y, direction.y * speed, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 11.0)
	# In Air
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 1.5)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 1.5)

	move_and_slide()


	# Exit Program
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

