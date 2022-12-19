extends Node

var network = ENetMultiplayerPeer.new()
var port = 24599
var max_servers = 5


func _ready():
	StartServer()


func StartServer():
	network.create_server(port, max_servers)
	multiplayer.set_multiplayer_peer(network)
	print("Authentication server started")
	
	network.peer_connected.connect(_Peer_Connected)
	network.peer_disconnected.connect(_Peer_Disconnected)


func _Peer_Connected(gateway_id):
	print("Gateway " + str(gateway_id) + " Connected")


func _Peer_Disconnected(gateway_id):
	print("Gateway " + str(gateway_id) + " Disconnected")


@rpc(any_peer)
func AuthenticatePlayer(username, password, player_id):
	print("Authentication request received")
	var gateway_id = multiplayer.get_remote_sender_id()
	var result
	print("Starting authentication")
	if not PlayerData.player_ids[username].password == password:
		print("Incorrect password")
		result = false
	else:
		print("Successful authentication")
		result = true
	print("Authentication result sent to gateway server")
	rpc_id(gateway_id, "AuthenticationResults", result, player_id)


@rpc
func AuthenticationResults(result, player_id):
	print(str(result) + str(player_id))
	pass
