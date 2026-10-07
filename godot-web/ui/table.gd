extends Control

const Icon = preload("res://ui/icon.gd")
const Atmosphere = preload("res://ui/atmosphere.gd")
const GOLD = Color("#f2d080")
const GREEN = Color("#65dfa7")
const TEXT = Color("#eef3ef")
const MUTED = Color("#8ea5aa")
const PANEL = Color("#14262e")
const RED = Color("#f39591")
var snapshot: Dictionary = {}
var view: Dictionary = {}
var last_signature: String = ""
var poll_time: float = 0.0
var active_tab: String = "mesa"
var active_screen: String = ""
var reduced: bool = false
var content: VBoxContainer
var body: VBoxContainer
var balance_label: Label
var balance_tween: Tween
var money_value: float = 0.0
var name_label: Label
var status_label: Label
var coin_icon: Control
var fx: Control
var tab_buttons: Dictionary = {}
var sound_button: Button
var exit_button: Button
var pin_label: Label
var scroll_area: ScrollContainer
var touching_body: bool = false
var suppress_touch_click: bool = false

func _ready() -> void:
	var theme_resource := Theme.new()
	theme_resource.default_font_size = 16
	for type in ["Label", "Button", "LineEdit"]:
		theme_resource.set_color("font_color", type, TEXT)
	theme = theme_resource
	fx = Atmosphere.new()
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fx)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.parent.companionReady()")
	_read_snapshot()
	resized.connect(_fit_width)

func _process(delta: float) -> void:
	poll_time += delta
	if poll_time >= 0.2:
		poll_time = 0
		_read_snapshot()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(scroll_area): return
	if event is InputEventScreenTouch:
		if event.pressed:
			touching_body = scroll_area.get_global_rect().has_point(event.position)
		else:
			touching_body = false
			if suppress_touch_click:
				get_viewport().set_input_as_handled()
				get_tree().create_timer(0.12).timeout.connect(func(): suppress_touch_click = false)
	elif event is InputEventScreenDrag and touching_body:
		if absf(event.relative.y) > 2:
			suppress_touch_click = true
			scroll_area.scroll_vertical -= int(event.relative.y)
			get_viewport().set_input_as_handled()

func _read_snapshot() -> void:
	var result: Variant
	if OS.has_feature("web"):
		result = JSON.parse_string(str(JavaScriptBridge.eval("window.parent.companionView()")))
	else:
		result = {"state": {"pin":"3922", "playerId":"demo", "playerName":"IGOR GABRIEL", "isBanker":true,
			"players":{"demo":{"name":"Igor Gabriel", "balance":25000, "properties":[], "jailed":false}}, "transactions":[]},
			"status":"Prévia da mesa", "sound":true, "reducedMotion":false}
	if not result is Dictionary: return
	view = result
	var next: Dictionary = view.get("state", {})
	reduced = view.get("reducedMotion", false)
	fx.reduced = reduced
	var screen := "game" if not str(next.get("pin", "")).is_empty() else "lobby"
	var old_balance: float = -1.0
	if not snapshot.is_empty():
		old_balance = float(snapshot.get("players", {}).get(snapshot.get("playerId", ""), {}).get("balance", -1))
	snapshot = next
	if screen != active_screen:
		active_screen = screen
		_build_screen()
	if screen == "game":
		name_label.text = str(snapshot.get("playerName", "Jogador"))
		pin_label.text = "MESA " + str(snapshot.get("pin", ""))
		status_label.text = str(view.get("status", "Conectando…"))
		status_label.add_theme_color_override("font_color",GREEN if "Conectado" in status_label.text or "Online" in status_label.text else MUTED)
		sound_button.tooltip_text = "Som ligado" if view.get("sound", true) else "Som desligado"
		sound_button.modulate.a = 1.0 if view.get("sound", true) else 0.45
		var player: Dictionary = snapshot.get("players", {}).get(snapshot.get("playerId", ""), {})
		var target := float(player.get("balance", 0))
		if old_balance != target:
			_animate_money(target, old_balance < 0)
		var signature := JSON.stringify([snapshot.get("players", {}), snapshot.get("transactions", []), active_tab])
		if signature != last_signature:
			last_signature = signature
			_render_body()

