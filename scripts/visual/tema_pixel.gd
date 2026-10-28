extends RefCounted
const FONTE=preload("res://assets/INTERFACE/FONTES/TINY5/Tiny5.ttf")
const QUADRO=preload("res://recursos/visual/quadro_pixel.svg")
const ICONES=preload("res://assets/mapa/Dungeon assets pack/Dungeon assets pack/Others/HUD.png")
const CLARO=Color("f0e5ca")
const OURO=Color("d9b875")
const SUAVE=Color("a7b4c6")
static var fonte_cache: FontFile
static func fonte() -> FontFile:
 if fonte_cache==null:
  fonte_cache=FONTE.duplicate()
  fonte_cache.antialiasing=TextServer.FONT_ANTIALIASING_NONE
  fonte_cache.hinting=TextServer.HINTING_NONE
  fonte_cache.subpixel_positioning=TextServer.SUBPIXEL_POSITIONING_DISABLED
  fonte_cache.oversampling=1.0
 return fonte_cache
static func moldura(cor: Color=Color.WHITE,margem: int=12) -> StyleBoxTexture:
 var s: StyleBoxTexture=StyleBoxTexture.new()
 s.texture=QUADRO
 for lado in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
  s.set_texture_margin(lado,6)
  s.set_content_margin(lado,margem)
 s.modulate_color=cor
 return s
static func tema() -> Theme:
 var t: Theme=Theme.new()
 t.default_font=fonte()
 t.default_font_size=16
 t.set_color("font_color","Label",CLARO)
 t.set_color("font_shadow_color","Label",Color("111b2b"))
 t.set_constant("shadow_offset_y","Label",1)
 t.set_stylebox("panel","PanelContainer",moldura())
 for estado in ["normal","hover","pressed","focus","disabled"]:
  var cor: Color=Color.WHITE
  if estado=="hover": cor=Color(1.23,1.2,1.03)
  if estado=="pressed": cor=Color(0.74,0.83,0.88)
  if estado=="disabled": cor=Color(0.55,0.58,0.67)
  var s: StyleBox=moldura(cor,8)
  if estado=="focus":
   var foco: StyleBoxFlat=StyleBoxFlat.new()
   foco.bg_color=Color.TRANSPARENT
   foco.border_color=OURO
   foco.set_border_width_all(1)
   foco.set_content_margin_all(8)
   s=foco
  t.set_stylebox(estado,"Button",s)
 t.set_font_size("font_size","Button",16)
 t.set_color("font_color","Button",CLARO)
 t.set_color("font_hover_color","Button",Color.WHITE)
 t.set_color("font_focus_color","Button",OURO)
 return t
static func escrever(no: CanvasItem,t: String,p: Vector2,tamanho: int=12,cor: Color=CLARO) -> void:
 p=p.round()
 no.draw_string(fonte(),p+Vector2(0,1),t,HORIZONTAL_ALIGNMENT_LEFT,-1,tamanho,Color("111827"))
 no.draw_string(fonte(),p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,tamanho,cor)
static func centro(no: CanvasItem,t: String,x: float,y: float,largura: float,tamanho: int,cor: Color=CLARO) -> void:
 var w: float=fonte().get_string_size(t,HORIZONTAL_ALIGNMENT_LEFT,-1,tamanho).x
 escrever(no,t,Vector2(x+(largura-w)/2,y),tamanho,cor)
static func painel(no: CanvasItem,r: Rect2,cor: Color=Color.WHITE) -> void:
 no.draw_rect(Rect2(r.position+Vector2(0,3),r.size),Color(0.025,0.035,0.07,0.55*cor.a))
 no.draw_style_box(moldura(cor),r)
static func som(no: Node,id: String) -> void:
 var audio: Node=no.get_node_or_null("/root/InterfaceAudio")
 if audio!=null: audio.tocar(id)
static func botao(pai: Node,t: String,acao: Callable) -> Button:
 var b: Button=Button.new()
 b.text=t
 b.custom_minimum_size.y=32
 b.mouse_entered.connect(func(): som(b,"mover"))
 b.focus_entered.connect(func(): som(b,"mover"))
 b.pressed.connect(func(): som(b,"confirmar"); acao.call())
 pai.add_child(b)
 return b

static func guia(pai: Node,menu: bool=false) -> void:
 var coluna: VBoxContainer=VBoxContainer.new()
 coluna.add_theme_constant_override("separation",12)
 pai.add_child(coluna)
 var titulo: Label=Label.new()
 titulo.text="GUIA DA EQUIPE"
 titulo.add_theme_font_size_override("font_size",16)
 coluna.add_child(titulo)
 var dupla: HBoxContainer=HBoxContainer.new()
 dupla.add_theme_constant_override("separation",24)
 coluna.add_child(dupla)
 var textos: Array[Array]=[
 ["LUCAS","W A S D","Move o guerreiro","ESPAÇO / J / CLIQUE DIREITO","Combo de 3 golpes","SHIFT: ESCUDO    F: SALTO","E: INTERAGIR / EMPURRAR"],
 ["OTTO","SETAS + MOUSE","Mover e mirar","ESQUERDO / ENTER: SEGURE","Tiro e carga","P: SALTO    I: INTERAGIR","C: ELEMENTO   TAB: TRAVAR"]]
 for i in range(2):
  var bloco: VBoxContainer=VBoxContainer.new()
  bloco.custom_minimum_size.x=226
  bloco.add_theme_constant_override("separation",6)
  dupla.add_child(bloco)
  for j in range(textos[i].size()):
   var l: Label=Label.new()
   l.text=textos[i][j]
   l.add_theme_font_size_override("font_size",16 if j in [0,2,4] else 8)
   if j==0: l.add_theme_color_override("font_color",OURO if i==0 else Color("8bd8d9"))
   bloco.add_child(l)
 var dica: Label=Label.new()
 dica.text="Escadas mudam a altura. Salte para o mesmo nível."
 dica.add_theme_font_size_override("font_size",16)
 coluna.add_child(dica)
 var rodape: Label=Label.new()
 rodape.text="V: MAPA    M: EFEITOS    R: REINICIAR    "+("CONTROLES / ESC: FECHAR" if menu else "F1 / ESC: FECHAR")
 rodape.add_theme_font_size_override("font_size",8)
 coluna.add_child(rodape)
