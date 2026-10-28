extends Node
const BASE="res://assets/SONS/INTERFACE/"
const CLIPES={
 "mover":preload(BASE+"SELECAO/KENNEY_INTERFACE_SOUNDS/select_001.ogg"),
 "confirmar":preload(BASE+"CONFIRMACAO/KENNEY_INTERFACE_SOUNDS/confirmation_001.ogg"),
 "abrir":preload(BASE+"ABRIR_FECHAR/KENNEY_INTERFACE_SOUNDS/open_001.ogg"),
 "fechar":preload(BASE+"ABRIR_FECHAR/KENNEY_INTERFACE_SOUNDS/close_001.ogg"),
 "aviso":preload(BASE+"OUTROS/KENNEY_INTERFACE_SOUNDS/pluck_001.ogg"),
 "objetivo":preload(BASE+"CONFIRMACAO/KENNEY_INTERFACE_SOUNDS/confirmation_002.ogg"),
 "letra":preload(BASE+"OUTROS/KENNEY_INTERFACE_SOUNDS/tick_001.ogg")}
var canais: Array[AudioStreamPlayer]=[]
var amostras: Dictionary={}
var ultimo: Dictionary={}
var eventos: Dictionary={}
func _ready() -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 # Decodifica clipes curtos uma vez; os canais da interface usam PCM em memória.
 for id in CLIPES:
  var leitor: AudioStreamPlayback=CLIPES[id].instantiate_playback()
  leitor.start()
  var frames: PackedVector2Array=leitor.mix_audio(1.0,ceili(CLIPES[id].get_length()*AudioServer.get_mix_rate()))
  leitor.stop()
  var dados: PackedByteArray=PackedByteArray()
  dados.resize(frames.size()*2)
  for i in range(frames.size()): dados.encode_s16(i*2,clampi(roundi((frames[i].x+frames[i].y)*0.5*32767.0),-32768,32767))
  var amostra: AudioStreamWAV=AudioStreamWAV.new()
  amostra.format=AudioStreamWAV.FORMAT_16_BITS
  amostra.mix_rate=int(AudioServer.get_mix_rate())
  amostra.stereo=false
  amostra.data=dados
  amostras[id]=amostra
 if AudioServer.get_bus_index("Interface")<0:
  AudioServer.add_bus()
  var i: int=AudioServer.bus_count-1
  AudioServer.set_bus_name(i,"Interface")
  AudioServer.set_bus_send(i,"SFX")
 for i in range(4):
  var p: AudioStreamPlayer=AudioStreamPlayer.new()
  p.bus="Interface"
  add_child(p)
  canais.append(p)
func tocar(id: String) -> void:
 if not CLIPES.has(id): return
 var agora: int=Time.get_ticks_msec()
 var intervalo: int=90 if id in ["letra","mover"] else 180
 if agora-int(ultimo.get(id,-1000))<intervalo: return
 ultimo[id]=agora
 eventos[id]=int(eventos.get(id,0))+1
 var p: AudioStreamPlayer=canais[0]
 for canal in canais:
  if not canal.playing:
   p=canal
   break
 p.stream=amostras[id]
 p.volume_db=-29 if id=="letra" else (-21 if id=="mover" else -14)
 p.pitch_scale=1.12 if id=="letra" else 1.0
 p.play()

func parar() -> void:
 for canal in canais:
  canal.stop()
  canal.stream=null
func _exit_tree() -> void:
 parar()
