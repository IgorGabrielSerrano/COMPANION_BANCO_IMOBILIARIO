extends Control

@onready var room_pin_label = $VBox/Header/RoomPinLabel
@onready var player_name_label = $VBox/Header/PlayerNameLabel
@onready var balance_label = $VBox/BalanceCard/VBox/BalanceLabel

@onready var btn_pay_player = $VBox/ActionsGrid/BtnPayPlayer
@onready var btn_pay_bank = $VBox/ActionsGrid/BtnPayBank
@onready var btn_receive_bank = $VBox/ActionsGrid/BtnReceiveBank
@onready var btn_pass_go = $VBox/BtnPassGo

@onready var tx_container = $VBox/TxHistory/Scroll/TxVBox

var transaction_modal_scene = preload("res://scenes/game/transaction_modal.tscn")

func _ready() -> void:
	room_pin_label.text = "Mesa #" + GameManager.room_pin
	player_name_label.text = GameManager.local_player_name
	
	GameManager.balance_updated.connect(_on_balance_updated)
	GameManager.transaction_added.connect(_on_transaction_added)
	GameManager.transaction_undone.connect(_on_transaction_undone)
	GameManager.players_updated.connect(_on_players_updated)
	
	btn_pay_player.pressed.connect(func(): open_modal("PAY_PLAYER"))
	btn_pay_bank.pressed.connect(func(): open_modal("PAY_BANK"))
	btn_receive_bank.pressed.connect(func(): open_modal("RECEIVE_BANK"))
	btn_pass_go.pressed.connect(_on_pass_go_pressed)
	
	update_balance_display()
	render_history()

func _on_players_updated(_players: Dictionary) -> void:
	update_balance_display()

func update_balance_display() -> void:
	if GameManager.players.has(GameManager.local_player_id):
		var bal = GameManager.players[GameManager.local_player_id]["balance"]
		balance_label.text = GameManager.format_money(bal)

func open_modal(mode: String) -> void:
	SoundManager.play_click_sound()
	var modal = transaction_modal_scene.instantiate()
	add_child(modal)
	modal.setup(mode)

func _on_pass_go_pressed() -> void:
	GameManager.pay_pass_go(GameManager.local_player_id)

func _on_balance_updated(p_id: String, _new_bal: int) -> void:
	if p_id == GameManager.local_player_id:
		update_balance_display()

func _on_transaction_added(_tx: Dictionary) -> void:
	render_history()

func _on_transaction_undone(_tx: Dictionary) -> void:
	render_history()

func render_history() -> void:
	for child in tx_container.get_children():
		child.queue_free()
		
	# Reverse transactions order for feed
	var list = GameManager.transactions.duplicate()
	list.reverse()
	
	for tx in list:
		var card = MarginContainer.new()
		var label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		var from_name = tx["from_name"]
		var to_name = tx["to_name"]
		var val_str = GameManager.format_money(tx["amount"])
		var time_str = tx.get("timestamp", "")
		var note_str = tx.get("note", "")
		
		var msg = time_str + " | " + from_name + " ➔ " + to_name + ": " + val_str
		if not note_str.is_empty():
			msg += " (" + note_str + ")"
			
		label.text = msg
		card.add_child(label)
		tx_container.add_child(card)
