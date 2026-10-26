extends Hero
## Cada comando aceito avanca um golpe; um unico comando pode aguardar o fim do atual.

@export var janela_combo: float = 1.1
@export var janela_buffer: float = 0.7
var passo_combo: int = 0
var restante_combo: float = 0.0
var buffer_ataque: float = 0.0
signal golpe_combo(passo: int)

func _physics_process(delta: float) -> void:
	restante_combo = maxf(0.0, restante_combo - delta)
	buffer_ataque = maxf(0.0, buffer_ataque - delta)
	super._physics_process(delta)
	if esta_morto or defendendo or tempo_dano > 0.0:
		buffer_ataque = 0.0
	elif buffer_ataque > 0.0 and not atacando and recarga.is_stopped():
		iniciar_ataque()

func iniciar_ataque() -> bool:
	if esta_morto or defendendo or tempo_dano > 0.0:
		buffer_ataque = 0.0
		return false
	if atacando or not recarga.is_stopped():
		buffer_ataque = janela_buffer
		return false
	passo_combo = 1 if restante_combo <= 0.0 else (passo_combo % 3) + 1
	duracao_ataque = [0.36, 0.4, 0.52][passo_combo - 1]
	preparo_ataque = [0.12, 0.14, 0.19][passo_combo - 1]
	intervalo_ataque = [0.39, 0.43, 0.56][passo_combo - 1]
	efeitos.variante_golpe = passo_combo
	buffer_ataque = 0.0
	var iniciou: bool = super.iniciar_ataque()
	if iniciou:
		restante_combo = janela_combo
		golpe_combo.emit(passo_combo)
	return iniciou

func obter_dano_ataque() -> int:
	return roundi(float(dano_ataque) * [1.0, 1.1, 1.5][maxi(0, passo_combo - 1)])

func _reproduzir(acao: String) -> void:
	if acao == "attack" and passo_combo > 0:
		animacao.play(StringName("combo_%d_%s" % [passo_combo, direcao]))
		animacao.offset = visual_offset
	else:
		super._reproduzir(acao)

func receber_dano(valor: int, origem: Vector2) -> void:
	var antes: int = vida_atual
	super.receber_dano(valor, origem)
	if vida_atual < antes:
		buffer_ataque = 0.0
		restante_combo = 0.0
