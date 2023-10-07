extends Control

@onready var playersList:ItemList = get_parent().get_node("PanelInfoPlayers/ItemList")
@onready var PanelPlayersList = get_parent().get_node("PanelInfoPlayers")
@onready var btnKick = get_parent().get_node("PanelInfoPlayers/btnKick")
@onready var StatusPartida = get_parent().get_node("StatusInfo")
@onready var inputName = $inputName
@onready var cbxPlayers = $cbxPlayers

#const ip = "192.168.78.202"
var ip = IP.get_local_addresses()[6]
var port = 9000
var Player = preload("res://scenes/Characters/Player/player.tscn")
var peer
var kicked = false
signal renameComplete

const PLAYER_INFO_STATES ={
	KICKED=" fue expulsado de la partida por el admin.", 
	DISCONNECT=" abandonó la partida.", 
	PEER_CREATED=" se ha unido a la partida.",
	SERVER_CREATED=" creó una partida.",
	}

const DIALOGS_ID={
	SERVER_EXIST = "Error, ya existe una partida creada en esta red"
	}
	

func _ready():
	multiplayer.peer_connected.connect(addPlayer)
	multiplayer.peer_disconnected.connect(deletePlayer)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(close_connection)

func _process(delta):
	$btnHost.disabled = inputName.text == ""
	$btnJoin.disabled = inputName.text == ""

#Se llama al server y los clientes
func peer_connected(id):
	print("Peer Connected ", id)

#Se llama al server y los clientes
func peer_disconnected(id):
	print("Peer disconnected ", id)

#Se llama solo a los clientes
func connected_to_server():
	print("Connected to Server")
	sendPlayerInfo.rpc_id(1, inputName.text, multiplayer.get_unique_id())
	CreateInfo.rpc_id(1,multiplayer.get_unique_id(),0)
	StatusPartida.hide()
	
	
#Se llama solo a los clientes
func connection_failed():
	OS.alert("No se ha podido establecer una conexión con el host de la partida.", "Error")
	backToMenu()
	
func close_connection() -> void:
	#Reinicia la conexion
	backToMenu()
	

func _on_btn_host_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, cbxPlayers.value-1)
	if error != OK: 
		printerr("Error cant host ", error)
		match error:
			ERR_CANT_CREATE: OS.alert(DIALOGS_ID.SERVER_EXIST, "ERROR")
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Host Connected, waiting for players...")
	get_parent().get_parent().get_node("bg").show()
	PanelPlayersList.show()
	self.hide()
	addPlayer(multiplayer.get_unique_id())
	sendPlayerInfo(inputName.text, multiplayer.get_unique_id())
	CreateInfo(multiplayer.get_unique_id(),0)


func _on_btn_join_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error == OK:
		peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
		multiplayer.set_multiplayer_peer(peer)
		print("Client connected")
		get_parent().get_parent().get_node("bg").show()
		PanelPlayersList.show()
		btnKick.hide()
		StatusPartida.show()
		self.hide()
		await renameComplete
		addPlayer(multiplayer.get_unique_id())
		
	else:
		match (error):
			ERR_CANT_CONNECT: OS.alert("Error, no se pudo conectar con la partida. Revisa si estas conectado a la misma rede del dueño de la partida", "ERROR")
			
	
	
#--------------------------

@rpc("authority", "call_remote")
func backToMenu():
	var id = multiplayer.get_unique_id()
	playersList.clear()
	GlobalNetwork.players.clear()
	await  get_tree().create_timer(.5)
	multiplayer.multiplayer_peer = null
	get_tree().reload_current_scene()

