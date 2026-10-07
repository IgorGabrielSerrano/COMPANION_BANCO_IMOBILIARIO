extends Control

const Icon = preload("res://ui/icon.gd")
const Atmosphere = preload("res://ui/atmosphere.gd")
const ShellLayout = preload("res://layouts/estrutura.tscn")
const AccountLayout = preload("res://layouts/conta.tscn")
const PrisonLayout = preload("res://layouts/prisao.tscn")
const CardGradient = preload("res://ui/card_gradient.gdshader")
const FONTS = {
	"Inter": preload("res://fonts/Inter.ttf"), "NunitoSans": preload("res://fonts/NunitoSans.ttf"),
	"DMSans": preload("res://fonts/DMSans.ttf"), "Manrope": preload("res://fonts/Manrope.ttf"), "Sora": preload("res://fonts/Sora.ttf")
}
var palette: Dictionary = {"id":"c4","name":"C4 Bank","font":"Inter","bg":"#101113","surface":"#1d1f22","accent":"#dddfe3","accentText":"#16181c","text":"#f8f8fa","muted":"#a8adb7","border":"#33363c","soft":"#292c31","card":"#25282d","cardText":"#ffffff","positive":"#73d7b0","negative":"#f09999"}
var snapshot: Dictionary = {}
var view: Dictionary = {}
var last_signature: String = ""
var active_tab: String = "conta"
var active_screen: String = ""
var reduced: bool = false
var poll_time: float = 0.0
var content: Control
var body: VBoxContainer
var scroll_area: ScrollContainer
var header: Control
var navigation: Control
var balance_label: Label
var balance_pattern: String = "{saldo}"
var balance_tween: Tween
var money_value: float = 0.0
var coin_icon: Control
var fx: Control
var tab_buttons: Dictionary = {}
var touching_body: bool = false
var suppress_touch_click: bool = false
var font_bold: FontVariation
var qa: bool = false
@export_enum("c4", "mu", "intel", "new", "nexus") var preview_bank: String = "c4"

func _ready() -> void:
	fx = Atmosphere.new()
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fx)
	if OS.has_feature("web"): JavaScriptBridge.eval("window.parent.companionReady()")
	_read_snapshot()
	resized.connect(_fit_width)

func _process(delta: float) -> void:
	poll_time += delta
	if poll_time >= 0.2:
		poll_time = 0
		_read_snapshot()
		if qa: _publish_layout()

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
		var bank_presets: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://bank_themes.json"))
		result = {"state":{"pin":"3922","playerId":"demo","playerName":"Igor Gabriel","isBanker":true,"players":{"demo":{"name":"Igor Gabriel","balance":25000,"properties":[]}},"transactions":[]},"status":"Prévia","sound":true,"bankAppearance":bank_presets.get(preview_bank,palette)}
	if not result is Dictionary: return
	view = result
	var next_palette: Dictionary = view.get("bankAppearance",palette)
	var theme_changed := str(next_palette.get("id")) != str(palette.get("id"))
	palette = next_palette
	var next: Dictionary = view.get("state",{})
	var next_screen := "lobby" if str(next.get("pin","")).is_empty() else "game"
	var old_balance := float(snapshot.get("players",{}).get(snapshot.get("playerId",""),{}).get("balance",-1))
	var motion_changed: bool = reduced != view.get("reducedMotion",false)
	reduced = view.get("reducedMotion",false)
	qa = view.get("qa",false)
	fx.reduced = reduced
	snapshot = next
	var rebuilding := theme_changed or next_screen != active_screen or motion_changed
	if rebuilding:
		active_screen = next_screen
		_apply_palette()
		_build_screen()
	var signature := JSON.stringify([snapshot,active_tab,view.get("sound"),view.get("status")])
	if signature != last_signature:
		last_signature = signature
		if active_screen == "game":
			_render_body()
			var target := float(_me().get("balance",0))
			if active_tab == "conta": _animate_money(target,rebuilding or old_balance < 0 or old_balance == target)

