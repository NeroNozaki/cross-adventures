extends RefCounted
## Composição manual em células de 24px; o gerador salva TileMapLayers editáveis.
const FASES = {
1: {
"nome":"Celas do Despertar", "modo":"placa", "tom":Color("#bac8cc"),
"salas":[Rect2i(2,12,11,8),Rect2i(2,2,11,8),Rect2i(9,8,4,6),Rect2i(12,11,11,4),Rect2i(21,2,9,18)],
"agua":[Rect2i(14,3,5,6),Rect2i(14,17,5,3)],
"inicio":Vector2i(6,17),"placa":Vector2i(8,15),"alvos":[Vector2i(17,11)],
"porta":Vector2i(28,3),"grade":Rect2i(20,11,1,4),"saida":Vector2i(28,5),
"dica":"Nico: fique na pedra. Otto: encontre o alvo e dispare.",
"props":[[3,3,"estante"],[4,3,"urna"],[10,3,"barril"],[3,8,"caixa"],[3,13,"barril"],[4,13,"urna"],[11,18,"caixa"],[23,3,"estante"],[24,3,"urna"],[28,17,"bau"],[22,18,"barril"]],
"tochas":[Vector2i(5,1),Vector2i(10,1),Vector2i(5,11),Vector2i(25,1),Vector2i(28,1)],
"tapetes":[Rect2i(4,16,5,3),Rect2i(25,7,3,7)],"segredos":[Vector2i(6,5)]
},
2: {
"nome":"Galeria dos Símbolos", "modo":"sequencia", "tom":Color("#adc8d3"),
"salas":[Rect2i(2,2,11,18),Rect2i(19,2,11,18)],
"agua":[Rect2i(13,2,6,18)],"ponte":Rect2i(13,8,6,3),
"inicio":Vector2i(6,17),"placa":Vector2i(7,16),"alvos":[Vector2i(4,4),Vector2i(7,4),Vector2i(10,4)],
"porta":Vector2i(27,3),"grade":Rect2i(13,8,6,3),"saida":Vector2i(27,5),
"dica":"Leiam a pista: 2 → 1 → 3. Nico segura a pedra; Otto acerta os símbolos.",
"props":[[3,3,"estante"],[11,3,"estante"],[3,10,"urna"],[11,10,"urna"],[3,18,"barril"],[11,18,"caixa"],[20,3,"barril"],[21,3,"caixa"],[28,17,"bau"],[20,18,"urna"],[27,11,"estante"]],
"tochas":[Vector2i(5,1),Vector2i(9,1),Vector2i(22,1),Vector2i(27,1)],
"tapetes":[Rect2i(4,7,7,3),Rect2i(23,7,4,8)],"segredos":[Vector2i(23,17)]
},
4: {
"nome":"Portão da Aurora", "modo":"ricochete", "tom":Color("#d5c6a9"),
"salas":[Rect2i(2,9,28,11),Rect2i(10,2,11,5),Rect2i(14,6,3,4)],
"agua":[Rect2i(11,11,7,6)],
"inicio":Vector2i(6,17),"placa":Vector2i(7,15),"alvos":[Vector2i(24,10)],
"espelho":Vector2i(24,17),"tiro":Vector2i(19,17),
"porta":Vector2i(15,2),"grade":Rect2i(14,8,3,1),"saida":Vector2i(15,4),
"placas_finais":[Vector2i(12,5),Vector2i(18,5)],
"dica":"Nico na pedra. Otto: segure o clique e atire no espelho para o alvo.",
"props":[[3,10,"estante"],[4,10,"urna"],[10,18,"barril"],[18,18,"caixa"],[28,10,"estante"],[28,18,"barril"],[11,3,"urna"],[19,3,"urna"],[3,18,"bau"]],
"tochas":[Vector2i(5,8),Vector2i(9,8),Vector2i(22,8),Vector2i(28,8),Vector2i(12,1),Vector2i(18,1)],
"tapetes":[Rect2i(4,13,5,5),Rect2i(13,3,5,3),Rect2i(20,12,3,4)],"segredos":[Vector2i(28,14)]
}}
