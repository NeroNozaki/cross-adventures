"""Desenha a fonte de interface de Cross Adventures em uma grade própria."""
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

# A última linha de cada desenho encosta na linha de base. Descendentes
# são indicados por > na primeira coluna da definição.
MATRIZES = """
A .###./##.##/##.##/#####/##.##/##.##/##.##
B ####./##.##/##.##/####./##.##/##.##/####.
C .####/##.../##.../##.../##.../##.../.####
D ####./##.##/##.##/##.##/##.##/##.##/####.
E #####/##.../##.../####./##.../##.../#####
F #####/##.../##.../####./##.../##.../##...
G .###./##..#/##.../##.##/##.##/##.##/.###.
H ##.##/##.##/##.##/#####/##.##/##.##/##.##
I ###/.#./.#./.#./.#./.#./###
J ..###/...##/...##/...##/...##/#..##/.###.
K ##..#/##.##/####./###../####./##.##/##..#
L ##.../##.../##.../##.../##.../##.../#####
M ##...##/###.###/#######/##.#.##/##...##/##...##/##...##
N ##..##/###.##/######/##.###/##..##/##..##/##..##
O .###./##.##/##.##/##.##/##.##/##.##/.###.
P ####./##.##/##.##/####./##.../##.../##...
Q .###./##.##/##.##/##.##/####./##.##/.####
R ####./##.##/##.##/####./###../####./##.##
S .####/##.../##.../.###./...##/...##/####.
T #######/..##.../..##.../..##.../..##.../..##.../..##...
U ##.##/##.##/##.##/##.##/##.##/##.##/.###.
V ##..##/##..##/##..##/.####./.####./..##../..##..
W ##...##/##...##/##.#.##/##.#.##/#######/###.###/.#...#.
X ##..##/.####./..##../..##../..##../.####./##..##
Y ##..##/##..##/.####./..##../..##../..##../..##..
Z #####/...##/..##./.##../##.../##.../#####
a .###./...##/.####/##.##/.####
b ##.../##.../####./##.##/##.##/##.##/####.
c .####/##.../##.../##.../.####
d ...##/...##/.####/##.##/##.##/##.##/.####
e .###./##.##/#####/##.../.####
f .###/##../###./##../##../##../##..
g >.####/##.##/##.##/##.##/.####/...##/####.
h ##.../##.../####./##.##/##.##/##.##/##.##
i #/./#/#/#/#/#
j >.#/../.#/.#/.#/.#/.#/##/#.
k ##.../##.../##..#/##.##/####./##.##/##..#
l ##/##/##/##/##/##/.#
m ######./##.#.##/##.#.##/##.#.##/##.#.##
n ####./##.##/##.##/##.##/##.##
o .###./##.##/##.##/##.##/.###.
p >####./##.##/##.##/##.##/####./##.../##...
q >.####/##.##/##.##/##.##/.####/...##/...##
r ####/##../##../##../##..
s .####/##.../.###./...##/####.
t .#../###./##../##../##../.###
u ##.##/##.##/##.##/##.##/.####
v ##.##/##.##/##.##/.###./..#..
w ##...##/##.#.##/##.#.##/#######/.#...#.
x ##.##/.###./..#../.###./##.##
y >##.##/##.##/##.##/##.##/.####/...##/####.
z #####/...##/..##./.##../#####
0 .###./##.##/##.##/##.##/##.##/##.##/.###.
1 .##/###/.##/.##/.##/.##/.##
2 .###./##.##/...##/..##./.##../##.../#####
3 ####./...##/...##/.###./...##/...##/####.
4 ##.##/##.##/##.##/#####/...##/...##/...##
5 #####/##.../##.../####./...##/...##/####.
6 .###./##.../##.../####./##.##/##.##/.###.
7 #####/...##/..##./..##./.##../.##../.##..
8 .###./##.##/##.##/.###./##.##/##.##/.###.
9 .###./##.##/##.##/.####/...##/...##/.###.
! #/#/#/#/#/./#
? .###./#..##/...##/..##./..#../...../..#..
. #
, >./#/#/#
: #/././#
; >#/. /./#/#/#
/ ....#/...#./...#./..#../.#.../.#.../#....
- ###/.../...
· #/././.
( ..#/.#./#../#../#../.#./..#
) #../.#./..#/..#/..#/.#./#..
+ .#./###/.#./.../...
' #/#/././././.
% #...#/...#./...#./..#../.#.../.#.../#...#
◆ ..#../.###./#####/.###./..#..
"""

ACENTOS = {
    "\u0300": ["#..", ".#."],
    "\u0301": ["..#", ".#."],
    "\u0302": [".#.", "#.#"],
    "\u0303": [".##.", "##.."],
    "\u0308": ["#.#"],
}
CARACTERES_ACENTUADOS = "ÀÁÂÃÄÇÉÊÍÓÔÕÚÜàáâãäçéêíóôõúü"
UNIDADE = 94
MARGEM = 43
CHANFRO = 18


