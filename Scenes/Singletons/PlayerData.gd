extends Node

var player_ids


func _ready():
	var player_ids_file = FileAccess.open("user://PlayerIDs.json", FileAccess.READ)
	var player_data_json = JSON.parse_string(player_ids_file.get_as_text())
	player_ids = player_data_json


func SavePlayerIDs():
	var file = FileAccess.open("user://PlayerIDs.json", FileAccess.READ_WRITE)
	file.store_line(JSON.stringify(player_ids, "\t"))
