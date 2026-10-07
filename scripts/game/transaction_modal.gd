extends Control

signal transfer_completed()

@onready var title_label = $Panel/VBox/TitleLabel
@onready var recipient_option = $Panel/VBox/RecipientOption
@onready var amount_input = $Panel/VBox/AmountInput
@onready var note_input = $Panel/VBox/NoteInput
@onready var btn_confirm = $Panel/VBox/HBoxBtn/BtnConfirm
@onready var btn_cancel = $Panel/VBox/HBoxBtn/BtnCancel

@onready var btn_50 = $Panel/VBox/QuickValues/Btn50
@onready var btn_100 = $Panel/VBox/QuickValues/Btn100
@onready var btn_200 = $Panel/VBox/QuickValues/Btn200
@onready var btn_500 = $Panel/VBox/QuickValues/Btn500
@onready var btn_2000 = $Panel/VBox/QuickValues/Btn2000

var mode: String = "PAY_PLAYER" # "PAY_PLAYER", "PAY_BANK", "RECEIVE_BANK"

func _ready() -> void:
	btn_cancel.pressed.connect(close)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	
	btn_50.pressed.connect(func(): add_quick_amount(50))
	btn_100.pressed.connect(func(): add_quick_amount(100))
	btn_200.pressed.connect(func(): add_quick_amount(200))
	btn_500.pressed.connect(func(): add_quick_amount(500))
	btn_2000.pressed.connect(func(): add_quick_amount(2000))

func setup(p_mode: String) -> void:
	mode = p_mode
	recipient_option.clear()
	amount_input.text = ""
	note_input.text = ""
	
	if mode == "PAY_PLAYER":
		title_label.text = "💸 Pagar a um Jogador"
		recipient_option.visible = true
		populate_players_dropdown()
	elif mode == "PAY_BANK":
		title_label.text = "🏦 Pagar ao Banco"
		recipient_option.visible = false
	elif mode == "RECEIVE_BANK":
		title_label.text = "💰 Receber do Banco"
		recipient_option.visible = false

func populate_players_dropdown() -> void:
	recipient_option.clear()
	var idx = 0
	for p_id in GameManager.players:
		if p_id != GameManager.local_player_id:
			var p_name = GameManager.players[p_id]["name"]
			recipient_option.add_item(p_name, idx)
			recipient_option.set_item_metadata(idx, p_id)
			idx += 1

func add_quick_amount(val: int) -> void:
	SoundManager.play_click_sound()
	var current = int(amount_input.text) if amount_input.text.is_valid_int() else 0
	amount_input.text = str(current + val)

func close() -> void:
	SoundManager.play_click_sound()
	queue_free()

func _on_confirm_pressed() -> void:
	var val = int(amount_input.text) if amount_input.text.is_valid_int() else 0
	if val <= 0:
		SoundManager.play_error_sound()
		return
		
	var note = note_input.text.strip_edges()
	var success = false
	
	if mode == "PAY_PLAYER":
		if recipient_option.selected < 0:
			SoundManager.play_error_sound()
			return
		var target_id = recipient_option.get_item_metadata(recipient_option.selected)
		success = GameManager.process_transfer(GameManager.local_player_id, target_id, val, note)
	elif mode == "PAY_BANK":
		success = GameManager.process_transfer(GameManager.local_player_id, GameManager.BANK_ID, val, note if not note.is_empty() else "Pagamento ao Banco")
	elif mode == "RECEIVE_BANK":
		success = GameManager.process_transfer(GameManager.BANK_ID, GameManager.local_player_id, val, note if not note.is_empty() else "Recebido do Banco")

	if success:
		emit_signal("transfer_completed")
		close()
	else:
		SoundManager.play_error_sound()