func startGame():
	var scene = load("res://scenes/Worlds/lobby.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

@rpc("any_peer")
func CreateInfo(id, type):
	CreateLabel(id, type)
	if multiplayer.is_server():
		CreateInfo.rpc(id, type)
		
@rpc("any_peer", "call_local")
func CreateExpulseInfo(id, type):
	if id == 0: return
	CreateLabel(id, type)

@rpc("any_peer")
func CreateLabel(id,type):
	var username = GlobalNetwork.players[id].username
	var text = ""
	if id == 1:
		text = username+PLAYER_INFO_STATES.SERVER_CREATED
	else:
		match  type:
			0: text = username+PLAYER_INFO_STATES.PEER_CREATED
			1: text = username+PLAYER_INFO_STATES.DISCONNECT
			2: text = username+PLAYER_INFO_STATES.KICKED
	
	var lbl = Label.new()
	lbl.name = "lbl"+str(id)+"type"+str(type)
	lbl.text = text
	match type:
		0: lbl.add_theme_color_override("font_color", Color(0.20784313976765, 0.69411766529083, 0))
		1: lbl.add_theme_color_override("font_color", Color(1, 0.28627452254295, 0.22352941334248))
		2: lbl.add_theme_color_override("font_color", Color(1, 0.28627452254295, 0.22352941334248))
	
	get_parent().get_node("lbls_container/vbox/").add_child(lbl)

	var label = get_parent().get_node("lbls_container/vbox/lbl"+str(id)+"type"+str(type))
#	print(get_parent().get_node("lbls_container/vbox/").get_children())
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate", Color.TRANSPARENT, 4)
	tween.tween_callback(label.queue_free)

	
@rpc("any_peer")
func remove_peers(id):
#	print(multiplayer.get_remote_sender_id()," kick ", id)
	CreateExpulseInfo(id, 1)
	var peer = get_parent().get_parent().get_node_or_null(str(id))
	if peer:
		erase_players_to_list(id)
		GlobalNetwork.players.erase(id)

@rpc("any_peer")
func sendPlayerInfo(username, peerId):
#	var sender_id = multiplayer.get_remote_sender_id()
#	var my_id = multiplayer.get_unique_id()
	var iterateName = username
	var idx_count_names = 1
	
	if GlobalNetwork.players.has(peerId):
		GlobalNetwork.players[peerId].username = username
	else:
		GlobalNetwork.players[peerId] = {
			"username":username,
			"id":peerId,
			"score":0,
			"color":""
		}
		
		renameComplete.emit()

	var id_repetido = 0
	if multiplayer.is_server():
		for i in GlobalNetwork.players:
			while GlobalNetwork.players[i].username == iterateName and i != peerId:
				idx_count_names += 1
				iterateName = username + str(idx_count_names)
				id_repetido = peerId
				GlobalNetwork.players[id_repetido].username = iterateName
				
			sendPlayerInfo.rpc(GlobalNetwork.players[i].username, i)
			
	playersList.clear()
	for i in GlobalNetwork.players:
		playersList.add_item(GlobalNetwork.players[i].username)
	

func addPlayer(id):
	var player = Player.instantiate()
	player.name = str(id)
	get_parent().get_parent().add_child(player)
	player.position = Vector2(randf_range(70,500),randf_range(500, 70))
	await get_tree().create_timer(.1).timeout
#	CreateInfo.rpc(id, 0)
	
	
func deletePlayer(id):
	var peer = get_parent().get_parent().get_node_or_null(str(id))
	print("Peer deleted ", id)
	if peer:
#		CreateInfo(id, 1)
		peer.queue_free()
		if multiplayer.is_server():
			remove_peers(id)
			remove_peers.rpc(id) 
			
		
		
func erase_players_to_list(id, username=""):
	if username == "": username = GlobalNetwork.players[id].username
	for i in playersList.item_count:
		if playersList.get_item_text(i) == username:
			playersList.remove_item(i)
		

func _on_btn_kick_pressed():
	if not multiplayer.is_server(): return
	var idx:Array = playersList.get_selected_items()
	
	if idx.is_empty(): return
	for i in GlobalNetwork.players.values():
		var u = playersList.get_item_text(idx[0])
		if u == i.username:
			kicked = true
			backToMenu.rpc_id(i.id)
			
			
