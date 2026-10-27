extends Control
const UI=preload("res://scripts/visual/tema_pixel.gd")
const DUNGEON=preload("res://assets/mapa/CRAFTPIX_DUNGEON/walls_floor.png")
var tempo: float=0.0
var piso: Texture2D=DUNGEON
var quadro: PanelContainer
var inicio: Button
var botoes: VBoxContainer
var herois: Array[CharacterBody2D]=[]
func _ready() -> void:
 theme=UI.tema()
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 for i in range(2):
  var ator: CharacterBody2D=load("res://cenas/personagens/"+("guerreiro" if i==0 else "robo")+".tscn").instantiate()
  ator.position=Vector2(424+i*88,236)
  add_child(ator)
  ator.set_physics_process(false)
  ator.barra_vida.hide()
  ator.nome_label.hide()
  if ator.has_node("Mira360"): ator.get_node("Mira360").hide()
  herois.append(ator)
 botoes=VBoxContainer.new()
 botoes.position=Vector2(42,210)
 botoes.size=Vector2(232,122)
 botoes.add_theme_constant_override("separation",9)
 add_child(botoes)
 inicio=UI.botao(botoes,"INICIAR AVENTURA",func(): get_node("/root/FluxoTela").trocar("res://cenas/fases/01_jardim.tscn"))
 UI.botao(botoes,"CONTROLES",alternar_controles)
 UI.botao(botoes,"SAIR",func(): get_tree().quit())
 quadro=PanelContainer.new()
 quadro.position=Vector2(64,66)
 quadro.size=Vector2(512,254)
 add_child(quadro)
 UI.guia(quadro,true)
 quadro.hide()
 inicio.grab_focus()
func alternar_controles() -> void:
 quadro.visible=not quadro.visible
 UI.som(self,"abrir" if quadro.visible else "fechar")
func _unhandled_input(e: InputEvent) -> void:
 if e is InputEventKey and e.pressed and e.physical_keycode==KEY_ESCAPE and quadro.visible:
  alternar_controles()
  get_viewport().set_input_as_handled()
func _process(delta: float) -> void:
 tempo+=delta
 botoes.position.y=210+roundi(18*(1.0-smoothstep(0.12,0.48,tempo)))
 for ator in herois: ator.modulate.a=smoothstep(0.1,0.5,tempo)
 queue_redraw()
func escrever(t: String,p: Vector2,tamanho: int,cor: Color=UI.CLARO) -> void:
 UI.escrever(self,t,p,tamanho,cor)
func _draw() -> void:
 draw_rect(Rect2(0,0,640,400),Color("111c2b"))
 for y in range(13):
  for x in range(21):
   var pos: Vector2=Vector2(x*32,y*32)
   draw_texture_rect_region(DUNGEON,Rect2(pos,Vector2(32,32)),Rect2(32,128,16,16),Color("475468"))
 for x in range(21):
  draw_texture_rect_region(DUNGEON,Rect2(x*32,0,32,32),Rect2(96,32,16,16))
  draw_texture_rect_region(DUNGEON,Rect2(x*32,368,32,32),Rect2(96,32,16,16))
 draw_rect(Rect2(0,32,640,336),Color(0.035,0.055,0.09,0.35))
 UI.painel(self,Rect2(24,50,268,296))
 draw_rect(Rect2(36,62,2,25),UI.OURO)
 escrever("UMA AVENTURA COOPERATIVA",Vector2(46,78),8,UI.OURO)
 escrever("CROSS",Vector2(40,120),40)
 escrever("ADVENTURES",Vector2(42,154),24,UI.OURO)
 draw_rect(Rect2(44,169,226,2),Color("526075"))
 escrever("A PROVAÇÃO DO HERÓI",Vector2(44,192),16,UI.SUAVE)
 UI.painel(self,Rect2(340,166,260,102))
 draw_rect(Rect2(352,176,236,78),Color("233447"))
 for i in range(2):
  var x: int=424+i*88
  draw_rect(Rect2(x-19,236,38,4),Color("14212e"))
  UI.painel(self,Rect2(x-30,270,60,23))
  UI.centro(self,"LUCAS" if i==0 else "OTTO",x-30,286,60,8,UI.OURO if i==0 else Color("8bd8d9"))
 UI.centro(self,"DOIS HERÓIS. UMA EQUIPE.",336,318,268,16)
 for i in range(4):
  var p: Vector2=Vector2(410+i*38,340)
  if i<3: draw_rect(Rect2(p+Vector2(8,3),Vector2(30,2)),Color("526075"))
  draw_rect(Rect2(p,Vector2(8,8)),UI.OURO if i==0 else Color("526075"))
  draw_rect(Rect2(p+Vector2(2,2),Vector2(4,4)),UI.CLARO)
 escrever("4 FASES  /  COMBATE  /  PUZZLES",Vector2(352,364),8,UI.SUAVE)
 for i in range(18):
  var p: Vector2=Vector2(floorf(fmod(i*131+tempo*3,640)/2)*2,floorf(fmod(i*73-tempo*7+800,400)/2)*2)
  draw_rect(Rect2(p,Vector2(2,2)),Color(0.8,0.72,0.5,0.18))