func _apply_palette() -> void:
	RenderingServer.set_default_clear_color(_c("bg"))
	var skin := Theme.new()
	var font_source: Font = FONTS.get(palette.get("font"),FONTS.Inter)
	var regular := FontVariation.new()
	regular.base_font = font_source
	regular.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):400.0}
	skin.default_font = regular
	skin.default_font_size = 15
	for type in ["Label","Button","LineEdit"]: skin.set_color("font_color",type,_c("text"))
	theme = skin
	font_bold = FontVariation.new()
	font_bold.base_font = font_source
	font_bold.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"):600.0}

func _c(key: String) -> Color:
	return Color(palette.get(key,"#ffffff"))

func _me() -> Dictionary:
	return snapshot.get("players",{}).get(snapshot.get("playerId",""),{})

func _display(text: Variant) -> String:
	var clean := ""
	for char in str(text):
		var code := char.unicode_at(0)
		if code <= 0xffff and code != 0xfe0f and code != 0x200d: clean += char
	return clean.strip_edges()

func _command(action: String, payload: Dictionary = {}) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.parent.companionAction("+JSON.stringify(action)+","+JSON.stringify(payload)+")")
	elif action == "SETTINGS":
		var popup := PopupMenu.new()
		add_child(popup)
		var ids := ["c4","mu","intel","new","nexus"]
		var names := ["C4 Bank","MuBank","Intel Bank","NeoBank","Nexus Bank"]
		for i in range(names.size()): popup.add_item(names[i],i)
		popup.id_pressed.connect(func(id): preview_bank = ids[id])
		popup.popup_centered(Vector2i(250,240))

func _style(color: Color, border: Color, radius: int = 14, padding: int = 12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding
	box.content_margin_right = padding
	box.content_margin_top = padding
	box.content_margin_bottom = padding
	return box

func _label(text: Variant, font_size: int = 15, color_key: String = "text", bold: bool = false) -> Label:
	var label := Label.new()
	label.text = _display(text)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",_c(color_key))
	if bold: label.add_theme_font_override("font",font_bold)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _icon(kind: String, tint: Color, dimension: int = 20) -> Control:
	var icon := Icon.new()
	icon.kind = kind
	icon.tint = tint
	icon.custom_minimum_size = Vector2(dimension,dimension)
	if kind == "coin": icon.spin = not reduced
	return icon

func _button(text: String, kind: String, callback: Callable, tone: String = "normal", qa_key: String = "") -> Button:
	var button := Button.new()
	button.set_meta("qa_key",qa_key)
	button.custom_minimum_size.y = 44
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := _c("soft") if tone == "soft" else _c("accent") if tone == "filled" else _c("surface")
	var ink := _c("accentText") if tone == "filled" else _c("negative") if tone == "danger" else _c("text")
	button.add_theme_stylebox_override("normal",_style(normal,_c("border"),12,8))
	button.add_theme_stylebox_override("hover",_style(_c("soft"),_c("accent"),12,8))
	button.add_theme_stylebox_override("pressed",_style(_c("soft"),_c("accent"),12,8))
	button.add_theme_stylebox_override("focus",_style(Color(0,0,0,0),_c("accent"),12,8))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_right = -6
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation",5)
	if not kind.is_empty(): row.add_child(_icon(kind,ink,18))
	if not text.is_empty():
		var label := _label(text,12)
		label.add_theme_color_override("font_color",ink)
		label.add_theme_font_override("font",font_bold)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.add_child(label)
	button.add_child(row)
	button.set_meta("feedback",row)
	button.pressed.connect(func():
		if suppress_touch_click: return
		var feedback: Control = button.get_meta("feedback")
		if not reduced and is_instance_valid(feedback):
			feedback.pivot_offset = feedback.size / 2
			var tween := button.create_tween()
			tween.tween_property(feedback,"scale",Vector2(0.97,0.97),0.07)
			tween.tween_property(feedback,"scale",Vector2.ONE,0.15)
		callback.call()
	)
	return button

func _card(parent: Node, color_key: String = "surface") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_style(_c(color_key),_c("border")))
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	panel.add_child(box)
	return box

