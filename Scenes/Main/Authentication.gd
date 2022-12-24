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
	var hashed_password
	var gateway_id = multiplayer.get_remote_sender_id()
	var result
	print("Starting authentication")
	if not PlayerData.player_ids.has(username):
		result = false
	else:
		var retrieved_salt = PlayerData.player_ids[username].salt
		hashed_password = GenerateHashedPassword(password, retrieved_salt)	
		if not PlayerData.player_ids[username].password == hashed_password:
			result = false
		else:
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


@rpc(any_peer)
func CreateAccount(username, password, player_id):
	var gateway_id = multiplayer.get_remote_sender_id()
	var result
	var message
	if PlayerData.player_ids.has(username):
		result = false
		message = 2
	else:
		result = true
		message = 3
		var salt = GenerateSalt()
		var hashed_password = GenerateHashedPassword(password, salt)
		PlayerData.player_ids[username] = {"password": hashed_password, "salt": salt}
		PlayerData.SavePlayerIDs()
	
	rpc_id(gateway_id, "CreateAccountResults", result, player_id, message)


@rpc
func CreateAccountResults(_result, _player_id, _message):
	# used for rpc checksum
	pass


func GenerateSalt():
	randomize()
	var salt = str(randi()).sha256_text()
	print("Salt: " + salt)
	return salt


func GenerateHashedPassword(password, salt):
	var hashed_password = password
	var rounds = pow(2, 18)
	print("Hashed password as input: " + hashed_password)
	while rounds > 0:
		hashed_password = (hashed_password + salt).sha256_text()
		rounds -= 1
	print("Final Hashed Password: " + hashed_password)
	return hashed_password
