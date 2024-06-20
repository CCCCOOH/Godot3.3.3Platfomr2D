extends KinematicBody2D

signal died

# 使用状态机管理
enum State { NORMAL, DASHING }

export(int, LAYERS_2D_PHYSICS) var dashHazardMask

var gravity = 1000	# 重力值
var velocity = Vector2.ZERO	# 玩家最终的速度应用值
var maxHorizontalSpeed = 125	# 水平速度的上限值: 玩家的速度将会被限制在该范围内
var horizontalAcceleration = 2000	# 按下按键后会持续获得的水平加速度
var jumpSpeed = 320	# 玩家按下按键的起始向上速度 / 本模板中玩家可以最多跳上3格的方块
var jumpTerminationMultiplier = 4	# 用于提前停止玩家的跳跃的参数	-> 33行
var hasDoubleJump = false	# 玩家是否拥有二段跳的能力
var hasDash = false
var currentState = State.NORMAL	
var maxDashSpeed = 500
var minDashSpeed = 200
var isStateNew = true
var defaultHazardMask = 0

func _ready():
	$HazardArea.connect("area_entered", self , "on_hazard_area_entered")
	defaultHazardMask = $HazardArea.collision_mask
func _process(delta):
	match currentState:
		State.NORMAL:
			process_normal(delta)
		State.DASHING:
			process_dash(delta)
	isStateNew = false
	
func process_normal(delta):
	if (isStateNew):
		$HazardArea.collision_mask = defaultHazardMask
		$DashArea/CollisionShape2D.disabled = true
	var moveVector = get_movement_vector()
	# 进行玩家的实际移动 #
	velocity.x += moveVector.x * horizontalAcceleration * delta	# 按下按键后给予水平加速度
	############## 松开按键进行减速
	if (moveVector.x == 0):
		velocity.x = lerp(velocity.x, 0, pow(2, -50 * delta))	# 让速度从原来的速度变到 0， 重量为 pow(2, -25 * delta)
	############## 限制玩家的速度防止超过最大值
	velocity.x = clamp(velocity.x, -maxHorizontalSpeed, maxHorizontalSpeed)
	####################################################
	
	
	############## 按下跳跃键进行跳跃
	if (moveVector.y == -1 and (is_on_floor() || !$CoyoteTimer.is_stopped() || hasDoubleJump)):	
		# 如果玩家按下了跳跃键才进行移动
		# 或者玩家出在第一次掉出地面的0.1秒内的土狼时间内也可以跳跃
		# 如果玩家拥有二段跳的能力也可以进行跳跃
		velocity.y = moveVector.y * jumpSpeed
		if (!is_on_floor() and $CoyoteTimer.is_stopped()):
			hasDoubleJump = false
		$CoyoteTimer.stop()
			
	#### 提前停止跳跃
	if (velocity.y < 0 && !Input.is_action_pressed("jump")):
		velocity.y += gravity * jumpTerminationMultiplier * delta	# 当没有按下按键时增强重力来达到提前落地的作用
	else:
		velocity.y += gravity * delta	# 让玩家受到重力的作用
	
	var WasOnFloor = is_on_floor() # 存储临时的离开地面信息
	
	
	##### 注意：只用调用该方法才会进行实际的移动，上述速度更改的信息会汇总进行更新
	velocity = move_and_slide(velocity, Vector2.UP)	# 移动玩家并检测碰撞
	# 注意: move_and_slide()方法需要提供速度和向上的法向量
	
	######## 启动郊狼
	if (WasOnFloor && !is_on_floor()):	# 一旦我们第一次离开地面，启动土狼时间
		$CoyoteTimer.start()
	#######
	
	if (is_on_floor()):
		hasDash = true
		hasDoubleJump = true
	
	if (hasDash && Input.is_action_just_pressed("dash")):
		call_deferred("change_state", State.DASHING)
		hasDash = false
	
	update_animation()
	
func process_dash(delta):
	if (isStateNew):
		$HazardArea.collision_mask = dashHazardMask
		$DashArea/CollisionShape2D.disabled = false
		$AnimatedSprite.play("jump")
		var moveVector = get_movement_vector()
		var dashDirection = 1
		if (moveVector.x != 0):
			dashDirection = sign(moveVector.x)
		else:
			dashDirection = 1 if $AnimatedSprite.flip_h else -1
		####### 这里认为将velocityMod 替换为 dashDirection 更加直观一些！
		velocity = Vector2(maxDashSpeed * dashDirection, 0)
		# 第一帧设置预计到达的速度
	velocity = move_and_slide(velocity, Vector2.UP)
	
	velocity.x = lerp(0, velocity.x, pow(2, -10 * delta))
	# 不断加速直到到达最大速度
	if (abs(velocity.x) < minDashSpeed):	# 如果速度小于冲刺状态的最小速度，回到正常状态
		call_deferred("change_state", State.NORMAL)
	
func change_state(newState):
	currentState = newState
	isStateNew = true
	# 切换状态时设置当前为第一帧
	# 运行完一次process后将不是第一帧
	

func get_movement_vector():
	# 获取玩家按键输入的脚本
	# 检测玩家移动的按键并存入moveVecor向量中
	var moveVector = Vector2.ZERO
	moveVector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	moveVector.y = -1 if Input.is_action_just_pressed("jump") else 0
	# 移动数组用来存储玩家的按键比特值
	return moveVector

func update_animation():
	var moveVec = get_movement_vector()
	
	if (! is_on_floor()):	# 如果不在地面上播放跳跃动画
		$AnimatedSprite.play("jump")
	elif (moveVec.x != 0):	# 如果左右方向进行了移动播放跑步动画
		$AnimatedSprite.play("run")
	else:	# 否则静止
		$AnimatedSprite.play("idle")
	if (moveVec.x != 0):	# 只有提供输入才会更新翻转，否则翻转停留在上一次的状态下。
		$AnimatedSprite.flip_h = true if moveVec.x > 0 else false

func on_hazard_area_entered(area2d):
	emit_signal("died")