func _build_screen() -> void:
	if balance_tween: balance_tween.kill()
	scroll_area = null
	balance_label = null
	coin_icon = null
	if is_instance_valid(content):
		content.get_parent().hide()
		content.get_parent().queue_free()
	last_signature = ""
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	content = ShellLayout.instantiate()
	margin.add_child(content)
	_fit_width()
	_skin_layout(content)
	_fill_layout(content,{"banco":palette.name,"mesa":"Mesa "+str(snapshot.get("pin","")) if active_screen=="game" else "Seu banco de brincadeira"})
	header = content.get_node("Cabecalho")
	content.get_node("Cabecalho/Tema").pressed.connect(func(): _command("SETTINGS"))
	var exit: Button = content.get_node("Cabecalho/Sair")
	exit.visible = active_screen == "game"
	exit.pressed.connect(func(): _command("LEAVE"))
	scroll_area = content.get_node("AreaMovel")
	body = content.get_node("AreaMovel/Conteudo")
	navigation = content.get_node("Abas")
	navigation.visible = active_screen == "game"
	if active_screen == "lobby":
		scroll_area.offset_bottom = -12
		_build_lobby()
		return
	tab_buttons.clear()
	for entry in [["Conta","conta"],["Jogadores","jogadores"],["Posses","posses"],["Historico","historico"],["Prisao","prisao"]]:
		var key: String = entry[1]
		var tab: Button = content.get_node("Abas/"+entry[0])
		tab.pressed.connect(func():
			if not suppress_touch_click: _select_tab(key)
		)
		tab_buttons[key] = tab
	_entrance(content)

func _skin_layout(root: Control) -> void:
	var layout_theme: Theme = root.theme.duplicate()
	layout_theme.default_font = theme.default_font
	root.theme = layout_theme
	_skin_node(root)

func _skin_node(node: Node) -> void:
	if node is Label:
		node.add_theme_color_override("font_color",_c(node.get_meta("tone","text")))
		if node.get_meta("bold",false): node.add_theme_font_override("font",font_bold)
	elif node is Panel:
		var panel_style: StyleBoxFlat = node.get_theme_stylebox("panel").duplicate()
		panel_style.bg_color = _c(node.get_meta("tone","surface"))
		panel_style.border_color = _c("border")
		node.add_theme_stylebox_override("panel",panel_style)
		if node.get_meta("gradient_eligible",false) and palette.id == "new": _gradient_card(node)
	elif node is Button:
		var normal: StyleBoxFlat = node.get_theme_stylebox("normal").duplicate()
		normal.bg_color = _c("soft") if node.get_meta("tone","") == "soft" else _c("surface")
		normal.border_color = _c("border")
		node.add_theme_stylebox_override("normal",normal)
		for key in ["hover","pressed","focus"]:
			var feedback: StyleBoxFlat = normal.duplicate()
			feedback.bg_color = _c("soft")
			feedback.border_color = _c("accent")
			node.add_theme_stylebox_override(key,feedback)
		node.add_theme_color_override("font_color",_c("text"))
		node.add_theme_color_override("font_hover_color",_c("text"))
		node.add_theme_color_override("font_pressed_color",_c("text"))
		node.add_theme_font_override("font",font_bold)
	elif node is Control and node.get_script() == Icon:
		node.tint = Color("#eac46b") if node.get_meta("tone","") == "gold" else _c("accent")
		if node.kind == "coin": node.spin = not reduced
	for child in node.get_children(): _skin_node(child)

func _fill_layout(node: Node, data: Dictionary) -> void:
	if node is Label:
		node.set_meta("template",node.text)
		node.text = _display(node.text.format(data))
	for child in node.get_children(): _fill_layout(child,data)

func _gradient_card(panel: Panel) -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(palette.gradientFrom),Color(palette.gradientTo)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill_to = Vector2(1,1)
	var background := TextureRect.new()
	background.texture = texture
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = CardGradient
	background.material = shader_material
	panel.add_child(background)
	panel.move_child(background,0)
	panel.resized.connect(func(): shader_material.set_shader_parameter("rect_size",panel.size))
	shader_material.set_shader_parameter("rect_size",panel.size)

