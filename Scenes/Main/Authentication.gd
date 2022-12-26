extends Node

var authentication_server: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var port: int = 24599
var max_servers: int = 5


func _ready() -> void:
	StartServer()


func StartServer() -> void:
	authentication_server.create_server(port, max_servers)
	multiplayer.set_multiplayer_peer(authentication_server)
	print("Authentication server started")
	
	authentication_server.peer_connected.connect(_Peer_Connected)
	authentication_server.peer_disconnected.connect(_Peer_Disconnected)


func _Peer_Connected(gateway_id: int) -> void:
	print("Gateway " + str(gateway_id) + " Connected")


func _Peer_Disconnected(gateway_id: int) -> void:
	print("Gateway " + str(gateway_id) + " Disconnected")


@rpc(any_peer)
func AuthenticatePlayer(username: String, password: String, player_id: int) -> void:
	var token: String
	var hashed_password: String
	var gateway_id: int = multiplayer.get_remote_sender_id()
	var result: bool
	print("Starting authentication")
	if not PlayerData.player_ids.has(username):
		result = false
	else:
		var retrieved_salt: String = PlayerData.player_ids[username].salt
		hashed_password = GenerateHashedPassword(password, retrieved_salt)	
		if not PlayerData.player_ids[username].password == hashed_password:
			result = false
		else:
			result = true
		
			randomize()
			token = str(randi()).sha256_text() + str(int(Time.get_unix_time_from_system()))
			var gameserver: String = "GameServer1" # this will have to be replaced with a load balancer
			GameServers.DistributeLoginToken(token, gameserver)
	
	print("Authentication result sent to gateway server: ", gateway_id)
	rpc_id(gateway_id, "AuthenticationResults", result, player_id, token)


@rpc(any_peer)
func CreateAccount(username: String, password: String, player_id: int) -> void:
	var gateway_id: int = multiplayer.get_remote_sender_id()
	var result: bool
	var message: int
	if PlayerData.player_ids.has(username):
		result = false
		message = 2
	else:
		result = true
		message = 3
		var salt: String = GenerateSalt()
		var hashed_password: String = GenerateHashedPassword(password, salt)
		PlayerData.player_ids[username] = {"password": hashed_password, "salt": salt}
		PlayerData.SavePlayerIDs()
	
	rpc_id(gateway_id, "CreateAccountResults", result, player_id, message)


func GenerateSalt() -> String:
	randomize()
	var salt: String = str(randi()).sha256_text()
	print("Salt: " + salt)
	return salt


func GenerateHashedPassword(password: String, salt: String) -> String:
	var hashed_password: String = password
	var rounds: int = int(pow(2, 18))
	print("Hashed password as input: " + hashed_password)
	while rounds > 0:
		hashed_password = (hashed_password + salt).sha256_text()
		rounds -= 1
	print("Final Hashed Password: " + hashed_password)
	return hashed_password


###################################################################################################
#							All functions below are used for									  #
#								rpc checksums													  #
###################################################################################################

@rpc
func CreateAccountResults(_result, _player_id, _message):
	# used for rpc checksum
	pass


@rpc
func AuthenticationResults(result, player_id, token):
	print(str(result) + str(player_id) + token)
	pass
