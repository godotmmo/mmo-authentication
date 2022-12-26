extends Node


var authentication_server: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var gameserver_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
var port: int = 24600
var max_players: int = 100

var game_server_list: Dictionary = {}

func _ready() -> void:
	StartServer()


func _process(_delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return;
	multiplayer.poll();


func StartServer() -> void:
	authentication_server.create_server(port, max_players)
	
	# This creates a new multiplayer api instance on the current path and allows
	# for a secondary connection
	get_tree().set_multiplayer(gameserver_api, get_path())
	multiplayer.set_multiplayer_peer(authentication_server)
	print("GameServerHub started")
	
	authentication_server.peer_connected.connect(_Peer_Connected)
	authentication_server.peer_disconnected.connect(_Peer_Disconnected)


func _Peer_Connected(gameserver_id: int) -> void:
	print("Game Server " + str(gameserver_id) + " Connected")
	game_server_list["GameServer1"] = gameserver_id
	print(game_server_list)


func _Peer_Disconnected(gateway_id: int) -> void:
	print("Gateway " + str(gateway_id) + " Disconnected")


func DistributeLoginToken(token: String, gameserver: String) -> void:
	var gameserver_peer_id: int = game_server_list[gameserver]
	rpc_id(gameserver_peer_id, "ReceiveLoginToken", token)


@rpc
func ReceiveLoginToken(token: String) -> void:
	print(str(token))