func _build_lobby() -> void:
	body.add_child(_label("Seu banco.\nSua mesa.",32,"text",true))
	body.add_child(_label("Escolha seu visual e cuide da fortuna no tabuleiro.",15,"muted"))
	var box := _card(body)
	var coin := _icon("coin",_c("accent"),36)
	coin.custom_minimum_size.y = 48
	box.add_child(coin)
	var name_input := _text_input(box,"Seu nome","name_input")
	var pin_input := _text_input(box,"PIN da mesa · 4 dígitos","pin_input")
	pin_input.max_length = 4
	box.add_child(_button("Entrar na mesa","people",func(): _command("JOIN",{"name":name_input.text,"pin":pin_input.text}),"filled","join"))
	box.add_child(_label("Ou crie uma mesa",12,"muted"))
	var cash := _text_input(box,"Saldo inicial","cash_input")
	cash.text = "25000"
	box.add_child(_button("Criar mesa","bank",func(): _command("CREATE",{"name":name_input.text,"cash":cash.text}),"soft","create"))
	body.add_child(_label("Para voltar a uma partida, use o mesmo PIN e nome.",12,"muted"))

func _text_input(parent: Node, placeholder: String, qa_key: String) -> LineEdit:
	var field := LineEdit.new()
	field.set_meta("qa_key",qa_key)
	field.placeholder_text = placeholder
	field.custom_minimum_size.y = 46
	field.add_theme_stylebox_override("normal",_style(_c("bg"),_c("border"),10,10))
	field.add_theme_stylebox_override("focus",_style(_c("bg"),_c("accent"),10,10))
	parent.add_child(field)
	return field

func _select_tab(tab: String) -> void:
	active_tab = tab
	last_signature = ""
	scroll_area.scroll_vertical = 0
	_read_snapshot()
	_entrance(body)

func _render_body() -> void:
	if balance_tween: balance_tween.kill()
	balance_label = null
	coin_icon = null
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for key in tab_buttons:
		var tab_style: StyleBoxFlat = tab_buttons[key].get_theme_stylebox("normal").duplicate()
		tab_style.bg_color = _c("soft") if key==active_tab else _c("bg")
		tab_style.border_color = _c("bg")
		tab_buttons[key].add_theme_stylebox_override("normal",tab_style)
	match active_tab:
		"posses": _render_properties()
		"historico": _render_history()
		"jogadores": _render_players()
		"prisao": _render_prison()
		_: _render_account()

func _render_account() -> void:
	var me := _me()
	var layout: Control = AccountLayout.instantiate()
	body.add_child(layout)
	_skin_layout(layout)
	var connection := str(view.get("status","Conectando…"))
	var short_connection := "Online" if "Online" in connection or "Conectado" in connection else "Conectando" if "Conectando" in connection else "Offline"
	_fill_layout(layout,{"nome":_display(snapshot.get("playerName","Jogador")),"papel":"Banqueiro" if snapshot.get("isBanker",false) else "",
		"saldo":_money(money_value),"conexao":short_connection,
		"jogadores":snapshot.get("players",{}).size(),"posses":me.get("properties",[]).size()})
	balance_label = layout.get_node("Patrimonio/Valor")
	balance_pattern = balance_label.get_meta("template","{saldo}")
	coin_icon = layout.get_node("Patrimonio/Moeda")
	for entry in [["Pagar","PAY_PLAYER"],["Banco","PAY_BANK"],["Receber","RECEIVE_BANK"],["Inicio","GO"]]:
		var action: String = entry[1]
		layout.get_node("Acoes/"+entry[0]).pressed.connect(func():
			if not suppress_touch_click: _command(action)
		)
	var players_panel: Panel = layout.get_node("JogadoresSala")
	players_panel.offset_bottom = players_panel.offset_top + maxi(80,46+snapshot.get("players",{}).size()*33)
	_render_player_preview(players_panel)
	var history_title: Label = layout.get_node("TituloHistorico")
	history_title.offset_top = players_panel.offset_bottom + 14
	history_title.offset_bottom = history_title.offset_top + 28
	layout.custom_minimum_size.y = history_title.offset_bottom + 10
	var txs: Array = snapshot.get("transactions",[])
	if txs.is_empty(): body.add_child(_label("As negociações aparecem aqui.",13,"muted"))
	else:
		for i in range(txs.size()-1,maxi(-1,txs.size()-4),-1): _transaction_row(txs[i])

