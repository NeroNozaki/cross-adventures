extends AudioStreamPlayer
## Sons curtos para confirmação e navegação, com intervalo para o foco e o mouse.
const BASE := "res://assets/SONS/INTERFACE/"
const SONS := {
	&"foco": preload(BASE + "SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg"),
	&"clique": preload(BASE + "CLIQUES/KENNEY_INTERFACE_SOUNDS/click_002.ogg"),
	&"abrir": preload(BASE + "ABRIR_FECHAR/KENNEY_INTERFACE_SOUNDS/open_001.ogg"),
	&"fechar": preload(BASE + "ABRIR_FECHAR/KENNEY_INTERFACE_SOUNDS/close_001.ogg"),
	&"jogar": preload(BASE + "CONFIRMACAO/KENNEY_INTERFACE_SOUNDS/confirmation_001.ogg")
}
var ultimo_foco := -1_000

func _ready() -> void:
	max_polyphony = 2

func tocar(evento: StringName) -> void:
	if HistoriaDupla.silenciado:
		return
	var agora := Time.get_ticks_msec()
	if evento == &"foco":
		if agora - ultimo_foco < 95:
			return
		ultimo_foco = agora
	stream = SONS[evento]
	volume_db = -23.0 if evento == &"foco" else -18.0
	play()

func ligar(botao: Button, evento := &"clique") -> void:
	botao.mouse_entered.connect(tocar.bind(&"foco"))
	botao.focus_entered.connect(tocar.bind(&"foco"))
	if evento != &"":
		botao.button_down.connect(tocar.bind(evento))
