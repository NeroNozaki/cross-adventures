@tool
extends Node2D
@export_file("*.json") var arquivo_dados: String
const PEDRA: Texture2D=preload("res://assets/mapa/CRAFTPIX_DUNGEON/walls_floor.png")
const COSTA: Texture2D=preload("res://assets/mapa/CRAFTPIX_DUNGEON/Water_coasts_animation.png")
const ONDAS: Texture2D=preload("res://assets/mapa/CRAFTPIX_DUNGEON/water_details_animation.png")
const MATERIAL_AGUA: Shader=preload("res://scripts/visual/agua_profundidade.gdshader")
var dados: Dictionary={}
var agua: Dictionary={}
var pisos: Dictionary={}
var profundidades: Dictionary={}
var tempo: float=0.0
var superficie: Polygon2D
var assinatura: String=""
func _ready() -> void:
 if not FileAccess.file_exists(arquivo_dados): return
 dados=JSON.parse_string(FileAccess.get_file_as_string(arquivo_dados))
 for c in dados.chao: pisos[Vector2i(c[0],c[1])]=true
 for r in dados.agua:
  for y in range(r[1],r[1]+r[3]):
   for x in range(r[0],r[0]+r[2]):
    var c: Vector2i=Vector2i(x,y)
    if not pisos.has(c): agua[c]=true
 # Distância até a margem, interpolada pelo shader: sem faixas retangulares de cor.
 var fila: Array[Vector2i]=[]
 for c: Vector2i in agua:
  for v in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   if not agua.has(c+v):
    profundidades[c]=1
    fila.append(c)
    break
 var inicio: int=0
 while inicio<fila.size():
  var c: Vector2i=fila[inicio]
  inicio+=1
  for v in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   if agua.has(c+v) and not profundidades.has(c+v):
    profundidades[c+v]=int(profundidades[c])+1
    fila.append(c+v)
 var imagem: Image=Image.create(int(dados.largura)+2,int(dados.altura)+2,false,Image.FORMAT_RF)
 imagem.fill(Color.BLACK)
 for c: Vector2i in agua: imagem.set_pixel(c.x+1,c.y+1,Color(minf(float(profundidades[c])/8.0,1.0),0,0))
 var material_agua: ShaderMaterial=ShaderMaterial.new()
 material_agua.shader=MATERIAL_AGUA
 material_agua.set_shader_parameter("profundidade",ImageTexture.create_from_image(imagem))
 material_agua.set_shader_parameter("tamanho_grade",Vector2(imagem.get_width(),imagem.get_height()))
 superficie=Polygon2D.new()
 superficie.name="SuperficieComProfundidade"
 superficie.material=material_agua
 superficie.show_behind_parent=true
 add_child(superficie)
 _atualizar_superficie()
 if not Engine.is_editor_hint() and int(dados.get("numero",0))==1:
  var vida: Node2D=Node2D.new()
  vida.name="VidaNaAgua"
  vida.set_script(preload("res://scripts/visual/agua_viva.gd"))
  add_child(vida)
func ponte_em(c: Vector2i) -> bool:
 if Engine.is_editor_hint(): return false
 for p in dados.get("pontes",[]):
  if Rect2i(p[0],p[1],p[2],p[3]).has_point(c) and get_parent().ponte_pronta(str(p[5])): return true
 return false
func _atualizar_superficie() -> void:
 var vertices: PackedVector2Array=PackedVector2Array()
 var partes: Array[PackedInt32Array]=[]
 for c: Vector2i in agua:
  if ponte_em(c): continue
  var n: int=vertices.size()
  var p: Vector2=Vector2(c)*32.0
  vertices.append_array(PackedVector2Array([p,p+Vector2(32,0),p+Vector2(32,32),p+Vector2(0,32)]))
  partes.append(PackedInt32Array([n,n+1,n+2,n+3]))
 superficie.polygons=[]
 superficie.polygon=vertices
 superficie.polygons=partes
func _process(delta: float) -> void:
 if dados.is_empty(): return
 tempo+=delta
 var nova: String=""
 for p in dados.get("pontes",[]): nova+=str(ponte_em(Vector2i(p[0],p[1])))
 if nova!=assinatura:
  assinatura=nova
  _atualizar_superficie()
 queue_redraw()
func _draw() -> void:
 if dados.is_empty(): return
 var quadro: int=int(tempo/0.15)%6
 var margem_externa: Dictionary={}
 for c: Vector2i in agua:
  if ponte_em(c): continue
  var p: Vector2=Vector2(c)*32.0
  var r: Rect2=Rect2(p,Vector2(32,32))
  if int(profundidades.get(c,8))<3:
   draw_texture_rect_region(COSTA,r,Rect2((7+absi(c.x+c.y)%2)*16,480,16,16),Color(0.6,0.86,0.82,0.14))
  # Cada quadro original mede 592 x 208. Mantém ondas inteiras, sem cortar tiras aleatórias.
  var origem: Vector2=Vector2(posmod(c.x*16,592),quadro*208+posmod(c.y*16,208))
  draw_texture_rect_region(ONDAS,r,Rect2(origem,Vector2(16,16)),Color(0.7,0.95,0.94,0.26))
  for v: Vector2i in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var vizinho: Vector2i=c+v
   if agua.has(vizinho) or ponte_em(vizinho): continue
   if not pisos.has(vizinho): margem_externa[vizinho]=true
   # Sombra de contato e reflexo quebrado junto à alvenaria.
   var sombra: Color=Color(0.025,0.07,0.1,0.42)
   var espuma: Color=Color(0.36,0.68,0.68,0.14+sin(tempo*2+c.x+c.y)*0.05)
   var trecho: int=4+posmod(c.x*7+c.y*11,12)
   if v==Vector2i.UP:
    draw_texture_rect_region(COSTA,Rect2(p,Vector2(32,14)),Rect2(96+(14 if quadro%2==1 else 0)*16,64+int(quadro/2)*160,16,7))
    draw_rect(Rect2(p+Vector2(0,14),Vector2(32,6)),sombra)
    draw_rect(Rect2(p+Vector2(trecho,16),Vector2(10,2)),espuma)
   elif v==Vector2i.DOWN:
    draw_rect(Rect2(p+Vector2(0,26),Vector2(32,6)),sombra)
    draw_rect(Rect2(p+Vector2(trecho,28),Vector2(8,2)),espuma)
   elif v==Vector2i.LEFT:
    draw_rect(Rect2(p,Vector2(6,32)),sombra)
    draw_rect(Rect2(p+Vector2(4,trecho),Vector2(2,10)),espuma)
   else:
    draw_rect(Rect2(p+Vector2(26,0),Vector2(6,32)),sombra)
    draw_rect(Rect2(p+Vector2(26,trecho),Vector2(2,8)),espuma)
 # Capeamento em pedra onde o reservatório encontra o vazio: nada de água cortada no preto.
 for c: Vector2i in margem_externa:
  var p: Vector2=Vector2(c)*32.0
  draw_texture_rect_region(PEDRA,Rect2(p,Vector2(32,32)),Rect2(96,32,16,16),Color(0.77,0.84,0.91))
  draw_rect(Rect2(p+Vector2(2,2),Vector2(28,2)),Color(0.5,0.58,0.63,0.45))
