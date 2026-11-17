extends RefCounted
## Recortes conferidos no atlas real de 384×144, não em uma grade presumida.
const OBJETOS = preload("res://assets/mapa/CRAFTPIX_DUNGEON/Objects.png")
const COLUNA = preload("res://assets/Dungeon Gathering Free Version/Structure.png")
const CAMA = preload("res://assets/Ninja Adventure - Asset Pack/Backgrounds/Tilesets/tileset_bed.png")
const MOLDURA = preload("res://assets/Ninja Adventure - Asset Pack/Ui/Theme/Wip/ThemeMetal3/nine_path_panel.png")
const RECORTES := {
	"caixa": Rect2(80,80,16,24),
	"barril": Rect2(192,80,16,24),
	"urna": Rect2(208,80,16,24),
	"bau": Rect2(144,16,32,32),
	# Este ponto decorativo usa duas caixas completas empilhadas.
	"estante": Rect2(132,80,28,32),
	"coluna": Rect2(0,0,16,32),
	"cama": Rect2(0,144,32,48)
}

static func textura(tipo: String) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = CAMA if tipo == "cama" else (COLUNA if tipo == "coluna" else OBJETOS)
	atlas.region = RECORTES[tipo]
	atlas.filter_clip = true
	return atlas

static func aplicar(sprite: Sprite2D, tipo: String) -> void:
	sprite.texture = textura(tipo)
	var escala := 1.0 if tipo == "cama" else 1.5
	sprite.scale = Vector2.ONE * escala
	var imagem := sprite.texture.get_image()
	var visivel := imagem.get_used_rect()
	# Alinhar os pixels visíveis, não a margem transparente do atlas.
	sprite.position = (Vector2(imagem.get_size()) * 0.5 - Vector2(visivel.get_center().x, visivel.end.y)) * escala + Vector2(0,3)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func trava() -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = OBJETOS
	atlas.region = Rect2(144,112,16,16)
	atlas.filter_clip = true
	return atlas

static func parte_alavanca(base: bool) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = OBJETOS
	# A base ocupa as linhas 117..121; a haste fica nas linhas 112..116.
	atlas.region = Rect2(144,117 if base else 112,16,5)
	atlas.filter_clip = true
	return atlas

static func espelho() -> NinePatchRect:
	var painel := NinePatchRect.new()
	painel.name = "MolduraEspelho"
	painel.texture = MOLDURA
	painel.position = Vector2(-24,-5)
	painel.size = Vector2(48,10)
	painel.patch_margin_left = 4
	painel.patch_margin_right = 4
	painel.patch_margin_top = 4
	painel.patch_margin_bottom = 4
	painel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var reflexo := ColorRect.new()
	reflexo.name = "Superficie"
	reflexo.color = Color("a7dbe1")
	reflexo.position = Vector2(6,4)
	reflexo.size = Vector2(36,2)
	reflexo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.add_child(reflexo)
	return painel
