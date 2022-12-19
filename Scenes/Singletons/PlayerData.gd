extends Node

var player_ids


func _ready():
	var player_ids_file = FileAccess.open("res://Data/player-data.json", FileAccess.READ)
	var player_data_json = JSON.parse_string(player_ids_file.get_as_text())
	player_ids = player_data_json
