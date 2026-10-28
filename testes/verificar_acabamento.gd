extends SceneTree
var falhas: Array[String]=[]
var total: int=0
func _initialize() -> void: call_deferred("rodar")
func conferir(ok: bool,t: String) -> void:
 total+=1
 if not ok:
  falhas.append(t)
  push_error(t)
func rodar() -> void:
 AudioServer.set_bus_mute(0,true)
 for nome in ["01_jardim","02_galeria","03_oficina","04_santuario"]:
  var f: Node2D=load("res://cenas/fases/"+nome+".tscn").instantiate()
  root.add_child(f)
  current_scene=f
  await process_frame
  for ator in f.atores: ator.set_physics_process(false)
  f.set_physics_process(false)
  var agua: Node2D=f.get_node("CanaisDeAgua")
  conferir(not agua.agua.is_empty(),nome+": reservatorio existe")
  var sobreposto: bool=false
  var maior: int=0
  for c: Vector2i in agua.agua:
   sobreposto=sobreposto or f.grade.has(c)
   maior=maxi(maior,int(agua.profundidades[c]))
  conferir(not sobreposto,nome+": agua recortada pelo chao real")
  conferir(maior>1,nome+": perfil de profundidade tem margem e centro")
  conferir(agua.superficie.polygon.size()==agua.agua.size()*4,nome+": superficie cobre somente agua")
  conferir(agua.superficie.material.get_shader_parameter("profundidade").get_width()==int(f.dados.largura)+2,nome+": campo de profundidade corresponde ao mapa")
  for decor in f.get_node("ArquiteturaEDecoracao").get_children():
   if not decor.has_meta("celula"): continue
   var c: Vector2i=decor.get_meta("celula")
   var livre: bool=true
   for obj in f.dados.objetos:
    if Vector2(c).distance_to(Vector2(obj.x,obj.y))<2.0: livre=false
   conferir(livre,nome+": decoracao separada de itens interativos "+str(decor.name))
   conferir(decor.scale==Vector2(2,2),nome+": pixels com escala inteira "+str(decor.name))
   var tex: AtlasTexture=decor.texture
   conferir(Rect2(Vector2.ZERO,tex.atlas.get_size()).encloses(tex.region),nome+": recorte dentro do atlas "+str(decor.name))
  for obj in f.get_node("Objetos").get_children():
   if obj.tipo() in ["barril","caixa"]:
    var tex: AtlasTexture=obj.get_node("Sprite").texture
    var esperado: Rect2=Rect2(192,80,16,16) if obj.tipo()=="barril" else Rect2(80,80,16,16)
    conferir(tex.region==esperado and obj.get_node("Sprite").scale==Vector2(2,2),nome+": sprite inteiro e escala correta "+str(obj.name))
  if nome=="01_jardim":
   var antes: int=agua.superficie.polygon.size()
   f.sinais.ponte=true
   await create_timer(2.0).timeout
   await process_frame
   await process_frame
   conferir(agua.superficie.polygon.size()==antes-24,"Agua deixa de cobrir as seis celulas da ponte aberta")
   f.sinais.ponte=false
   await process_frame
   await process_frame
   conferir(agua.superficie.polygon.size()==antes,"Reiniciar o mecanismo restaura a superficie")
  f.queue_free()
  await process_frame
 if falhas.is_empty():
  print("ACABAMENTO_OK: %d verificacoes de agua, profundidade, ponte, recortes, escala e separacao dos itens." % total)
  quit(0)
 else: quit(1)