def desenho(matriz, base=0, inicio=0):
    return {
        (x + inicio, base + len(matriz) - y - 1)
        for y, linha in enumerate(matriz)
        for x, pixel in enumerate(linha)
        if pixel == "#"
    }


def letras():
    import unicodedata

    glifos = {" ": (set(), 3)}
    for linha in MATRIZES.strip().splitlines():
        caractere, matriz = linha.split(maxsplit=1)
        base = -2 if matriz.startswith(">") else 0
        linhas = matriz.removeprefix(">").split("/")
        glifos[caractere] = (desenho(linhas, base), max(map(len, linhas)))

    for caractere in CARACTERES_ACENTUADOS:
        original, acento = unicodedata.normalize("NFD", caractere)
        base, largura = glifos[original]
        base = base.copy()
        if acento == "\u0327":
            base.update(desenho(["..#", ".##"], -2, (largura - 3) // 2))
        else:
            if original == "i":
                base.discard((0, 6))
            topo = max(y for _x, y in base)
            marca = ACENTOS[acento]
            base.update(desenho(marca, topo + 2, (largura - len(marca[0])) // 2))
        glifos[caractere] = (base, largura)
    return glifos


def arestas_externas(pixels):
    arestas = set()
    for x, y in pixels:
        vertices = [(x, y), (x + 1, y), (x + 1, y + 1), (x, y + 1)]
        for a, b in zip(vertices, vertices[1:] + vertices[:1]):
            if (b, a) in arestas:
                arestas.remove((b, a))
            else:
                arestas.add((a, b))
    return arestas


def vetor(a, b):
    return b[0] - a[0], b[1] - a[1]


def voltas(arestas):
    while arestas:
        a, b = min(arestas)
        contorno = [a]
        while True:
            arestas.remove((a, b))
            if b == contorno[0]:
                break
            contorno.append(b)
            dx, dy = vetor(a, b)
            saidas = [destino for inicio, destino in arestas if inicio == b]
            a, b = b, max(saidas, key=lambda p: dx * (p[1] - b[1]) - dy * (p[0] - b[0]))
        yield contorno


def contorno_com_cantos(contorno):
    for i, (x, y) in enumerate(contorno):
        a, b = vetor((x, y), contorno[i - 1]), vetor((x, y), contorno[(i + 1) % len(contorno)])
        if a[0] == -b[0] and a[1] == -b[1]:
            continue
        # Cantos internos retos mantêm aberturas como as de A, P e O.
        chanfro = CHANFRO if a[1] * b[0] - a[0] * b[1] > 0 else 0
        origem = x * UNIDADE + MARGEM, y * UNIDADE
        yield origem[0] + a[0] * chanfro, origem[1] + a[1] * chanfro
        if chanfro:
            yield origem[0] + b[0] * chanfro, origem[1] + b[1] * chanfro


def glifo(pixels):
    caneta = TTGlyphPen(None)
    for curva in voltas(arestas_externas(pixels)):
        # TrueType espera o contorno externo no sentido horário.
        pontos = list(contorno_com_cantos(curva))[::-1]
        caneta.moveTo(pontos[0])
        for ponto in pontos[1:]:
            caneta.lineTo(ponto)
        caneta.closePath()
    return caneta.glyph()


def gerar(destino):
    dados = {ord(caractere): desenho for caractere, desenho in letras().items()}
    mapa = {codigo: f"uni{codigo:04X}" for codigo in dados}
    formas = {".notdef": glifo({(0, 0), (0, 1), (1, 0), (1, 1)})}
    metricas = {".notdef": (3 * UNIDADE, MARGEM)}
    for codigo, (pixels, largura) in dados.items():
        nome = mapa[codigo]
        formas[nome] = glifo(pixels)
        margem_esquerda = (min(x for x, _y in pixels) * UNIDADE + MARGEM) if pixels else 0
        metricas[nome] = (largura * UNIDADE + MARGEM * 2 + 28, margem_esquerda)
    fonte = FontBuilder(1000, isTTF=True)
    fonte.setupGlyphOrder(list(formas))
    fonte.setupCharacterMap(mapa)
    fonte.setupGlyf(formas)
    fonte.setupHorizontalMetrics(metricas)
    fonte.setupHorizontalHeader(ascent=960, descent=-205)
    fonte.setupNameTable({
        "familyName": "Cross Inscricao",
        "styleName": "Regular",
        "uniqueFontIdentifier": "CrossInscricao-1.0",
        "fullName": "Cross Inscricao",
        "psName": "CrossInscricao-Regular",
        "version": "Version 1.0",
    })
    fonte.setupOS2(sTypoAscender=960, sTypoDescender=-205, usWinAscent=960, usWinDescent=205,
                  sCapHeight=658, sxHeight=470)
    fonte.setupPost()
    fonte.save(destino)


if __name__ == "__main__":
    gerar(Path(__file__).with_name("CrossInscricao.ttf"))
