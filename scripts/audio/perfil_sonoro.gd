extends Resource
## Perfil editavel de sons; os arquivos originais ficam em assets/SONS.

@export var passos: Array[AudioStream] = []
@export var ataque: Array[AudioStream] = []
@export var acerto: Array[AudioStream] = []
@export var dano: Array[AudioStream] = []
@export var morte: Array[AudioStream] = []
@export var defesa: Array[AudioStream] = []
@export var bloqueio: Array[AudioStream] = []
@export var carga: Array[AudioStream] = []
@export var ricochete: Array[AudioStream] = []
@export var distancia_entre_passos: float = 22.0
@export var tom_base: float = 1.0
@export var volume_passos_db: float = -18.0
@export var volume_acoes_db: float = -11.0
@export var volume_impactos_db: float = -12.0
@export var atraso_morte: float = 0.0

func clipes(evento: StringName) -> Array[AudioStream]:
	match evento:
		&"passo": return passos
		&"ataque": return ataque
		&"acerto": return acerto
		&"dano": return dano
		&"morte": return morte
		&"defesa": return defesa
		&"bloqueio": return bloqueio
		&"ricochete": return ricochete
		&"carga": return carga
	return []