func _render_prison() -> void:
	var me := _me()
	var jailed: bool = me.get("jailed",false)
	var layout: Control = PrisonLayout.instantiate()
	body.add_child(layout)
	_skin_layout(layout)
	_fill_layout(layout,{"prisao":"Preso · %d/3 rodadas" % int(me.get("jailRounds",0)) if jailed else "Livre · duplas %d/3" % int(me.get("consecutiveDoubles",0))})
	layout.get_node("Cadeia/Entrar").visible = not jailed
	layout.get_node("Cadeia/Rodada").visible = jailed
	layout.get_node("Cadeia/FimTurno").visible = not jailed
	layout.get_node("Cadeia/Entrar").pressed.connect(func():
		if not suppress_touch_click: _command("JAIL",{"action":"ENTER"})
	)
	layout.get_node("Cadeia/Rodada").pressed.connect(func():
		if not suppress_touch_click: _command("JAIL",{"action":"ROUND"})
	)
	layout.get_node("Cadeia/Dupla").pressed.connect(func():
		if not suppress_touch_click: _command("JAIL",{"action":"DOUBLES" if _me().get("jailed",false) else "MARK_DOUBLES"})
	)
	layout.get_node("Cadeia/FimTurno").pressed.connect(func():
		if not suppress_touch_click: _command("JAIL",{"action":"END_TURN"})
	)
	body.add_child(_label("A terceira dupla consecutiva leva à prisão. Ao completar três rodadas ou tirar dados iguais, você sai e a contagem zera.",12,"muted"))
	body.add_child(_label("Situação dos jogadores",15,"text",true))
	for player in snapshot.get("players",{}).values():
		var box := _card(body)
		box.add_child(_label(player.name,14,"text",true))
		box.add_child(_label("Preso · %d/3 rodadas" % int(player.get("jailRounds",0)) if player.get("jailed",false) else "Livre · duplas %d/3" % int(player.get("consecutiveDoubles",0)),12,"muted"))

func _render_player_preview(panel: Panel) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,10)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,6)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",4)
	margin.add_child(box)
	var heading := HBoxContainer.new()
	heading.add_child(_label("Jogadores na sala",13,"text",true))
	var all := _button("Ver todos","",func(): _select_tab("jogadores"),"normal","view_players")
	all.custom_minimum_size = Vector2(78,28)
	all.size_flags_horizontal = Control.SIZE_SHRINK_END
	heading.add_child(all)
	box.add_child(heading)
	var players: Array = snapshot.get("players",{}).values()
	for i in range(players.size()):
		var player: Dictionary = players[i]
		var row := HBoxContainer.new()
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation",0)
		details.add_child(_label(_display(player.name).replace(" (Banqueiro)",""),12,"text",true))
		details.add_child(_label("Preso %d/3" % int(player.get("jailRounds",0)) if player.get("jailed",false) else "Livre · duplas %d/3" % int(player.get("consecutiveDoubles",0)),10,"muted"))
		row.add_child(details)
		var amount := _label(_money(float(player.balance)),12,"positive",true)
		amount.autowrap_mode = TextServer.AUTOWRAP_OFF
		amount.size_flags_horizontal = Control.SIZE_SHRINK_END
		row.add_child(amount)
		box.add_child(row)

func _render_jail(me: Dictionary) -> void:
	var box := _card(body)
	var jailed: bool = me.get("jailed",false)
	var title := HBoxContainer.new()
	title.add_child(_icon("lock" if jailed else "dice",_c("accent"),20))
	title.add_child(_label("Preso · %d/3 rodadas" % int(me.get("jailRounds",0)) if jailed else "Livre · duplas %d/3" % int(me.get("consecutiveDoubles",0)),14,"text",true))
	box.add_child(title)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	if jailed:
		actions.add_child(_button("+1 rodada","history",func(): _command("JAIL",{"action":"ROUND"}),"normal","jail_round"))
		actions.add_child(_button("Dados iguais","dice",func(): _command("JAIL",{"action":"DOUBLES"}),"soft","jail_release"))
	else:
		actions.add_child(_button("Ir à cadeia","lock",func(): _command("JAIL",{"action":"ENTER"}),"normal","jail_enter"))
		actions.add_child(_button("Dados iguais","dice",func(): _command("JAIL",{"action":"MARK_DOUBLES"}),"soft","jail_double"))
	box.add_child(actions)
	if not jailed: box.add_child(_button("Encerrar turno · zerar duplas","",func(): _command("JAIL",{"action":"END_TURN"}),"normal","end_turn"))

