extends Control

# Nodes
@onready var create_tab_btn = $VBox/TabContainer/BtnTabCreate
@onready var join_tab_btn = $VBox/TabContainer/BtnTabJoin

@onready var create_panel = $VBox/Panels/CreatePanel
@onready var join_panel = $VBox/Panels/JoinPanel

# Create form
@onready var banker_name_input = $VBox/Panels/CreatePanel/VBox/BankerNameInput
@onready var starting_cash_input = $VBox/Panels/CreatePanel/VBox/StartingCashInput
@onready var btn_create_room = $VBox/Panels/CreatePanel/VBox/BtnCreateRoom

# Join form
@onready var room_pin_input = $VBox/Panels/JoinPanel/VBox/RoomPinInput
@onready var player_name_input = $VBox/Panels/JoinPanel/VBox/PlayerNameInput
@onready var color_container = $VBox/Panels/JoinPanel/VBox/ColorContainer
@onready var btn_join_room = $VBox/Panels/JoinPanel/VBox/BtnJoinRoom
@onready var status_label = $VBox/StatusLabel

var selected_color: String = "#e74c3c"

func _ready() -> void:
	create_tab_btn.pressed.connect(show_create_tab)
	join_tab_btn.pressed.connect(show_join_tab)
	
	btn_create_room.pressed.connect(_on_create_pressed)
	btn_join_room.pressed.connect(_on_join_pressed)
	
	setup_color_buttons()
	show_join_tab()

func show_create_tab() -> void:
	SoundManager.play_click_sound()
	create_panel.visible = true
	join_panel.visible = false
	create_tab_btn.modulate = Color(1, 1, 1, 1)
	join_tab_btn.modulate = Color(0.6, 0.6, 0.6, 1)

func show_join_tab() -> void:
	SoundManager.play_click_sound()
	create_panel.visible = false
	join_panel.visible = true
	create_tab_btn.modulate = Color(0.6, 0.6, 0.6, 1)
	join_tab_btn.modulate = Color(1, 1, 1, 1)

func setup_color_buttons() -> void:
	for child in color_container.get_children():
		child.queue_free()
		
	for c in GameManager.PLAYER_COLORS:
		var c_hex = "#" + c.to_html(false)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.modulate = c
		btn.pressed.connect(func():
			SoundManager.play_click_sound()
			selected_color = c_hex
			status_label.text = "Cor selecionada!"
		)
		color_container.add_child(btn)

func _on_create_pressed() -> void:
	var name_text = banker_name_input.text.strip_edges()
	if name_text.is_empty():
		status_label.text = "⚠️ Por favor, informe seu nome como Banqueiro."
		SoundManager.play_error_sound()
		return
		
	var cash = int(starting_cash_input.text) if starting_cash_input.text.is_valid_int() else 25000
	GameManager.starting_cash = cash
	
	var pin = GameManager.create_room(name_text)
	status_label.text = "Mesa criada! PIN: " + pin

func _on_join_pressed() -> void:
	var pin_text = room_pin_input.text.strip_edges()
	var name_text = player_name_input.text.strip_edges()
	
	if pin_text.is_empty() or name_text.is_empty():
		status_label.text = "⚠️ Informe o PIN da mesa e seu nome."
		SoundManager.play_error_sound()
		return
		
	GameManager.join_room(pin_text, name_text, selected_color)
