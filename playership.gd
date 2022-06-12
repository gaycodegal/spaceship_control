extends RigidBody


var inputVector = Vector3()
export var invert_y: bool
export var speed: float = 1
export var max_speed: float = 1
export var angular_speed: float = 1
var max_speed_squared: float = max_speed * max_speed
var left_right: float = 0
var up_down: float = 0
var left_right_time = 0
var up_down_time = 0
var model

#debug
var time_since_print = 0

func _init():
	friction = 0
	max_speed_squared = max_speed * max_speed
	angular_damp = angular_speed
	
func _ready():
	model = get_node("model")

func _integrate_forces(state):
	# Rotation
	left_right = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	up_down = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	
	# handle y inversion
	up_down *= int(invert_y) * -2 + 1
	var basis = get_transform().basis
	
	# apply desired rotation direction as torque
	# angular_damping makes us not spin super fast
	#add_torque(basis.y.normalized() * left_right * angular_speed + basis.x.normalized() * up_down * angular_speed)
	var horizontal = basis.y.normalized() * left_right * angular_speed
	var vertical = basis.x.normalized() * up_down * angular_speed
	var rot = basis.z.normalized() * clamp(-basis.get_euler().z, -0.2, 0.2) 
	angular_velocity = horizontal + vertical + rot

	#get_transform().basis = basis.rotated(basis.z, -z/10)
	
	# Speed
	speed = clamp(speed, 0, max_speed)
	var desired_velocity = linear_velocity + basis.z.normalized() * speed
	if desired_velocity.length_squared() > max_speed_squared:
		desired_velocity = desired_velocity.normalized() * max_speed
	
	linear_velocity = desired_velocity
	#print(linear_velocity)
	
func _process(delta):
	left_right_time = clamp(left_right * delta + left_right_time , -1, 1)
	up_down_time = clamp(up_down * delta + up_down_time, -1, 1)
	if left_right == 0:
		left_right_time = left_right_time * 0.7
	if up_down == 0:
		up_down_time = up_down_time * 0.7
	var fake_PI = 3
	var basis = get_transform().basis

	
	# SUPER EXPENSIVE CODE
	# projection is the component of one vector along another
	#var x_basis = basis.x.normalized()
	#var x_project = angular_velocity.project(x_basis)
	#var x_sign = 1
	#if x_project.angle_to(x_basis) > fake_PI:
	#	x_sign = -1
	#var x_rot = x_project.length() * x_sign
	#
	#var z_basis = basis.y.normalized()
	#var z_project = angular_velocity.project(z_basis)
	#var z_sign = -1
	#if z_project.angle_to(z_basis) > fake_PI:
	#	z_sign = 1
	#var z_rot = z_project.length() * z_sign
	
	#var x_rot = angular_velocity.angle_to(basis.z)
	#var y_rot = angular_velocity.angle_to(basis.x)
	var z_rot = -left_right_time * 2
	var x_rot = up_down_time * 2
	if model != null:
		model.rotation_degrees.z = z_rot * 10
		model.rotation_degrees.x = x_rot * 5
		model.rotation_degrees.y = -z_rot * 5
	
	# debug
	time_since_print -= delta
	#var basis = get_transform().basis
	if time_since_print <= 0:
		time_since_print = 0.1
		print(basis.get_euler().z)
	#	print(basis.z, basis.x)

func _input(event):
	if Input.is_action_pressed("ui_cancel") or Input.is_action_pressed("ui_end"):
		get_tree().quit(OK)
	sleeping = false