func _render_players() -> void:
	body.add_child(_label("Jogadores na mesa",23,"text",true))
	body.add_child(_label("%d participantes · mesa %s" % [snapshot.get("players",{}).size(),snapshot.get("pin","")],12,"muted"))
	for id in snapshot.get("players",{}):
		var player: Dictionary = snapshot.players[id]
		var card := _card(body)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",8)
		row.add_child(_icon("people",_c("accent"),22))
		row.add_child(_label(_display(player.name).replace(" (Banqueiro)","")+(" · você" if id==snapshot.playerId else ""),15,"text",true))
		var amount := _label(_money(float(player.balance)),15,"positive",true)
		amount.autowrap_mode = TextServer.AUTOWRAP_OFF
		amount.size_flags_horizontal = Control.SIZE_SHRINK_END
		row.add_child(amount)
		card.add_child(row)
		card.add_child(_label(("Banqueiro · " if player.get("isBanker",false) else "")+("Preso %d/3" % int(player.get("jailRounds",0)) if player.get("jailed",false) else "Livre · duplas %d/3" % int(player.get("consecutiveDoubles",0))),11,"muted"))
		for prop in player.get("properties",[]):
			var property := _label(_display(prop.name)+" · aluguel "+_money(float(prop.rent)),12)
			property.add_theme_color_override("font_color",_property_color(prop.get("color","#f1c40f")))
			card.add_child(property)

func _property_color(hex: String) -> Color:
	var color := Color(hex)
	if _c("bg").get_luminance()>0.6: color = color.darkened(0.38 if color.get_luminance()<0.8 else 0.65)
	return color

func _render_properties() -> void:
	var heading := HBoxContainer.new()
	heading.add_child(_label("Minhas posses",23,"text",true))
	var buy := _button("Comprar","home",func(): _command("BUY"),"soft","buy")
	buy.size_flags_horizontal = Control.SIZE_SHRINK_END
	buy.custom_minimum_size.x = 94
	heading.add_child(buy)
	body.add_child(heading)
	var properties: Array = _me().get("properties",[])
	body.add_child(_label("%d títulos · aluguéis, vendas e hipotecas" % properties.size(),12,"muted"))
	if properties.is_empty():
		var empty := _card(body)
		empty.add_child(_label("Sua próxima conquista começa aqui.",20,"text",true))
		empty.add_child(_label("Compre uma posse para acompanhar seus negócios.",13,"muted"))
	for index in range(properties.size()):
		var prop: Dictionary = properties[index]
		var card := _card(body)
		var title := _label(prop.name,18,"text",true)
		title.add_theme_color_override("font_color",_property_color(prop.get("color","#f1c40f")))
		card.add_child(title)
		card.add_child(_label("Aluguel "+_money(float(prop.rent))+" · Compra "+_money(float(prop.get("price",0))),12,"muted"))
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation",6)
		actions.add_child(_button("Editar","edit",func(): _command("EDIT",{"index":index}),"normal","prop_edit_"+str(index)))
		actions.add_child(_button("Vender","transfer",func(): _command("SELL",{"index":index}),"normal","prop_sell_"+str(index)))
		actions.add_child(_button("Hipotecar","bank",func(): _command("MORTGAGE",{"index":index}),"normal","prop_mortgage_"+str(index)))
		card.add_child(actions)

func _render_history() -> void:
	body.add_child(_label("Histórico da mesa",23,"text",true))
	var txs: Array = snapshot.get("transactions",[])
	body.add_child(_label("%d movimentações" % txs.size(),12,"muted"))
	if txs.is_empty(): body.add_child(_label("As negociações da mesa vão aparecer aqui.",14,"muted"))
	for i in range(txs.size()-1,-1,-1): _transaction_row(txs[i])

