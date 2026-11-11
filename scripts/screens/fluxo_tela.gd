extends CanvasLayer
var em_transicao: bool=false
var progresso: float=0.0
var cortina: Control
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 layer=100
 cortina=Control.new()
 cortina.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 cortina.mouse_filter=Control.MOUSE_FILTER_STOP
 cortina.draw.connect(_desenhar)
 add_child(cortina)
 cortina.hide()
func _input(_event: InputEvent) -> void:
 if em_transicao: get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
 if em_transicao: cortina.queue_redraw()
func _desenhar() -> void:
 for x in range(20):
  var h: float=ceilf(clampf(progresso*1.35-float(x)*0.018,0.0,1.0)*25.0)*16
  cortina.draw_rect(Rect2(x*32,0,32,h),Color("111b2b"))
  if h>0 and h<400: cortina.draw_rect(Rect2(x*32,h-2,32,2),Color("586578"))
func trocar(caminho: String) -> void:
 if em_transicao: return
 em_transicao=true
 cortina.show()
 get_tree().paused=true
 var t: Tween=create_tween()
 t.tween_property(self,"progresso",1.0,0.24)
 await t.finished
 get_tree().change_scene_to_file(caminho)
 await get_tree().process_frame
 await get_tree().create_timer(0.06).timeout
 t=create_tween()
 t.tween_property(self,"progresso",0.0,0.28)
 await t.finished
 cortina.hide()
 em_transicao=false
 get_tree().paused=false
