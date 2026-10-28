extends Control
const UI=preload("res://scripts/visual/tema_pixel.gd")
const ELEMENTOS={"normal":Color("82d4db"),"fogo":Color("f5a46c"),"gelo":Color("a7e5ed"),"choque":Color("c2a4eb"),"onda":Color("8dce9e")}
var fase: Node2D
var estado_debug: Label
var mensagem: Label
var texto_aviso: Label
var ajuda: PanelContainer
var pausa: PanelContainer
var tempo: float=0.0
var retratos: Array[AtlasTexture]=[]
var vidas: Array[float]=[]
var ultima_mensagem: String=""
var revelacao: float=0.0
var altura_aviso: int=34
var paginas_aviso: Array[String]=[]
var pagina_aviso: int=0
var espera_letra: float=0.0
var leitura: float=0.0
var alpha_aviso: float=0.0
var escrevendo: bool=false
var aviso_ativo: bool=false
var total_anterior: int=0
var elemento_anterior: String="normal"
var etapa_final: bool=false
var flash_objetivo: float=0.0
var teclas_guia: Button
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 theme=UI.tema()
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 estado_debug=Label.new()
 add_child(estado_debug)
 estado_debug.hide()
 mensagem=Label.new()
 mensagem.name="EntradaMensagens"
 mensagem.hide()
 add_child(mensagem)
 texto_aviso=Label.new()
 texto_aviso.name="HistoriaDigitada"
 texto_aviso.size=Vector2(368,30)
 texto_aviso.autowrap_mode=TextServer.AUTOWRAP_OFF
 texto_aviso.add_theme_font_size_override("font_size",8)
 texto_aviso.add_theme_constant_override("line_spacing",1)
 texto_aviso.mouse_filter=Control.MOUSE_FILTER_IGNORE
 texto_aviso.hide()
 add_child(texto_aviso)
 ajuda=painel(Vector2(64,66),Vector2(512,254))
 ajuda.name="Guia"
 UI.guia(ajuda)
 ajuda.hide()
 pausa=painel(Vector2(194,94),Vector2(252,214))
 pausa.name="Pausa"
 var coluna: VBoxContainer=VBoxContainer.new()
 coluna.add_theme_constant_override("separation",10)
 pausa.add_child(coluna)
 var titulo: Label=Label.new()
 titulo.text="AVENTURA EM PAUSA"
 titulo.add_theme_font_size_override("font_size",16)
 coluna.add_child(titulo)
 UI.botao(coluna,"CONTINUAR",alternar_pausa)
 UI.botao(coluna,"REINICIAR SALA",func(): navegar(get_tree().current_scene.scene_file_path))
 UI.botao(coluna,"MENU PRINCIPAL",func(): navegar("res://cenas/interface/menu.tscn"))
 pausa.hide()
 teclas_guia=UI.botao(self,"F1  GUIA",alternar_ajuda)
 teclas_guia.position=Vector2(580,374)
 teclas_guia.custom_minimum_size=Vector2(52,18)
 teclas_guia.size=Vector2(52,18)
 teclas_guia.add_theme_font_size_override("font_size",8)
 for estado in ["normal","hover","pressed","focus"]:
  teclas_guia.add_theme_stylebox_override(estado,UI.moldura(Color(1.15,1.12,0.95) if estado in ["hover","focus"] else Color.WHITE,3))
 teclas_guia.size=Vector2(52,18)
 if is_instance_valid(fase):
  for ator in [fase.lucas,fase.otto]:
   var tex: Texture2D=ator.animacao.sprite_frames.get_frame_texture("idle_down",0)
   var usado: Rect2i=tex.get_image().get_used_rect()
   var retrato: AtlasTexture=AtlasTexture.new()
   retrato.atlas=tex
   retrato.region=Rect2(usado.position.x+maxi(0,(usado.size.x-16)/2),usado.position.y,16,16)
   retratos.append(retrato)
   vidas.append(float(ator.vida_atual))
func painel(p: Vector2,s: Vector2) -> PanelContainer:
 var n: PanelContainer=PanelContainer.new()
 n.position=p
 n.size=s
 add_child(n)
 return n
func navegar(p: String) -> void:
 get_node("/root/FluxoTela").trocar(p)
func alternar_ajuda() -> void:
 if pausa.visible: return
 ajuda.visible=not ajuda.visible
 get_tree().paused=ajuda.visible
 UI.som(self,"abrir" if ajuda.visible else "fechar")
 if ajuda.visible: entrada_modal(ajuda)
func alternar_pausa() -> void:
 if ajuda.visible:
  ajuda.hide()
  get_tree().paused=false
  UI.som(self,"fechar")
  return
 pausa.visible=not pausa.visible
 get_tree().paused=pausa.visible
 UI.som(self,"abrir" if pausa.visible else "fechar")
 if pausa.visible:
  entrada_modal(pausa)
  pausa.get_child(0).get_child(1).grab_focus()
