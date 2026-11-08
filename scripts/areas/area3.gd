extends BaseArea

@onready var button2 = $objects/button2
@onready var button3 = $objects/button3
@onready var switch2 = $objects/switch2

@onready var player1 = $Personagens/Player1
@onready var player2 = $Personagens/Player2
var _fences_opened := false

func _ready() -> void:
	super._ready()
	
	# Connect both buttons to the same check
	if button2 and button2.has_signal("state_changed"):
		button2.state_changed.connect(_check_both_buttons)
	if button3 and button3.has_signal("state_changed"):
		button3.state_changed.connect(_check_both_buttons)

func _check_both_buttons(_state = null) -> void:
	if _fences_opened:
		return
	if not button2 or not button3:
		return

	# Both must currently be considered pressed
	var both_pressed := _is_button_pressed(button2) and _is_button_pressed(button3)
	if not both_pressed:
		return

	# Extra safety: make sure there is actually something standing on each
	if _get_bodies_on(button2) == 0 or _get_bodies_on(button3) == 0:
		return

	# Success — lock everything
	_fences_opened = true
	_lock_button(button2)
	_lock_button(button3)


func _is_button_pressed(btn: Node) -> bool:
	if "pressed" in btn:
		return btn.pressed == true
	return false


func _get_bodies_on(btn: Node) -> int:
	if "bodies_on_button" in btn:
		return int(btn.bodies_on_button)
	return 0


func _lock_button(btn: Node) -> void:
	btn.single_use = true
	btn.pressed = true

	# Keep the button permanently "occupied" so it doesn't release
	if btn.has_method("set_deferred"):
		btn.set_deferred("bodies_on_button", 999)
	else:
		btn.bodies_on_button = 999

	# Play the permanently-pressed animation if it exists
	var anim = btn.get("animation")
	if anim and anim.has_method("play"):
		anim.play("3-pressed")


func _process(_delta: float) -> void:
	if has_node("MarcadorPlayer2") and player2:
		$MarcadorPlayer2.position = player2.position + Vector2(0, 8)
		$MarcadorPlayer2.visible = not player2.esta_morto
