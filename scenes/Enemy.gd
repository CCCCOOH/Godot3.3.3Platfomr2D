extends KinematicBody2D

var maxSpeed = 25
var velocity = Vector2.ZERO
var direction = Vector2.RIGHT
var gravity = 500

func _ready():
	$HitboxArea.connect("area_entered", self, "on_hitbox_entered")


func _process(delta):
	velocity.x = (direction * maxSpeed).x

	if (not is_on_floor()):
		velocity.y += gravity * delta
	if ($FlipTimer.is_stopped() && 
	(!$AnimatedSprite/RayCastBottom.is_colliding() or $AnimatedSprite/RayCastBorder.is_colliding())):
		direction *= -1
		$FlipTimer.start()
	
	$AnimatedSprite.scale.x = 1 if direction.x > 0 else -1
	
	move_and_slide(velocity, Vector2.UP)

func on_hitbox_entered(_area2d):
	queue_free()
