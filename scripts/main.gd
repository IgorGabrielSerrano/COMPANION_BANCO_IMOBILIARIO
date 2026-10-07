extends Control

@onready var content_container = $ContentContainer

var main_menu_scene = preload("res://scenes/lobby/main_menu.tscn")
var player_dashboard_scene = preload("res://scenes/game/player_dashboard.tscn")
var banker_dashboard_scene = preload("res://scenes/game/banker_dashboard.tscn")

func _ready() -> void:
	GameManager.room_created.connect(_on_room_created)
	GameManager.room_joined.connect(_on_room_joined)
	show_main_menu()

func clear_container() -> void:
	for child in content_container.get_children():
		child.queue_free()

func show_main_menu() -> void:
	clear_container()
	var menu = main_menu_scene.instantiate()
	content_container.add_child(menu)

func _on_room_created(_pin: String) -> void:
	clear_container()
	var banker_view = banker_dashboard_scene.instantiate()
	content_container.add_child(banker_view)

func _on_room_joined(_pin: String, _player_id: String) -> void:
	clear_container()
	var player_view = player_dashboard_scene.instantiate()
	content_container.add_child(player_view)
