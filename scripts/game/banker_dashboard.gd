extends Control

@onready var pin_label = $VBox/Header/PinLabel
@onready var players_vbox = $VBox/PlayersCard/Scroll/PlayersVBox
@onready var btn_undo = $VBox/Controls/BtnUndo
@onready var btn_pay_all_go = $VBox/Controls/BtnPayAllGo
@onready var tx_container = $VBox/TxHistory/Scroll/TxVBox

func _ready() -> void:
	pin_label.text = "👑 BANQUEIRO - Mesa #" + GameManager.room_pin
	
	GameManager.players_updated.connect(_on_players_updated)
	GameManager.transaction_added.connect(_on_transaction_event)
	GameManager.transaction_undone.connect(_on_transaction_event)
	
	btn_undo.pressed.connect(_on_undo_pressed)
	btn_pay_all_go.pressed.connect(_on_pay_all_go_pressed)
	
	render_players()
	render_history()

func _on_players_updated(_players: Dictionary) -> void:
	render_players()
	render_history()

func _on_transaction_event(_tx: Dictionary) -> void:
	render_players()
	render_history()

func render_players() -> void:
	for child in players_vbox.get_children():
		child.queue_free()
		
	for p_id in GameManager.players:
		var p_data = GameManager.players[p_id]
		var hbox = HBoxContainer.new()
		
		var name_lbl = Label.new()
		name_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		name_lbl.text = p_data["name"]
		if p_data.get("is_banker", false):
			name_lbl.text += " 👑"
			
		var bal_lbl = Label.new()
		bal_lbl.text = GameManager.format_money(p_data["balance"])
		bal_lbl.modulate = Color(0.2, 0.9, 0.4, 1)
		
		hbox.add_child(name_lbl)
		hbox.add_child(bal_lbl)
		players_vbox.add_child(hbox)

func _on_undo_pressed() -> void:
	var success = GameManager.undo_last_transaction()
	if not success:
		SoundManager.play_error_sound()

func _on_pay_all_go_pressed() -> void:
	SoundManager.play_click_sound()
	for p_id in GameManager.players:
		GameManager.pay_pass_go(p_id)

func render_history() -> void:
	for child in tx_container.get_children():
		child.queue_free()
		
	var list = GameManager.transactions.duplicate()
	list.reverse()
	
	for tx in list:
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
		tx_container.add_child(label)
