extends Node2D

@onready var upper_arm: Line2D = $RightUpperArm
@onready var forearm: Line2D = $RightUpperArm/Forearm
@onready var rod: Line2D = $RightUpperArm/Forearm/Rod
@onready var line: Line2D = $RightUpperArm/Forearm/Rod/Line
# @onready var bubble: Sprite2D = $Bubble

var max_segment_count = 50
var initial_velocity = 10.0
var angle = 45.0
var max_line_length = 10.0
var end_angle = 120.0

var bait_target_global_position: Vector2
var bait_global_position: Vector2
var bait_global_position0: Vector2

var casting = false
var rotation_speed_down = false
var bait_down = false
var speed = 1.0
var segment_count = 0.0
var segment_increment = 0.0
var parabola_time = 0.0
var curve_offset = 0.3

var local_rotation0: float
var bait_initial_velocity: Vector2
var forearm_rotation0: float
var rod_rotation0: float
const g_vec = Vector2(0, 9.8) * 500
const bait_duration = 0.35

func _ready():
	# bubble.visible = false
	local_rotation0 = upper_arm.rotation_degrees
	bait_global_position0 = line.global_position
	bait_global_position = bait_global_position0
	forearm_rotation0 = forearm.rotation_degrees
	rod_rotation0 = rod.rotation_degrees
	_reset()

func _process(delta):
	if Input.is_action_just_pressed("mouse_left"):
		_reset()
		_start_casting()

	if Input.is_action_just_pressed("esc_reset"):
		_reset()

	if Input.is_action_just_pressed("show_data"):
		print("Velocity:", initial_velocity)
		print("Angle:", angle)
		print("End Angle:", end_angle)

	if casting:
		_handle_casting(delta)

	if bait_down:
		_handle_bait_fall(delta)

	if casting or bait_down:
		_update_bait_position(delta)
		_draw_bezier(line.global_position, bait_global_position, Vector2(1,-1), Vector2(-1,1), curve_offset)

func _start_casting():
	bait_target_global_position = get_global_mouse_position()
	# end = start + v0 * T + 0.5 * g_vec * T^2
	bait_initial_velocity = (bait_target_global_position - bait_global_position0 - 0.5 * g_vec * bait_duration * bait_duration) / bait_duration
	casting = true
	parabola_time = 0.0
	line.clear_points()
	curve_offset = 0.3

func _reset():
	# bubble.visible = false
	upper_arm.rotation_degrees = local_rotation0
	line.clear_points()
	max_segment_count = 50
	initial_velocity = 10.0
	angle = 30.0
	max_line_length = 10.0
	end_angle = 120.0
	casting = false
	rotation_speed_down = false
	bait_down = false
	speed = 1.0
	segment_count = 0
	segment_increment = 0
	bait_global_position0 = line.global_position
	bait_global_position = bait_global_position0
	parabola_time = 0.0
	forearm.rotation_degrees = forearm_rotation0
	rod.rotation_degrees = rod_rotation0

func _handle_casting(delta): #rod rotation
	if not rotation_speed_down:
		upper_arm.rotation_degrees -= 110 * delta * 5.0 * speed
		speed *= 1.01
		curve_offset *= (1 - 0.05 * delta)
		if upper_arm.rotation_degrees < 120:
			rotation_speed_down = true
		rod.rotation_degrees *= 0.85
	else:
		upper_arm.rotation_degrees -= 10 * delta * speed
		speed *= 0.98
		if upper_arm.rotation_degrees < 105:
			print('upper_arm.rotation_degrees < 105')
			casting = false
			bait_down = true
			curve_offset = 0
			rotation_speed_down = false
		rod.rotation_degrees *= 0.95
	if forearm.rotation_degrees > 5:
		forearm.rotation_degrees *= 0.95

func _handle_bait_fall(delta):
	if curve_offset > -0.18:
		curve_offset -= 1.0 * delta

# compute unique physical initial velocity v0 such that:
func _update_bait_position(delta): #parabola (physical)
	parabola_time += delta
	var start = bait_global_position0
	var duration = bait_duration
	if duration <= 0:
		return

	# clamp time and compute physical position
	var t = clamp(parabola_time, 0.0, duration)
	var pos = start + bait_initial_velocity * t + 0.5 * g_vec * t * t
	bait_global_position = pos

	# if bait passed below target, stop
	if bait_global_position.y > bait_target_global_position.y:
		casting = false
		bait_down = false
		# bubble.global_position = bait_position
		# bubble.visible = true
		# bubble.rotation = 0

func _draw_bezier(start: Vector2, end: Vector2, control1: Vector2, control2: Vector2, offset: float):
	var dir = (end - start).normalized()
	var normal = Vector2(-dir.y, dir.x).normalized()
	offset *= (end - start).length() / 10
	control1 = start + dir * ((start.distance_to(end)) / 3) + normal * offset
	control2 = start + dir * ((start.distance_to(end)) * 2 / 3) - normal * offset

	segment_count = 40
	line.clear_points()
	for i in range(segment_count):
		var t = float(i) / segment_count
		var point = (1 - t) ** 3 * start + 3 * (1 - t) ** 2 * t * control1 + 3 * (1 - t) * t ** 2 * control2 + t ** 3 * end
		line.add_point(line.to_local(point))
