extends Villain

func _morrer() -> void:
	super._morrer()
	animacao.hide()
	nome_label.hide()
	$ArmaduraCaida.cair()
