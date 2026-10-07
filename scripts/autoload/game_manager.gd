extends Node

# Signals
signal room_created(pin: String)
signal room_joined(pin: String, local_player_id: String)
signal players_updated(players_dict: Dictionary)
signal balance_updated(player_id: String, new_balance: int)
signal transaction_added(transaction: Dictionary)
signal transaction_undone(transaction: Dictionary)
signal game_started()
signal game_reset()

# Constants
const BANK_ID = "BANK"
const DEFAULT_STARTING_CASH = 25000
const DEFAULT_PASS_GO_BONUS = 2000

# Player Colors for Monopoly UI
const PLAYER_COLORS = [
	Color("#e74c3c"), # Vermelho
	Color("#3498db"), # Azul
	Color("#2ecc71"), # Verde
	Color("#f1c40f"), # Amarelo
	Color("#9b59b6"), # Roxo
	Color("#e67e22"), # Laranja
	Color("#1abc9c"), # Ciano
	Color("#ecf0f1")  # Branco/Prata
]

# State
var room_pin: String = ""
var local_player_id: String = ""
var local_player_name: String = ""
var is_banker: bool = false
var game_active: bool = false

# Settings
var starting_cash: int = DEFAULT_STARTING_CASH
var pass_go_bonus: int = DEFAULT_PASS_GO_BONUS

# Game Data
var players: Dictionary = {} # player_id -> { "name": String, "balance": int, "color": String, "is_banker": bool }
var transactions: Array = [] # Array of Dictionary { "id": String, "from": String, "to": String, "amount": int, "timestamp": String, "note": String }

func _ready() -> void:
	print("GameManager inicializado.")

# Generate random 4-digit PIN
func generate_room_pin() -> String:
	randomize()
	return "%04d" % (randi() % 10000)

func create_room(banker_name: String) -> String:
	room_pin = generate_room_pin()
	local_player_id = "p_banker_" + str(Time.get_ticks_msec())
	local_player_name = banker_name
	is_banker = true
	
	players.clear()
	transactions.clear()
	
	# Add Banker Player
	players[local_player_id] = {
		"name": banker_name + " (Banqueiro)",
		"balance": starting_cash,
		"color": "#f1c40f",
		"is_banker": true
	}
	
	game_active = true
	emit_signal("room_created", room_pin)
	emit_signal("players_updated", players)
	
	# Connect to network
	NetworkManager.host_room(room_pin)
	return room_pin

func join_room(pin: String, player_name: String, color_hex: String) -> void:
	room_pin = pin
	local_player_id = "p_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 1000)
	local_player_name = player_name
	is_banker = false
	
	NetworkManager.join_room(pin, local_player_id, {
		"name": player_name,
		"balance": starting_cash,
		"color": color_hex,
		"is_banker": false
	})
	
	emit_signal("room_joined", room_pin, local_player_id)

func add_player_from_network(p_id: String, p_data: Dictionary) -> void:
	players[p_id] = p_data
	emit_signal("players_updated", players)

func process_transfer(from_id: String, to_id: String, amount: int, note: String = "") -> bool:
	if amount <= 0:
		return false
		
	# Check balance if player is paying (Bank has unlimited money)
	if from_id != BANK_ID:
		if not players.has(from_id):
			return false
		if players[from_id]["balance"] < amount:
			return false # Insufficient funds
		players[from_id]["balance"] -= amount
		emit_signal("balance_updated", from_id, players[from_id]["balance"])

	if to_id != BANK_ID:
		if not players.has(to_id):
			return false
		players[to_id]["balance"] += amount
		emit_signal("balance_updated", to_id, players[to_id]["balance"])

	# Create Transaction Record
	var trans = {
		"id": "tx_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 1000),
		"from": from_id,
		"to": to_id,
		"amount": amount,
		"from_name": get_entity_name(from_id),
		"to_name": get_entity_name(to_id),
		"timestamp": Time.get_time_string_from_system(),
		"note": note
	}
	
	transactions.append(trans)
	emit_signal("transaction_added", trans)
	emit_signal("players_updated", players)
	
	# Play sound feedback
	SoundManager.play_money_sound()
	
	# Sync to network
	NetworkManager.broadcast_transaction(trans, players)
	return true

func pay_pass_go(player_id: String) -> bool:
	return process_transfer(BANK_ID, player_id, pass_go_bonus, "Passou no Ponto de Partida")

func undo_last_transaction() -> bool:
	if transactions.size() == 0:
		return false
		
	var last_tx = transactions.pop_back()
	var from_id = last_tx["from"]
	var to_id = last_tx["to"]
	var amount = last_tx["amount"]
	
	# Reverse transfer
	if from_id != BANK_ID and players.has(from_id):
		players[from_id]["balance"] += amount
		emit_signal("balance_updated", from_id, players[from_id]["balance"])
		
	if to_id != BANK_ID and players.has(to_id):
		players[to_id]["balance"] -= amount
		emit_signal("balance_updated", to_id, players[to_id]["balance"])

	emit_signal("transaction_undone", last_tx)
	emit_signal("players_updated", players)
	
	SoundManager.play_undo_sound()
	NetworkManager.broadcast_state(players, transactions)
	return true

func get_entity_name(entity_id: String) -> String:
	if entity_id == BANK_ID:
		return "🏦 Banco"
	if players.has(entity_id):
		return players[entity_id]["name"]
	return "Desconhecido"

func get_entity_color(entity_id: String) -> Color:
	if entity_id == BANK_ID:
		return Color("#f39c12") # Dourado Banco
	if players.has(entity_id) and players[entity_id].has("color"):
		return Color(players[entity_id]["color"])
	return Color("#ffffff")

func format_money(amount: int) -> String:
	var str_val = str(amount)
	var formatted = ""
	var count = 0
	for i in range(str_val.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "." + formatted
		formatted = str_val[i] + formatted
		count += 1
	return "R$ " + formatted
