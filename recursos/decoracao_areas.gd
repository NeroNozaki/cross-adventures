extends RefCounted
## Posições da campanha em células do TileMap.
## Nas entradas Vector3i, z é a face do apoio: 0 norte, 1 leste, 2 sul e 3 oeste.
## As três listas de cada grupo seguem a ordem das cenas area_1, area_2 e area_3.

const ARANDELAS := [
	# Entre celas, nas duas bocas do corredor e junto à saída.
	[Vector3i(18, 24, 0), Vector3i(25, 22, 3), Vector3i(8, 18, 2), Vector3i(4, 13, 3),
	 Vector3i(8, 7, 0), Vector3i(15, 7, 0), Vector3i(26, 5, 0), Vector3i(30, 16, 3),
	 Vector3i(17, 12, 0), Vector3i(18, -15, 1), Vector3i(18, -10, 1), Vector3i(23, -24, 3),
	 Vector3i(18, 0, 1), Vector3i(23, 0, 3), Vector3i(24, 18, 2)],
	# Balizas nas margens úteis da galeria e na chegada das plataformas.
	[Vector3i(2, 24, 0), Vector3i(11, 24, 0), Vector3i(35, 24, 0), Vector3i(39, 22, 3),
	 Vector3i(39, 12, 3), Vector3i(0, 2, 1), Vector3i(4, 0, 2), Vector3i(12, 0, 2),
	 Vector3i(27, 0, 2), Vector3i(36, 0, 2), Vector3i(5, -24, 2), Vector3i(31, -24, 2)],
	# Salões e linha de paredes que leva aos degraus da saída.
	[Vector3i(6, 24, 0), Vector3i(22, 24, 0), Vector3i(28, 21, 3), Vector3i(35, 18, 3),
	 Vector3i(16, 5, 3), Vector3i(0, 8, 1), Vector3i(10, 0, 2), Vector3i(28, 8, 2),
	 Vector3i(0, -10, 1), Vector3i(8, -11, 2), Vector3i(18, -24, 2), Vector3i(30, -24, 2),
	 Vector3i(39, -17, 3), Vector3i(39, -8, 3)]
]
const NICHOS := [
	[Vector3i(4, 5, 3), Vector3i(13, 18, 2), Vector3i(1, -14, 1), Vector3i(22, -24, 2)],
	[Vector3i(39, 6, 3), Vector3i(8, 0, 2), Vector3i(33, -24, 2)],
	[Vector3i(16, 12, 3), Vector3i(1, 24, 0), Vector3i(28, 12, 1), Vector3i(17, -24, 2)]
]
const SELOS := [
	[Vector2i(21, 22), Vector2i(16, 5), Vector2i(28, 9), Vector2i(21, -2), Vector2i(21, -19)],
	[Vector2i(9, 20), Vector2i(37, 21), Vector2i(7, 2), Vector2i(30, 2), Vector2i(20, -22)],
	[Vector2i(14, 19), Vector2i(7, 8), Vector2i(32, 14), Vector2i(9, -8), Vector2i(37, -22)]
]
const CANTOS_COM_URNAS := [
	[Vector3i(3, 22, 2), Vector3i(5, 3, 3), Vector3i(22, -23, 1)],
	[Vector3i(1, 1, 3), Vector3i(38, 2, 1), Vector3i(34, -23, 0)],
	[Vector3i(1, 21, 3), Vector3i(15, 6, 1), Vector3i(29, 15, 3)]
]