func _command(action: String, payload: Dictionary = {}) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.parent.companionAction(" + JSON.stringify(action) + "," + JSON.stringify(payload) + ")")

func _style(color: Color, border: Color = Color("#29424a"), radius: int = 18) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	return box

func _label(text: String, font_size: int = 16, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _icon(kind: String, tint: Color = GOLD) -> Control:
	var icon := Icon.new()
	icon.kind = kind
	icon.tint = tint
	return icon

func _button(text: String, kind: String, callback: Callable, accent: Color = GOLD, filled: bool = false) -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = 60
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_stylebox_override("normal", _style(Color("#245946") if filled else PANEL, accent if filled else Color("#29424a"), 14))
	button.add_theme_stylebox_override("hover", _style(Color("#284b49"), accent, 14))
	button.add_theme_stylebox_override("pressed", _style(Color("#33625b"), accent, 14))
	button.add_theme_stylebox_override("focus", _style(Color(0,0,0,0), accent, 14))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.add_child(_icon(kind, accent))
	if not text.is_empty():
		var label := _label(text, 14)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
	button.add_child(row)
	button.pressed.connect(func():
		if suppress_touch_click: return
		if not reduced:
			row.pivot_offset = row.size / 2
			var tween := button.create_tween()
			tween.tween_property(row, "modulate", Color(1.3,1.3,1.3), 0.08)
			tween.parallel().tween_property(row, "scale",Vector2(0.96,0.96),0.08)
			tween.tween_property(row, "modulate", Color.WHITE, 0.18)
			tween.parallel().tween_property(row, "scale",Vector2.ONE,0.18).set_trans(Tween.TRANS_BACK)
		callback.call()
	)
	return button

func _card(parent: Node, color: Color = PANEL) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(color))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	return box

func _build_screen() -> void:
	scroll_area = null
	if is_instance_valid(content): content.get_parent().queue_free()
	last_signature = ""
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_"+side, 18)
	add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	_fit_width()
	var brand := HBoxContainer.new()
	brand.add_theme_constant_override("separation", 10)
	brand.add_child(_icon("bank"))
	brand.add_child(_label("BANCO IMOBILIÁRIO", 19, GOLD))
	content.add_child(brand)
	if active_screen == "lobby":
		_build_lobby()
		return
	var meta := HBoxContainer.new()
	name_label = _label("", 16)
	meta.add_child(name_label)
	pin_label = _label("", 13, GOLD)
	pin_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	pin_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	meta.add_child(pin_label)
	content.add_child(meta)
	var balance_card := _card(content, Color("#183c38"))
	var top := HBoxContainer.new()
	top.add_child(_label("SEU PATRIMÔNIO EM MOVIMENTO", 11, MUTED))
	sound_button = _button("", "sound", func(): _command("SOUND"))
	sound_button.custom_minimum_size = Vector2(42,42)
	sound_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	top.add_child(sound_button)
	balance_card.add_child(top)
	var balance_row := HBoxContainer.new()
	coin_icon = _icon("coin")
	coin_icon.custom_minimum_size = Vector2(50,50)
	balance_row.add_child(coin_icon)
	balance_label = _label("R$ 0", 38, GREEN)
	balance_row.add_child(balance_label)
	balance_card.add_child(balance_row)
	status_label = _label("Conectando…", 11, MUTED)
	balance_card.add_child(status_label)
	content.add_child(_button("Ponto de partida  ·  + R$ 2.000", "go", func(): _command("GO"), GREEN, true))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.add_child(_button("Pagar", "pay", func(): _command("PAY_PLAYER")))
	actions.add_child(_button("Banco", "bank", func(): _command("PAY_BANK")))
	actions.add_child(_button("Receber", "coin", func(): _command("RECEIVE_BANK")))
	content.add_child(actions)
	var scroll := ScrollContainer.new()
	scroll_area = scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	content.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	tab_buttons.clear()
	for item in [["mesa","Mesa","people"],["posses","Posses","home"],["historico","Histórico","history"]]:
		var key: String = item[0]
		var button := _button(item[1],item[2],func(): _select_tab(key))
		tab_buttons[key] = button
		tabs.add_child(button)
	content.add_child(tabs)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	if snapshot.get("isBanker",false): footer.add_child(_button("Finalizar", "lock", func(): _command("END"), RED))
	exit_button = _button("Sair da mesa", "exit", func(): _command("LEAVE"), MUTED)
	footer.add_child(exit_button)
	content.add_child(footer)
	_entrance(content)

