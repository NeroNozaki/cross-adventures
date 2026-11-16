extends SceneTree
## Exercita a vinheta real, retorno ao menu e o botão que encerra o processo.
var verificacoes := 0
var erros := 0

func _initialize() -> void:
	call_deferred("executar")

func conferir(condicao: bool, mensagem: String) -> void:
	verificacoes += 1
	if not condicao:
		erros += 1
		push_error(mensagem)

func executar() -> void:
	create_timer(24).timeout.connect(func(): push_error("Tempo limite do encerramento"); quit(1))
	var historia = root.get_node("HistoriaDupla")
	historia.silenciado = false
	change_scene_to_file("res://cenas/screens/fim_aventura.tscn")
	await scene_changed
	var cena = current_scene
	var atores = cena.dupla
	conferir(atores.sprites.size() == 2,"Nico e Otto participam da saída")
	conferir(cena.texto.visible_characters == 0,"A mensagem não cobre a saída pelo portão")
	conferir(cena.voltar.disabled and cena.sair.disabled,"Ações finais aguardam a mensagem")
	conferir(cena.musica.playing,"Tema de encerramento começa na cena")
	conferir(cena.musica.stream.loop,"Música continua enquanto a criança lê")
	var inicio_nico: Vector2 = atores.sprites[0].position
	var inicio_otto: Vector2 = atores.sprites[1].position
	await create_timer(1.8).timeout
	conferir(atores.sprites[0].position.x < inicio_nico.x-30,"Nico caminha para fora do portão")
	conferir(atores.sprites[1].position.x < inicio_otto.x-20,"Otto caminha para fora do portão")
	conferir(atores.sprites[0].animation == "walk_left" and atores.sprites[1].animation == "walk_left","Os dois caminham com quadros animados")
	conferir(atores.sprites[0].modulate.a == 1 and atores.sprites[1].modulate.a == 1,"A dupla aparece gradualmente na soleira")
	await create_timer(2.1).timeout
	conferir(atores.festa and cena.comemorou,"Comemoração e som de vitória iniciam após a caminhada")
	conferir(atores.confetes.size() > 0 and atores.confetes.size() <= 72,"Confetes estão visíveis e limitados")
	conferir(atores.saltos[0] > 0 and atores.saltos[1] > 0,"Os dois saltam de alegria sem deslocar o chão")
	conferir(atores.sprites[0].animation == "festejar","Nico usa a pose de braços erguidos do próprio asset")
	conferir(atores.baloes[0].visible,"Um balão breve acompanha a comemoração")
	await create_timer(3).timeout
	conferir(cena.texto.visible_characters > 0 and cena.texto.visible_characters < cena.MENSAGEM.length(),"Mensagem aparece aos poucos após a comemoração")
	conferir(atores.confetes.is_empty(),"Partículas temporárias são removidas")
	conferir(not cena.pular.visible,"Atalho de animação desaparece ao chegar à mensagem")
	conferir(not atores.baloes[0].visible and not atores.baloes[1].visible,"Balões não permanecem sobre a leitura")
	await create_timer(5).timeout
	conferir(cena.texto.visible_characters == cena.MENSAGEM.length(),"A mensagem motivadora fica completa")
	conferir(cena.pronto and cena.botoes.visible,"Conclusão oferece ações explícitas")
	conferir(not cena.voltar.disabled and not cena.sair.disabled,"Voltar e sair ficam disponíveis")
	conferir(cena.voltar.has_focus(),"O teclado recebe foco na ação final")
	conferir(cena.fim.modulate.a == 1,"A aventura tem uma identificação clara de fim")
	conferir(cena.painel.get_global_rect().end.x <= cena.size.x and cena.painel.position.x >= 0,"Mensagem cabe na área da janela")
	conferir(cena.botoes.get_global_rect().end.y <= cena.size.y,"Botões finais não ficam cortados")
	var m := InputEventKey.new()
	m.physical_keycode = KEY_M
	m.pressed = true
	cena._unhandled_key_input(m)
	await process_frame
	conferir(historia.silenciado and cena.musica.stream_paused,"M silencia também o encerramento")
	cena._unhandled_key_input(m)
	await process_frame
	conferir(not historia.silenciado and not cena.musica.stream_paused,"M restaura a trilha")
	await create_timer(0.4).timeout
	conferir(current_scene == cena and not cena.saindo,"A leitura não fecha o jogo automaticamente")
	var referencia_musica: WeakRef = weakref(cena.musica)
	cena.voltar.pressed.emit()
	cena.voltar.pressed.emit()
	await create_timer(1.2).timeout
	conferir(current_scene.scene_file_path.ends_with("start_menu.tscn"),"Voltar retorna ao menu sem transição duplicada")
	conferir(not paused,"Retorno não deixa a árvore pausada")
	conferir(referencia_musica.get_ref() == null,"Trilha final é liberada ao voltar ao menu")
	change_scene_to_file("res://cenas/screens/fim_aventura.tscn")
	await scene_changed
	cena = current_scene
	cena.pular.pressed.emit()
	await process_frame
	conferir(cena.pronto and cena.texto.visible_characters == cena.MENSAGEM.length(),"Ver mensagem pula a animação e preserva o comunicado completo")
	conferir(not cena.voltar.disabled and not cena.sair.disabled,"Pular não deixa ações finais bloqueadas")
	if erros > 0:
		quit(1)
		return
	# Só o botão real deve encerrar. Se não o fizer, o temporizador falha o teste.
	cena.sair.pressed.emit()
	cena.sair.pressed.emit()
	conferir(cena.saindo and cena.sair.disabled and cena.voltar.disabled,"Sair bloqueia confirmações repetidas durante o fade")
	print("ENCERRAMENTO_OK: %d verificações; aguardando fechamento pelo botão Sair." % verificacoes)
	create_timer(1).timeout.connect(func(): push_error("Sair não encerrou o jogo"); quit(1))
