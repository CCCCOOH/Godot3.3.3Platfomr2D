extends Position2D

export(PackedScene) var enemyScene

var currentEnemyNode = null
var spawnOnNextTick = false


func _ready():
	$SpawnerTimer.connect("timeout", self, "on_check_enemy_spawn")
	call_deferred("spawn_enemy")
	
	
func spawn_enemy():
	currentEnemyNode = enemyScene.instance()
	get_parent().add_child(currentEnemyNode)
	currentEnemyNode.global_position = global_position
	
func check_enemy_spawn():
	if (! is_instance_valid(currentEnemyNode)):
		if (spawnOnNextTick):
			spawn_enemy()
			spawnOnNextTick = false
		else:
			spawnOnNextTick = true
		
func on_check_enemy_spawn():
	check_enemy_spawn()
