extends Node

var players := {} # Tu diccionario de jugadores

#func _process(delta):
#	# Crear un diccionario para hacer un seguimiento de los nombres de usuario duplicados
#	var duplicate_usernames := {}
#
#	# Recorrer el diccionario de jugadores
#	for player_id in players.keys():
#		var player_data = players[player_id]
#		var username = player_data["username"]
#
#		# Si el nombre de usuario ya está en el diccionario de duplicados
#		if duplicate_usernames.has(username):
#			# Incrementar el contador de duplicados para ese nombre de usuario
#			duplicate_usernames[username] += 1
#			# Crear un nuevo nombre de usuario con el indicador de suma
#			var new_username = username + str(duplicate_usernames[username])
#			# Actualizar el diccionario de jugadores con el nuevo nombre de usuario
#			player_data["username"] = new_username
#			players[player_id] = player_data
#		else:
#			# Si es la primera vez que se encuentra este nombre de usuario, agregarlo al diccionario de duplicados
#			duplicate_usernames[username] = 1
