extends Node
const SHADER=preload("res://scripts/visual/respiracao.gdshader")
var ator: CharacterBody2D
var material_respiracao: ShaderMaterial
var tempo: float=0.0
var intensidade: float=0.0
func _ready() -> void:
	ator=get_parent()
	tempo=float(posmod(hash(str(ator.name)),31))*0.19
	material_respiracao=ShaderMaterial.new()
	material_respiracao.shader=SHADER
	ator.animacao.material=material_respiracao
func _process(delta: float) -> void:
	tempo+=delta
	var repouso: bool=not ator.esta_morto and not ator.pulando and not ator.atacando and ator.tempo_dano<=0 and ator.velocity.length()<0.5
	intensidade=(sin(tempo*TAU/3.2)+1.0)*0.5 if repouso else 0.0
	material_respiracao.set_shader_parameter("inspiracao",intensidade)