func _build_lobby() -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var box := _card(content, Color("#183c38"))
	var coin := _icon("coin")
	coin.spin = not reduced
	coin.custom_minimum_size.y = 60
	box.add_child(coin)
	box.add_child(_label("Sua mesa. Seus negócios.", 27, GOLD))
	box.add_child(_label("Jogue no tabuleiro. Cuide da fortuna aqui.",15,MUTED))
	var name_input := _text_input(box,"Seu nome")
	var pin_input := _text_input(box,"PIN da mesa · 4 dígitos")
	pin_input.max_length = 4
	box.add_child(_button("Entrar na mesa", "people", func(): _command("JOIN", {"name":name_input.text,"pin":pin_input.text}), GREEN, true))
	var cash_input := _text_input(box,"Saldo inicial")
	cash_input.text = "25000"
	box.add_child(_button("Criar mesa como banqueiro", "bank", func(): _command("CREATE", {"name":name_input.text,"cash":cash_input.text})))
	box.add_child(_label("Já jogou nesta mesa? Use o mesmo PIN e nome para recuperar sua posição.",13,MUTED))
	var bottom := Control.new()
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bottom)
	_entrance(box)

func _text_input(parent: Node, placeholder: String) -> LineEdit:
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size.y = 60
	input.add_theme_stylebox_override("normal", _style(Color("#0d2028")))
	input.add_theme_stylebox_override("focus", _style(Color("#0d2028"),GOLD))
	parent.add_child(input)
	return input

func _select_tab(tab: String) -> void:
	active_tab = tab
	last_signature = ""
	_render_body()
	_entrance(body)

func _render_body() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for key in tab_buttons:
		tab_buttons[key].add_theme_stylebox_override("normal", _style(Color("#254640") if key==active_tab else PANEL, GOLD if key==active_tab else Color("#29424a"),14))
	match active_tab:
		"posses": _render_properties()
		"historico": _render_history()
		_: _render_table()

func _render_table() -> void:
	var me: Dictionary = snapshot.get("players",{}).get(snapshot.get("playerId",""),{})
	var box := _card(body)
	var jailed: bool = me.get("jailed",false)
	var heading := HBoxContainer.new()
	heading.add_child(_icon("lock" if jailed else "dice",RED if jailed else GOLD))
	heading.add_child(_label("Na cadeia · %d/3 rodadas" % int(me.get("jailRounds",0)) if jailed else "Livre para negociar",19, RED if jailed else GOLD))
	box.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	box.add_child(grid)
	if jailed:
		grid.add_child(_button("+1 rodada","history",func(): _command("JAIL",{"action":"ROUND"})))
		grid.add_child(_button("Dados iguais","dice",func(): _command("JAIL",{"action":"DOUBLES"}),GREEN))
	else:
		box.add_child(_label("Duplas consecutivas · %d/3" % int(me.get("consecutiveDoubles",0)),14,MUTED))
		grid.add_child(_button("Ir à cadeia","lock",func(): _command("JAIL",{"action":"ENTER"})))
		grid.add_child(_button("Dados iguais","dice",func(): _command("JAIL",{"action":"MARK_DOUBLES"})))
		box.add_child(_button("Encerrar turno · zerar duplas","go",func(): _command("JAIL",{"action":"END_TURN"}),MUTED))
	body.add_child(_label("JOGADORES NA MESA",12,MUTED))
	for id in snapshot.get("players",{}):
		var p: Dictionary = snapshot.players[id]
		var card := _card(body)
		var row := HBoxContainer.new()
		row.add_child(_label(str(p.name)+( " · você" if id==snapshot.playerId else ""),16))
		var amount := _label(_money(float(p.balance)),16,GREEN)
		amount.autowrap_mode = TextServer.AUTOWRAP_OFF
		amount.size_flags_horizontal = Control.SIZE_SHRINK_END
		row.add_child(amount)
		card.add_child(row)
		card.add_child(_label("Preso · %d/3" % int(p.get("jailRounds",0)) if p.get("jailed",false) else "Livre · duplas %d/3" % int(p.get("consecutiveDoubles",0)),12,MUTED))
		for prop in p.get("properties",[]): card.add_child(_label(str(prop.name)+" · "+_money(float(prop.rent)),13,Color(prop.get("color","#f2d080"))))