func entrada_modal(no: Control) -> void:
 no.modulate.a=0.0
 var t: Tween=create_tween()
 t.tween_property(no,"modulate:a",1.0,0.12)
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode==KEY_ESCAPE:
   alternar_pausa()
   get_viewport().set_input_as_handled()
  elif event.physical_keycode==KEY_F1:
   alternar_ajuda()
   get_viewport().set_input_as_handled()
func objetivos_feitos() -> int:
 var total: int=0
 for id in fase.dados.get("objetivos",[]):
  if fase.sinais.get(str(id),false): total+=1
 return total
func _process(delta: float) -> void:
 tempo+=delta
 if not is_instance_valid(fase): return
 var modal: bool=ajuda.visible or pausa.visible
 atualizar_aviso(delta,modal)
 for i in range(2):
  var heroi: Node2D=fase.lucas if i==0 else fase.otto
  heroi.nome_label.hide()
  heroi.barra_vida.hide()
  vidas[i]=move_toward(vidas[i],float(heroi.vida_atual),delta*90.0)
 for ator in fase.atores:
  if ator.equipe==1 and not ator.esta_morto: ator.nome_label.visible=ator.vida_atual<ator.vida_maxima
 var feitos: int=objetivos_feitos()
 if feitos>total_anterior:
  flash_objetivo=0.8
  UI.som(self,"objetivo")
 total_anterior=feitos
 flash_objetivo=maxf(0.0,flash_objetivo-delta)
 if fase.otto.elemento!=elemento_anterior:
  elemento_anterior=fase.otto.elemento
  UI.som(self,"mover")
 if fase.concluida and not etapa_final:
  etapa_final=true
  UI.som(self,"objetivo")
 teclas_guia.position.y=374+roundi(26*(1.0-smoothstep(0.08,0.42,tempo)))
 queue_redraw()
func texto(t: String,p: Vector2,tamanho: int=12,cor: Color=UI.CLARO) -> void:
 UI.escrever(self,t,p,tamanho,cor)
func linhas(t: String,largura: float,tamanho: int) -> Array[String]:
 var resultado: Array[String]=[]
 for paragrafo in t.replace("\r","").split("\n"):
  var linha: String=""
  for palavra in paragrafo.split(" ",false):
   var nova: String=palavra if linha.is_empty() else linha+" "+palavra
   if not linha.is_empty() and UI.fonte().get_string_size(nova,HORIZONTAL_ALIGNMENT_LEFT,-1,tamanho).x>largura:
    resultado.append(linha)
    linha=palavra
   else: linha=nova
  if not linha.is_empty(): resultado.append(linha)
 return resultado

func _draw() -> void:
 if not is_instance_valid(fase) or fase.dados.is_empty(): return
 draw_set_transform(Vector2(0,-roundi(48*(1.0-smoothstep(0.0,0.32,tempo)))))
 for i in range(2):
  var ator: Node2D=fase.lucas if i==0 else fase.otto
  var x: int=8+i*130
  var cor: Color=Color("e6b36b") if i==0 else Color("7dd0d4")
  UI.painel(self,Rect2(x,8,122,36))
  draw_rect(Rect2(x+5,13,1,24),cor)
  draw_rect(Rect2(x+10,17,16,16),Color("172333"))
  if retratos.size()>i: draw_texture_rect(retratos[i],Rect2(x+10,17,16,16),false)
  texto("LUCAS" if i==0 else "OTTO",Vector2(x+32,20),8,cor)
  texto(str(ator.vida_atual)+"/"+str(ator.vida_maxima),Vector2(x+81,20),8,UI.SUAVE)
  draw_rect(Rect2(x+32,24,82,5),Color("101a27"))
  draw_rect(Rect2(x+33,25,roundi(80*vidas[i]/ator.vida_maxima),3),Color("965f59"))
  var w: int=roundi(80.0*ator.vida_atual/ator.vida_maxima)
  draw_rect(Rect2(x+33,25,w,3),cor.darkened(0.25))
  draw_rect(Rect2(x+33,25,w,1),cor.lightened(0.2))
  for corte in range(1,8): draw_rect(Rect2(x+33+corte*10,25,1,3),Color(0.04,0.08,0.12,0.25))
  var estado: String="ESPADA + ESCUDO" if i==0 else ator.elemento.to_upper()
  if ator.esta_morto: estado="RECUPERANDO..."
  elif i==0 and ator.defendendo: estado="ESCUDO ERGUIDO"
  elif i==0 and ator.restante_combo>0: estado="COMBO "+str(ator.passo_combo)+"/3"
  elif i==1 and ator.carregando: estado="CARGA "+str(roundi(100*ator.tempo_carga/ator.tempo_carga_total))+"%"
  texto(estado,Vector2(x+32,38),8,ELEMENTOS.get(fase.otto.elemento,cor) if i==1 else UI.SUAVE)
 UI.painel(self,Rect2(468,8,164,36))
 texto("PROVAÇÃO "+str(int(fase.dados.numero))+" / 4",Vector2(478,21),8,UI.OURO)
 texto(str(fase.dados.nome),Vector2(478,34),8)
 draw_set_transform(Vector2(0,roundi(30*(1.0-smoothstep(0.08,0.36,tempo)))))
 var largura: float=largura_objetivo()
 UI.painel(self,Rect2(8,368,largura,24),Color(1.12,1.05,0.86) if flash_objetivo>0 else Color.WHITE)
 draw_texture_rect_region(UI.ICONES,Rect2(14,372,16,16),Rect2(0,0,16,16))
 texto(str(fase.dados.objetivo),Vector2(36,384),8)
 texto(str(objetivos_feitos())+"/"+str(fase.dados.get("objetivos",[]).size()),Vector2(largura-18,384),8,Color("9fd5bb"))
 draw_set_transform(Vector2.ZERO)
 if texto_aviso.visible:
  UI.painel(self,Rect2(128,360-altura_aviso,384,altura_aviso),Color(1,1,1,alpha_aviso))
  if escrevendo and int(tempo*3)%2==0:
   draw_rect(Rect2(502,352,2,3),Color(0.85,0.72,0.46,alpha_aviso))
 if fase.concluida:
  draw_rect(Rect2(0,60,640,278),Color(0.035,0.055,0.1,0.88))
  UI.painel(self,Rect2(114,110,412,180))
  UI.centro(self,"PROVAÇÃO CONCLUÍDA",114,148,412,24,UI.OURO)
  UI.centro(self,"A Medalha da Equipe é de vocês.",114,184,412,16)
  UI.centro(self,"Lucas e Otto venceram juntos.",114,212,412,16,Color("9fd5bb"))
  UI.centro(self,"R  JOGAR NOVAMENTE     ESC  PAUSA",114,264,412,8)
 elif ajuda.visible or pausa.visible:
  draw_rect(Rect2(0,60,640,278),Color(0.025,0.04,0.08,0.78))

