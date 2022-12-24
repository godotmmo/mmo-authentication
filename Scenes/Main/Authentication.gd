extends Node

var authentication_server = ENetMultiplayerPeer.new()
var port = 24599
var max_servers = 5


func _ready():
	StartServer()


func StartServer():
	authentication_server.create_server(port, max_servers)
	multiplayer.set_multiplayer_peer(authentication_server)
	print("Authentication server started")
	
	authentication_server.peer_connected.connect(_Peer_Connected)
	authentication_server.peer_disconnected.connect(_Peer_Disconnected)


func _Peer_Connected(gateway_id):
	print("Gateway " + str(gateway_id) + " Connected")


func _Peer_Disconnected(gateway_id):
	print("Gateway " + str(gateway_id) + " Disconnected")


@rpc(any_peer)
func AuthenticatePlayer(username, password, player_id):
	var token
	var gateway_id = multiplayer.get_remote_sender_id()
	var result
	print("Starting authentication")
	if not PlayerData.player_ids[username].password == password:
		print("Incorrect password")
		result = false
	else:
		print("Successful authentication")
		result = true
	
		randomize()
		token = str(randi()).sha256_text() + str(int(Time.get_unix_time_from_system()))
		var gameserver = "GameServer1" # this will have to be replaced with a load balancer
		GameServers.DistributeLoginToken(token, gameserver)
	print("Authentication result sent to gateway server: ", gateway_id)
	rpc_id(gateway_id, "AuthenticationResults", result, player_id, token)


@rpc
func AuthenticationResults(result, player_id, token):
	print(str(result) + str(player_id) + token)
	pass
