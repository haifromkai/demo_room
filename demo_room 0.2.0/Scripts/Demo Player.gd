extends CharacterBody3D

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
const sensitivity = 0.0005
const gravity = 9.8
const walk_speed = 3.0
const crouch_speed = 1.4
const crawl_speed = 1.0
const sprint_speed = 5.5
const jump_velocity = 6.1
const head_height = 0.558

var speed = 0
var crouch_depth = -0.7
var crawl_depth = -1.3

var crawl_state = false
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ONREADY VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var standing_collision_shape = $Standing_CollisionShape3D
@onready var crouching_collision_shape = $Crouching_CollisionShape3D
@onready var crawling_collision_shape = $Crawling_CollisionShape3D
@onready var player_raycast = $RayCast3D
@onready var player_shapecast = $ShapeCast3D

# HUD
@onready var current_stance_state = $Head/Camera3D/HUD_System/Stance_State/VBoxContainer/Stance_State/Current_Stance_State
@onready var current_speed_state = $Head/Camera3D/HUD_System/Stance_State/VBoxContainer/Speed_State/Current_Speed_State

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
		velocity.y -= gravity * delta * 1.5

	# Direction Handling
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Jump Handling
	if Input.is_action_just_pressed("jump") and is_on_floor() and !Input.is_action_pressed("crouch") and !Input.is_action_pressed("crawl") and !player_raycast.is_colliding():
		velocity.y = jump_velocity

	# Stance & Speed Handling --------------------------------------------------------
	# Crawling State (Hold)
	if Input.is_action_pressed("crawl") and is_on_floor():
		speed = lerp(speed, crawl_speed, delta * 5.0)
		if head.position.y > head_height + crouch_depth:
			head.position.y = lerp(head.position.y, head_height + crawl_depth, delta * 1.4)
		else:
			head.position.y = move_toward(head.position.y, head_height + crawl_depth, delta * 1.8)

		if head.position.y < head_height + crawl_depth + 0.3:
			standing_collision_shape.disabled = true
			crouching_collision_shape.disabled = true
			crawling_collision_shape.disabled = false
			crawl_state = true

			# Current_Stance_State = STATE(CRAWLING) #
			current_stance_state.text = "Crawling"

			# Current_Speed_State = STATE(IDLE) #
			if abs(velocity.x) < 0.2 and abs(velocity.y) < 0.2 and abs(velocity.z) < 0.2:
				current_speed_state.text = "Idle"
			else:
				current_speed_state.text = "Moving While In Crawl"
		# if abs(head.position.y - (head_height + crawl_depth)) < 0.01:
			# print("Camera Shake")
			# implement camera shake

	# Crouching State (Hold)
	elif Input.is_action_pressed("crouch") and is_on_floor() and !Input.is_action_pressed("crawl") and crawl_state == false:
		speed = lerp(speed, crouch_speed, delta * 9.0)
		head.position.y = lerp(head.position.y, head_height + crouch_depth, delta * 3.2)
		if head.position.y < head_height + crouch_depth + 0.2:
			standing_collision_shape.disabled = true
			crouching_collision_shape.disabled = false
			crawling_collision_shape.disabled = true

			# Current_Stance_State = STATE(CROUCHING) #
			current_stance_state.text = "Crouching"

			# Current_Speed_State = STATE(IDLE) #
			if abs(velocity.x) < 0.2 and abs(velocity.y) < 0.2 and abs(velocity.z) < 0.2:
				current_speed_state.text = "Idle"
			else:
				current_speed_state.text = "Moving While Crouched"

	# Standing State
	elif !player_shapecast.is_colliding():
		if head.position.y < head_height + crouch_depth:
			head.position.y = lerp(head.position.y, head_height, delta * 1.1)

		else:
			head.position.y = lerp(head.position.y, head_height, delta * 3.2)

		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		crawling_collision_shape.disabled = true
		crawl_state = false

		# Current_Stance_State = STATE(STANDING) #
		current_stance_state.text = "Standing"

		# Current_Speed_State = STATE(IDLE) #
		if abs(velocity.x) < 0.5 and abs(velocity.y) < 0.5 and abs(velocity.z) < 0.5:
			current_speed_state.text = "Idle"

		else:
			# Sprinting
			if Input.is_action_pressed("sprint") and !Input.is_action_pressed("backward"):
				speed = lerp(speed, sprint_speed, delta * 3.6)
				# Current_Speed_State = STATE(SPRINTING) #
				current_speed_state.text = "Sprinting"

			# Walking
			else:
				# Current_Speed_State = STATE(WALKING) #
				current_speed_state.text = "Walking"

				if head.position.y < head_height + crouch_depth:
					speed = move_toward(crawl_speed, crouch_speed, delta * 0.5)
				else:
					speed = walk_speed

	#-------------------------------------------------------------------------------------
	# Add Inertia
	if is_on_floor():
		# Starting Speed
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.y = lerp(velocity.y, direction.y * speed, delta * 6.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
		# Stopping Speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 8.0)
			velocity.y = lerp(velocity.y, direction.y * speed, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 8.0)

	# In Air
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 1.5)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 1.5)

		# Current_Stance_State = STATE(JUMPING) #
		if velocity.y > 0:
			current_stance_state.text = "Jumping"

		# Current_Stance_State = STATE(FALLING) #
		if velocity.y < 0:
			current_stance_state.text = "Falling"


	move_and_slide()


	# Exit Program
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

