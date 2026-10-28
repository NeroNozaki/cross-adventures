extends SceneTree
const UI=preload("res://scripts/visual/tema_pixel.gd")
var falhas: Array[String]=[]
var total: int=0
func _initialize() -> void: call_deferred("rodar")
func conferir(ok: bool,t: String) -> void:
 total+=1
 if not ok:
  falhas.append(t)
  push_error(t)
func quadros() -> void:
 await process_frame
 await process_frame
func tecla(codigo: Key) -> void:
 var e: InputEventKey=InputEventKey.new()
 e.physical_keycode=codigo
 e.pressed=true
 Input.parse_input_event(e)
 await quadros()
 e=InputEventKey.new()
 e.physical_keycode=codigo
 e.pressed=false
 Input.parse_input_event(e)
 await quadros()
func rodar() -> void:
 AudioServer.set_bus_mute(0,true)
 var menu: Control=load("res://cenas/interface/menu.tscn").instantiate()
 root.add_child(menu)
 current_scene=menu
 await quadros()
 conferir(menu.piso!=null and menu.inicio.has_focus(),"Menu carrega arte e foco")
 conferir(menu.theme.default_font==UI.fonte(),"Menu usa a fonte pixel compartilhada")
 conferir(UI.fonte().antialiasing==TextServer.FONT_ANTIALIASING_NONE,"Fonte sem suavizacao")
 for letra in "áéíóúãõâêôçÁÉÇ": conferir(UI.fonte().has_char(letra.unicode_at(0)),"Acento disponivel: "+letra)
 conferir(not menu.quadro.visible,"Guia inicialmente fechado")
 menu.botoes.get_child(1).pressed.emit()
 conferir(menu.quadro.visible,"Controles abre guia")
 menu.botoes.get_child(1).pressed.emit()
 conferir(not menu.quadro.visible,"Controles fecha guia")
 var audio: Node=root.get_node("InterfaceAudio")
 conferir(int(audio.eventos.get("confirmar",0))>0 and int(audio.eventos.get("abrir",0))>0,"Botoes produzem sons de confirmacao e abertura")
 menu.inicio.pressed.emit()
 await create_timer(0.08).timeout
 conferir(root.get_node("FluxoTela").em_transicao and paused,"Transicao bloqueia a simulacao")
 await create_timer(0.7).timeout
 var fase: Node2D=current_scene
 conferir(fase.arquivo_dados.ends_with("01_jardim.json") and not paused,"Inicio conclui transicao sem deixar pausa")
 var gui: Control=fase.get_node("Interface").get_child(0)
 conferir(gui.theme.default_font==menu_font(),"HUD e menu usam a mesma fonte")
 conferir(not gui.estado_debug.visible and not fase.lucas.nome_label.visible,"HUD substitui textos sobre os herois")
 for n in ["01_jardim","02_galeria","03_oficina","04_santuario"]:
  var dados: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://recursos/fases/"+n+".json"))
  conferir(UI.fonte().get_string_size(str(dados.objetivo),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x<=452,"Objetivo cabe no HUD: "+n)
  conferir(UI.fonte().get_string_size(str(dados.nome),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x<=144,"Titulo cabe no HUD: "+n)
 conferir(gui.retratos.size()==2 and gui.retratos[0].region.size==Vector2(16,16),"Retratos possuem recorte de cabeca consistente")
 await create_timer(1.3).timeout
 fase.avisar("Mensagem nova: ação, proteção e cooperação para os dois heróis.",30)
 await create_timer(0.15).timeout
 conferir(gui.texto_aviso.visible and gui.texto_aviso.visible_characters>0 and gui.texto_aviso.visible_characters<gui.texto_aviso.text.length(),"Aviso revela o texto progressivamente")
 await create_timer(2.4).timeout
 conferir(gui.texto_aviso.visible_characters>=gui.texto_aviso.text.length(),"Revelacao mostra a mensagem completa")
 conferir(gui.texto_aviso.get_line_height()*gui.texto_aviso.get_line_count()<=gui.texto_aviso.size.y,"Aviso reserva altura para todas as linhas")
 await create_timer(3.0).timeout
 conferir(not gui.texto_aviso.visible and not gui.aviso_ativo,"Historia desaparece depois da escrita e leitura")
 conferir(not fase.mensagem.text.is_empty(),"Dica nao fica presa mesmo com origem ainda ativa")
 var cliques: int=int(audio.eventos.get("letra",0))
 await create_timer(0.3).timeout
 conferir(int(audio.eventos.get("letra",0))==cliques,"Som de digitacao para ao terminar")
 fase.avisar("História com ação e aventura para Lucas e Otto. ".repeat(16),0.1)
 await create_timer(0.3).timeout
 conferir(gui.paginas_aviso.size()>1 and gui.altura_aviso<=44,"Historia longa usa paginas pequenas de ate tres linhas")
 conferir(gui.aviso_ativo and gui.texto_aviso.visible and fase.mensagem.text.is_empty(),"Origem expirar nao corta o texto durante a escrita")
 fase.lucas.vida_atual=60
 await create_timer(0.8).timeout
 conferir(is_equal_approx(gui.vidas[0],60.0),"Barra animada converge para a vida real")
 await tecla(KEY_F1)
 conferir(gui.ajuda.visible and paused,"F1 abre guia e pausa")
 var letras_antes: float=gui.revelacao
 var pos: Vector2=fase.lucas.position
 Input.action_press("guerreiro_direita")
 await create_timer(0.15).timeout
 Input.action_release("guerreiro_direita")
 conferir(fase.lucas.position==pos,"Guia impede movimento sob o modal")
 conferir(gui.revelacao==letras_antes,"Pausa suspende tambem a escrita da historia")
 await tecla(KEY_F1)
 conferir(not gui.ajuda.visible and not paused,"F1 fecha guia e retoma")
 await tecla(KEY_ESCAPE)
 conferir(paused and gui.pausa.visible,"Esc abre pausa")
 gui.pausa.get_child(0).get_child(1).pressed.emit()
 conferir(not paused and not gui.pausa.visible,"Continuar retoma")
 var eventos: int=int(audio.eventos.get("objetivo",0))
 fase.sinais.cristal=true
 await create_timer(0.3).timeout
 conferir(gui.total_anterior==1 and int(audio.eventos.get("objetivo",0))>eventos,"Objetivo real atualiza contador e toca sinal")
 var indice: int=AudioServer.get_bus_index("Interface")
 conferir(indice>=0 and AudioServer.get_bus_send(indice)=="SFX","Sons da UI pertencem ao controle geral de efeitos")
 await tecla(KEY_M)
 conferir(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"M silencia tambem a interface")
 await tecla(KEY_M)
 conferir(not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"M restaura os efeitos")
 for id in audio.CLIPES:
  conferir(audio.CLIPES[id].instantiate_playback()!=null,"Clipe de interface decodificado: "+id)
 await tecla(KEY_ESCAPE)
 gui.pausa.get_child(0).get_child(3).pressed.emit()
 await create_timer(0.75).timeout
 conferir(not paused and current_scene.scene_file_path.ends_with("menu.tscn"),"Retorno ao menu conclui transicao e limpa pausa")
 current_scene.queue_free()
 await quadros()
 if falhas.is_empty():
  print("INTERFACE_OK: %d verificacoes de fonte, acentos, sons, entrada, HUD, avisos, guia, pausa e transicoes." % total)
  quit(0)
 else: quit(1)
func menu_font() -> Font: return UI.fonte()
