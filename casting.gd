extends Node2D

@onready var line: Line2D = $Line
# @onready var bubble: Sprite2D = $Bubble

var max_segment_count = 50
var initial_velocity = 10.0
var angle = 45.0
var gravity = 9.8
var max_line_length = 10.0
var end_angle = 120.0

var bait_target_position: Vector2
var bait_position: Vector2
var bait_position0: Vector2

var casting = false
var rotation_speed_down = false
var bait_down = false
var speed = 1.0
var segment_count = 0.0
var segment_increment = 0.0
var parabola_time = 0.0
var curve_offset = 0.3

var local_rotation0: float

func _ready():
	# bubble.visible = false
	local_rotation0 = rotation_degrees
	bait_position = global_position
	bait_position0 = global_position
	_reset()

func _process(delta):
	if Input.is_action_just_pressed("mouse_left"):
		_start_casting()

	if Input.is_action_just_pressed("esc_reset"):
		_reset()

	if Input.is_action_just_pressed("show_data"):
		print("Velocity:", initial_velocity)
		print("Angle:", angle)
		print("Gravity:", gravity)
		print("End Angle:", end_angle)

	if casting:
		_handle_casting(delta)

	if bait_down:
		_handle_bait_fall(delta)

	if casting or bait_down:
		_update_bait_position(delta)
		_draw_bezier(global_position, bait_position, Vector2(1,-1), Vector2(-1,1), curve_offset)

func _start_casting():
	segment_increment = 0.5
	segment_count = 0
	initial_velocity = 10.0
	angle = 45.0
	gravity = 9.8
	max_line_length = 10.0
	end_angle = 120.0
	bait_position0 = global_position
	bait_position = bait_position0
	bait_target_position = get_global_mouse_position()
	casting = true
	parabola_time = 0.0
	line.clear_points()
	curve_offset = 0.3

func _reset():
	# bubble.visible = false
	rotation_degrees = local_rotation0
	line.clear_points()
	max_segment_count = 50
	initial_velocity = 10.0
	angle = 45.0
	gravity = 9.8
	max_line_length = 10.0
	end_angle = 120.0
	casting = false
	rotation_speed_down = false
	bait_down = false
	speed = 1.0
	segment_count = 0
	segment_increment = 0
	bait_position = global_position
	parabola_time = 0.0

func _handle_casting(delta): #rod rotation
	if not rotation_speed_down:
		rotation_degrees -= 110 * delta * 5.0 * speed
		speed *= 1.01
		curve_offset *= (1 - 0.05 * delta)
		if rotation_degrees < -60:
			rotation_speed_down = true
	else:
		rotation_degrees -= 10 * delta * speed
		speed *= 0.98
		if rotation_degrees < -75:
			casting = false
			bait_down = true
			curve_offset = 0
			rotation_speed_down = false

func _handle_bait_fall(delta):
	if curve_offset > -0.15:
		curve_offset -= 1.0 * delta

func _update_bait_position(delta): #parabola
	parabola_time += delta * 3
	var start = bait_position0
	var end = bait_target_position
	var duration = 0.3
	var g = 9.8 * 30

	var velocity = Vector2(end.x - start.x, 0) * 1.5
	var height_offset = 30
	var vy = (height_offset + 0.5 * g * duration * duration) * 3

	var t = parabola_time
	var pos = start + velocity * t
	pos.y -= vy * t - 0.5 * g * t * t

	bait_position = pos

	if bait_position.y > bait_target_position.y:
		casting = false
		bait_down = false
		# bubble.global_position = bait_position
		# bubble.visible = true
		# bubble.rotation = 0

func _draw_bezier(start: Vector2, end: Vector2, control1: Vector2, control2: Vector2, offset: float):
	var dir = (end - start).normalized()
	var normal = Vector2(-dir.y, dir.x).normalized()
	offset *= 15
	control1 = start + dir * ((start.distance_to(end)) / 3) + normal * offset
	control2 = start + dir * ((start.distance_to(end)) * 2 / 3) - normal * offset

	segment_count = 40
	line.clear_points()
	for i in range(segment_count):
		var t = float(i) / segment_count
		var point = (1 - t) ** 3 * start + 3 * (1 - t) ** 2 * t * control1 + 3 * (1 - t) * t ** 2 * control2 + t ** 3 * end
		line.add_point(to_local(point))
