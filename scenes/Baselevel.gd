extends Node

signal coin_total_change

export(PackedScene) var levelCompleteScene

var playerScene = preload("res://scenes/Player.tscn")
var spawnPosition = Vector2.ZERO
var currentPlayerNode = null
var totalCoins = 0
var collectedCoins = 0


func _ready():
	spawnPosition = $Player.global_position
	register_player($Player)

	coin_total_changed(get_tree().get_nodes_in_group("coin").size())
	# 记录场景中硬币的总数
	$Flag.connect("player_won", self, "on_player_won")
	
func coin_collected():
	collectedCoins += 1
	print(collectedCoins, " - ", totalCoins)
	emit_signal("coin_total_change", totalCoins, collectedCoins)

func coin_total_changed(newTotal):
	totalCoins = newTotal
	emit_signal("coin_total_change", totalCoins, collectedCoins)
	

func register_player(player):
	# 注册新的玩家
	currentPlayerNode = player
	currentPlayerNode.connect("died", self, "on_player_died", [], CONNECT_DEFERRED)	# 让玩家的死亡连接到本脚本中
# 监听玩家的死亡并创建新场景

func create_player():
	var playerInstance = playerScene.instance()
	add_child_below_node(currentPlayerNode, playerInstance)		# 创建新的玩家实例，并将放到场景树原先应有的位置上
	playerInstance.global_position = spawnPosition
	register_player(playerInstance)	# 注册新的玩家实例作为当前的玩家实例
	

func on_player_died():
	currentPlayerNode.queue_free()	# 首先删除当前的玩家
	create_player()	# 然后创建新的玩家

func on_player_won():
	currentPlayerNode.queue_free()
	var levelComplete = levelCompleteScene.instance()
	add_child(levelComplete)