func largura_objetivo() -> float:
 return clampf(UI.fonte().get_string_size(str(fase.dados.objetivo),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x+86,280,540)

func iniciar_aviso(t: String) -> void:
 paginas_aviso.clear()
 var partes: Array[String]=linhas(t,368,8)
 for i in range(0,partes.size(),3):
  var pagina: String=""
  for j in range(i,mini(i+3,partes.size())):
   if not pagina.is_empty(): pagina+="\n"
   pagina+=partes[j]
  paginas_aviso.append(pagina)
 if paginas_aviso.is_empty(): return
 pagina_aviso=0
 aviso_ativo=true
 alpha_aviso=0.0
 iniciar_pagina()
 UI.som(self,"aviso")

func iniciar_pagina() -> void:
 texto_aviso.text=paginas_aviso[pagina_aviso]
 texto_aviso.visible_characters=0
 revelacao=0.0
 espera_letra=0.0
 leitura=0.0
 escrevendo=true
 altura_aviso=14+mini(texto_aviso.text.split("\n").size(),3)*10
 texto_aviso.position=Vector2(136,367-altura_aviso)
 texto_aviso.size=Vector2(368,altura_aviso-14)

func atualizar_aviso(delta: float,modal: bool) -> void:
 # A fase fornece o texto; a apresentação guarda sua cópia até terminar a leitura.
 if mensagem.text!=ultima_mensagem:
  ultima_mensagem=mensagem.text
  if not ultima_mensagem.is_empty() and not fase.concluida: iniciar_aviso(ultima_mensagem)
 if fase.concluida:
  aviso_ativo=false
  alpha_aviso=0.0
 if not modal and not get_tree().paused and tempo>0.45:
  if aviso_ativo:
   alpha_aviso=move_toward(alpha_aviso,1.0,delta*8.0)
   if escrevendo:
    espera_letra-=delta
    while espera_letra<=0.0 and revelacao<texto_aviso.text.length():
     var letra: String=texto_aviso.text[int(revelacao)]
     revelacao+=1.0
     espera_letra+=0.028
     if letra in [".","!","?"]: espera_letra+=0.15
     elif letra in [",",";",":"]: espera_letra+=0.07
     elif letra.strip_edges()!="" and int(revelacao)%3==0: UI.som(self,"letra")
    texto_aviso.visible_characters=int(revelacao)
    if revelacao>=texto_aviso.text.length():
     escrevendo=false
     leitura=2.4
   else:
    leitura-=delta
    if leitura<=0.0:
     if pagina_aviso+1<paginas_aviso.size():
      pagina_aviso+=1
      iniciar_pagina()
     else: aviso_ativo=false
  else: alpha_aviso=move_toward(alpha_aviso,0.0,delta*5.0)
 texto_aviso.modulate.a=alpha_aviso
 texto_aviso.visible=not modal and not fase.concluida and tempo>0.45 and alpha_aviso>0.01