func _render_properties() -> void:
	body.add_child(_button("Comprar nova posse","home",func(): _command("BUY"),GREEN,true))
	var properties: Array = snapshot.get("players",{}).get(snapshot.get("playerId",""),{}).get("properties",[])
	if properties.is_empty():
		var empty := _card(body)
		empty.add_child(_label("Sua próxima conquista começa aqui.",22,GOLD))
		empty.add_child(_label("Compre uma posse para acompanhar aluguel, transferências e hipotecas.",15,MUTED))
	for index in range(properties.size()):
		var prop: Dictionary = properties[index]
		var color := Color(prop.get("color","#f2d080"))
		var card := _card(body)
		var title := HBoxContainer.new()
		title.add_child(_icon("home",color))
		title.add_child(_label(str(prop.name),21,color))
		card.add_child(title)
		card.add_child(_label("Aluguel "+_money(float(prop.rent))+"   ·   Compra "+_money(float(prop.get("price",0))),14,MUTED))
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation",6)
		actions.add_child(_button("Editar","edit",func(): _command("EDIT",{"index":index}),color))
		actions.add_child(_button("Vender","transfer",func(): _command("SELL",{"index":index}),color))
		card.add_child(actions)
		card.add_child(_button("Hipotecar ao banco","bank",func(): _command("MORTGAGE",{"index":index}),color))

func _render_history() -> void:
	body.add_child(_label("HISTÓRICO DA MESA",12,MUTED))
	var transactions: Array = snapshot.get("transactions",[]).duplicate()
	transactions.reverse()
	if transactions.is_empty(): body.add_child(_label("As negociações da mesa vão aparecer aqui.",18,MUTED))
	for tx in transactions:
		var card := _card(body)
		card.add_child(_label(str(tx.get("from","Banco"))+" → "+str(tx.get("to","Banco")),16))
		card.add_child(_label(_money(float(tx.amount)),23,GREEN))
		if not str(tx.get("note","")).is_empty(): card.add_child(_label(str(tx.note),13,MUTED))

func _animate_money(target: float, immediate: bool) -> void:
	if balance_tween: balance_tween.kill()
	var increasing := target > money_value
	if immediate or reduced:
		_set_money(target)
		balance_label.text = _money(target)
		return
	coin_icon.spin = true
	if increasing: fx.celebrate(balance_label.global_position+Vector2(30,20))
	balance_label.add_theme_color_override("font_color",GREEN if increasing else RED)
	balance_tween = create_tween()
	balance_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	balance_tween.tween_method(_set_money,money_value,target,minf(1.8,0.9+absf(target-money_value)/20000.0))
	balance_tween.tween_callback(func():
		balance_label.text = _money(target)
		coin_icon.spin = false
		balance_label.add_theme_color_override("font_color",GREEN)
	)

func _set_money(value: float) -> void:
	money_value = value
	if is_instance_valid(balance_label): balance_label.text = _money(round(value))

func _money(value: float) -> String:
	var digits := str(int(floor(absf(value))))
	var cents := int(round(absf(value)*100)) % 100
	var formatted := ""
	for i in range(digits.length()):
		if i>0 and (digits.length()-i)%3==0: formatted += "."
		formatted += digits[i]
	return "R$ "+("-" if value<0 else "")+formatted+(",%02d" % cents if cents else "")

func _entrance(node: Control) -> void:
	if reduced: return
	node.modulate.a = 0
	var tween := create_tween()
	tween.tween_property(node,"modulate:a",1.0,0.3)

func _fit_width() -> void:
	if not is_instance_valid(content): return
	var inset := maxi(18,int((size.x-560)/2))
	content.get_parent().add_theme_constant_override("margin_left",inset)
	content.get_parent().add_theme_constant_override("margin_right",inset)
