extends Node

# Signals
signal network_state_updated()
signal connection_status_changed(status: String)

var http_request: HTTPRequest
var sync_timer: Timer
var room_code: String = ""
var is_host: bool = false
var firebase_url: String = "https://companion-banco-imobiliario-default-rtdb.asia-southeast1.firebasedatabase.app" # Public default fallback / customizable

# State polling rate (in seconds)
const POLL_INTERVAL = 1.0

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)
	
	sync_timer = Timer.new()
	sync_timer.wait_time = POLL_INTERVAL
	sync_timer.timeout.connect(_on_sync_timer_timeout)
	add_child(sync_timer)
	
	print("NetworkManager inicializado.")

func host_room(pin: String) -> void:
	room_code = pin
	is_host = true
	emit_signal("connection_status_changed", "Conectado como Banqueiro (Sala " + pin + ")")
	push_room_state_to_cloud()
	sync_timer.start()

func join_room(pin: String, player_id: String, player_data: Dictionary) -> void:
	room_code = pin
	is_host = false
	emit_signal("connection_status_changed", "Conectando à Sala " + pin + "...")
	
	# Fetch current room state first
	fetch_room_state(func(success: bool, data: Dictionary):
		if success and data.has("players"):
			var players = data["players"]
			players[player_id] = player_data
			# Push updated player list
			push_to_endpoint("/rooms/" + room_code + "/players.json", players, HTTPClient.METHOD_PUT)
			
			if data.has("transactions"):
				GameManager.transactions = data["transactions"]
			GameManager.players = players
			GameManager.emit_signal("players_updated", GameManager.players)
			emit_signal("connection_status_changed", "Conectado à Sala " + pin)
		else:
			# Fallback: Local registration if offline/mock
			GameManager.add_player_from_network(player_id, player_data)
			emit_signal("connection_status_changed", "Entrou na Sala " + pin + " (Modo Direto)")
	)
	
	sync_timer.start()

func broadcast_transaction(trans: Dictionary, updated_players: Dictionary) -> void:
	if room_code.is_empty():
		return
	push_to_endpoint("/rooms/" + room_code + "/transactions.json", GameManager.transactions, HTTPClient.METHOD_PUT)
	push_to_endpoint("/rooms/" + room_code + "/players.json", updated_players, HTTPClient.METHOD_PUT)

func broadcast_state(players: Dictionary, transactions: Array) -> void:
	if room_code.is_empty():
		return
	push_room_state_to_cloud()

func push_room_state_to_cloud() -> void:
	if room_code.is_empty():
		return
	var payload = {
		"pin": room_code,
		"players": GameManager.players,
		"transactions": GameManager.transactions,
		"updated_at": Time.get_unix_time_from_system()
	}
	push_to_endpoint("/rooms/" + room_code + ".json", payload, HTTPClient.METHOD_PUT)

func push_to_endpoint(path: String, data: Variant, method: HTTPClient.Method) -> void:
	if firebase_url.is_empty():
		return
	var url = firebase_url + path
	var json_str = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_request.request(url, headers, method, json_str)

var pending_fetch_callback: Callable

func fetch_room_state(callback: Callable = Callable()) -> void:
	if room_code.is_empty() or firebase_url.is_empty():
		if callback.is_valid():
			callback.call(false, {})
		return
	pending_fetch_callback = callback
	var url = firebase_url + "/rooms/" + room_code + ".json"
	http_request.request(url)

func _on_sync_timer_timeout() -> void:
	if room_code.is_empty():
		return
	# Poll cloud state every second
	var url = firebase_url + "/rooms/" + room_code + ".json"
	var req = HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(func(_result, response_code, _headers, body):
		if response_code == 200:
			var json = JSON.new()
			var parse_result = json.parse(body.get_string_from_utf8())
			if parse_result == OK:
				var data = json.data
				if data is Dictionary and data.has("players"):
					var remote_players = data["players"]
					var remote_tx = data.get("transactions", [])
					
					# Sync players
					GameManager.players = remote_players
					GameManager.transactions = remote_tx
					GameManager.emit_signal("players_updated", GameManager.players)
		req.queue_free()
	)
	req.request(url)

func _on_http_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if pending_fetch_callback.is_valid():
		var cb = pending_fetch_callback
		pending_fetch_callback = Callable()
		if response_code == 200:
			var json = JSON.new()
			if json.parse(body.get_string_from_utf8()) == OK:
				cb.call(true, json.data if json.data is Dictionary else {})
				return
		cb.call(false, {})