func _transaction_row(tx: Dictionary) -> void:
	var card := _card(body)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	row.add_child(_icon("transfer",_c("accent"),18))
	row.add_child(_label(_display(tx.get("from","Banco"))+" para "+_display(tx.get("to","Banco")),13,"text",true))
	var amount := _label(_money(float(tx.get("amount",0))),14,"text",true)
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	amount.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(amount)
	card.add_child(row)
	if not str(tx.get("note","")).is_empty(): card.add_child(_label(tx.note,11,"muted"))

func _animate_money(target: float, immediate: bool) -> void:
	if balance_tween: balance_tween.kill()
	if immediate or reduced:
		_set_money(target)
		balance_label.text = balance_pattern.format({"saldo":_money(target)})
		return
	var increasing := target>money_value
	if increasing: fx.celebrate(balance_label.global_position+Vector2(30,16))
	balance_tween = create_tween()
	balance_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	balance_tween.tween_method(_set_money,money_value,target,minf(1.8,0.9+absf(target-money_value)/20000.0))
	balance_tween.tween_callback(func():
		if is_instance_valid(balance_label): balance_label.text = balance_pattern.format({"saldo":_money(target)})
	)

func _set_money(value: float) -> void:
	money_value = value
	if is_instance_valid(balance_label): balance_label.text = balance_pattern.format({"saldo":_money(round(value))})

func _money(value: float) -> String:
	var total := int(round(absf(value)*100))
	var digits := str(total/100)
	var cents := total%100
	var formatted := ""
	for i in range(digits.length()):
		if i>0 and (digits.length()-i)%3==0: formatted += "."
		formatted += digits[i]
	return "R$ "+("-" if value<0 else "")+formatted+(",%02d" % cents if cents else "")

func _entrance(node: Control) -> void:
	if reduced: return
	node.modulate.a = 0
	create_tween().tween_property(node,"modulate:a",1.0,0.2)

func _fit_width() -> void:
	if not is_instance_valid(content): return
	var inset := maxi(0,int((size.x-440)/2))
	content.get_parent().add_theme_constant_override("margin_left",inset)
	content.get_parent().add_theme_constant_override("margin_right",inset)

func _publish_layout() -> void:
	if not OS.has_feature("web") or not is_instance_valid(scroll_area): return
	var physical: Variant = JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify([window.innerWidth,window.innerHeight])")))
	var ratio := Vector2(float(physical[0]),float(physical[1])) / get_viewport_rect().size
	var controls := {}
	var texts: Array = []
	var missing: Array = []
	_collect_controls(content,controls,ratio)
	_collect_texts(content,texts,missing)
	var area := scroll_area.get_global_rect()
	var data := {"theme":palette.id,"tab":active_tab,"screen":active_screen,"buttons":controls,
		"scroll":{"x":area.position.x*ratio.x,"y":area.position.y*ratio.y,"width":area.size.x*ratio.x,"height":area.size.y*ratio.y,"offset":scroll_area.scroll_vertical},
		"coinSpinning":is_instance_valid(coin_icon) and coin_icon.spin,"texts":texts,"missingGlyphs":missing}
	JavaScriptBridge.eval("window.parent.companionLayout="+JSON.stringify(data))

func _collect_controls(node: Node, controls: Dictionary, ratio: Vector2) -> void:
	if node is Control and node.has_meta("qa_key") and node.is_visible_in_tree():
		var key: String = node.get_meta("qa_key")
		if not key.is_empty():
			var rect: Rect2 = (node as Control).get_global_rect()
			controls[key] = {"x":rect.position.x*ratio.x,"y":rect.position.y*ratio.y,"width":rect.size.x*ratio.x,"height":rect.size.y*ratio.y}
	for child in node.get_children(): _collect_controls(child,controls,ratio)

func _collect_texts(node: Node, texts: Array, missing: Array) -> void:
	if node is Label:
		texts.append(node.text)
		var font: Font = node.get_theme_font("font")
		for char in node.text:
			var code: int = char.unicode_at(0)
			if code>32 and not font.has_char(code) and not missing.has(char): missing.append(char)
	for child in node.get_children(): _collect_texts(child,texts,missing)
