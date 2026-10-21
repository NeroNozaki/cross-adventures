extends Node2D
var tempo: float = 0.0
var duracao: float = 0.22
var cor: Color = Color("79eaff")
var som: AudioStream
var terminou_visual: bool = false

func _ready() -> void:
	if som != null:
		$Som.stream = som
		$Som.volume_db = -17.0
		$Som.pitch_scale = randf_range(0.96, 1.06)
		$Som.play()

func _process(delta: float) -> void:
	tempo += delta
	queue_redraw()
	if tempo >= duracao:
		terminou_visual = true
		if not $Som.playing:
			queue_free()

func _draw() -> void:
	if terminou_visual:
		return
	var p: float = clampf(tempo / duracao, 0.0, 1.0)
	draw_arc(Vector2.ZERO, 3.0 + 14.0 * p, 0, TAU, 20, Color(cor, 1.0 - p), 1.5, true)
	for i in range(6):
		var dir: Vector2 = Vector2.RIGHT.rotated(float(i) * TAU / 6.0)
		draw_line(dir * (3.0 + 8.0 * p), dir * (6.0 + 15.0 * p), Color(cor, 1.0 - p), 1.5)

func _exit_tree() -> void:
	$Som.stop()
	$Som.stream = null
