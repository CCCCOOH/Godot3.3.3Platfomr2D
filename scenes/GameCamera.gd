extends Camera2D

var targetPosition = Vector2.ZERO
var sourcePosition
export(Color, RGB) var backgroundColor

func _ready():
	VisualServer.set_default_clear_color(backgroundColor)

func _process(delta):
	acquire_target_position()	# 获取玩家的目标位置
	global_position = lerp(targetPosition, global_position, pow(2, -15 * delta))	
	
func acquire_target_position():
	# 明确目标位置
	var players = get_tree().get_nodes_in_group("player")
	# 如果玩家组中只有一个玩家，应该是为了以防万一。就固定位置到玩家的位置上去。
	if (players.size() > 0):
		var player = players[0]
		targetPosition = player.global_position
