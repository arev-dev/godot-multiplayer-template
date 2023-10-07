extends CharacterBody2D

const SPEED = 300.0
var username = ""

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	await get_tree().create_timer(.25).timeout
	if not is_multiplayer_authority(): 
		return

func _physics_process(delta):
	if multiplayer.has_multiplayer_peer():
		if not is_multiplayer_authority(): return
		if GlobalNetwork.players.has(multiplayer.get_unique_id()):
			$Label.text = str(GlobalNetwork.players[multiplayer.get_unique_id()].username)
		var x = Input.get_axis("a","d")
		var y = Input.get_axis("w","s")
		velocity = Vector2(x, y).normalized() * SPEED
		move_and_slide()
#	update_username.rpc(username)
