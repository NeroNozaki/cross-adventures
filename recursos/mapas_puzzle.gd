extends RefCounted
## Salas com função, percursos em laço e marcos visuais. Células de 24px.
const FASES = {
1: {
"nome":"Celas do Despertar", "modo":"resgate", "tom":Color("#bac8cc"), "tamanho":Vector2i(36,26),
"salas":[Rect2i(2,18,7,6),Rect2i(12,18,7,6),Rect2i(6,14,3,5),Rect2i(13,14,3,5),Rect2i(5,10,13,6),Rect2i(17,11,7,3),Rect2i(21,10,12,6),Rect2i(27,6,3,5),Rect2i(25,2,8,5),Rect2i(4,3,7,5),Rect2i(8,7,3,4)],
"agua":[Rect2i(14,3,8,5),Rect2i(23,16,8,5)],
"inicio":Vector2i(5,22),"inicios":[Vector2i(5,22),Vector2i(15,22)],
"placa":Vector2i(7,20),"placa_otto":Vector2i(14,12),"mecanismo":Vector2i(23,12),
"alvos":[Vector2i(15,19)],"porta":Vector2i(29,2),"grade":Rect2i(13,17,3,1),"grade_final":Rect2i(27,7,3,1),"saida":Vector2i(29,4),
"dica":"Nico, a pedra acende o alvo da cela de Otto. Vamos ajudá-lo a sair!",
"props":[[3,19,"cama"],[3,22,"urna"],[8,22,"caixa"],[17,19,"cama"],[17,22,"estante"],[5,10,"coluna"],[17,10,"coluna"],[6,10,"barril"],[4,3,"estante"],[5,3,"urna"],[10,4,"caixa"],[21,10,"coluna"],[32,10,"coluna"],[22,14,"barril"],[31,14,"caixa"],[26,3,"coluna"],[32,3,"coluna"],[31,5,"urna"]],
"tochas":[Vector2i(4,17),Vector2i(17,17),Vector2i(7,9),Vector2i(15,9),Vector2i(27,1),Vector2i(31,1),Vector2i(6,2)],
"tapetes":[Rect2i(6,14,3,4),Rect2i(10,11,5,3),Rect2i(27,6,3,5),Rect2i(27,3,4,3)],
"segredos":[Vector2i(9,5)]
},
2: {
"nome":"Cisterna das Memórias", "modo":"sequencia", "tom":Color("#adc8d3"), "tamanho":Vector2i(36,26),
"salas":[Rect2i(3,18,10,6),Rect2i(3,4,7,16),Rect2i(7,3,17,5),Rect2i(14,10,7,6),Rect2i(9,11,6,3),Rect2i(25,4,8,20),Rect2i(26,2,7,5)],
"agua":[Rect2i(10,8,15,2),Rect2i(10,10,4,1),Rect2i(10,14,4,4),Rect2i(21,10,4,8),Rect2i(14,16,7,2)],
"ponte":Rect2i(21,12,4,3),"inicio":Vector2i(6,21),"placa":Vector2i(17,14),"mecanismo":Vector2i(17,14),
"pistas":[Vector2i(6,14),Vector2i(12,5),Vector2i(22,5)],
"alvos":[Vector2i(15,11),Vector2i(17,11),Vector2i(19,11)],
"porta":Vector2i(29,2),"grade":Rect2i(21,12,4,3),"saida":Vector2i(29,4),
"dica":"Nico reconhece as marcas antigas. Procurem as três pistas pela galeria.",
"props":[[4,5,"coluna"],[8,5,"coluna"],[4,8,"urna"],[4,18,"estante"],[4,22,"barril"],[11,22,"caixa"],[9,4,"estante"],[15,4,"coluna"],[23,4,"coluna"],[14,10,"coluna"],[20,10,"coluna"],[25,5,"coluna"],[32,5,"coluna"],[31,20,"bau"],[26,21,"urna"],[27,7,"estante"]],
"tochas":[Vector2i(5,3),Vector2i(16,2),Vector2i(21,2),Vector2i(27,1),Vector2i(31,1),Vector2i(2,20)],
"tapetes":[Rect2i(5,18,3,5),Rect2i(4,10,4,2),Rect2i(10,4,5,2),Rect2i(15,12,5,2),Rect2i(28,6,3,12)],
"segredos":[Vector2i(29,22)]
},
4: {
"nome":"Portão da Aurora", "modo":"ricochete", "tom":Color("#d5c6a9"), "tamanho":Vector2i(36,26),
"salas":[Rect2i(13,19,10,5),Rect2i(3,14,9,9),Rect2i(11,18,4,3),Rect2i(25,14,8,9),Rect2i(22,18,4,3),Rect2i(4,8,8,5),Rect2i(7,12,3,3),Rect2i(25,8,8,5),Rect2i(27,12,3,3),Rect2i(13,8,10,8),Rect2i(11,10,3,3),Rect2i(22,10,4,3),Rect2i(13,2,10,4),Rect2i(16,5,4,4)],
"agua":[Rect2i(14,12,8,3),Rect2i(14,16,8,2)],
"inicio":Vector2i(18,22),"placa":Vector2i(7,18),"mecanismo":Vector2i(7,10),"alvos":[Vector2i(29,10)],
"espelho":Vector2i(29,20),"tiro":Vector2i(26,20),
"porta":Vector2i(18,2),"grade":Rect2i(16,7,4,1),"saida":Vector2i(18,3),
"placas_finais":[Vector2i(15,4),Vector2i(20,4)],
"dica":"Uma ala para cada amigo. Nico prepara a roda; Otto procura o espelho.",
"props":[[4,15,"coluna"],[11,15,"coluna"],[4,21,"barril"],[10,21,"caixa"],[5,8,"coluna"],[11,8,"coluna"],[26,8,"coluna"],[32,8,"coluna"],[26,15,"coluna"],[32,15,"coluna"],[31,22,"bau"],[14,20,"urna"],[22,20,"urna"],[14,2,"coluna"],[22,2,"coluna"],[14,5,"urna"],[22,5,"urna"],[13,8,"coluna"],[22,8,"coluna"]],
"tochas":[Vector2i(5,13),Vector2i(10,13),Vector2i(27,13),Vector2i(31,13),Vector2i(15,1),Vector2i(21,1),Vector2i(17,18),Vector2i(20,18)],
"tapetes":[Rect2i(16,20,4,3),Rect2i(6,15,3,5),Rect2i(28,15,3,5),Rect2i(16,5,4,6),Rect2i(16,2,4,3)],
"segredos":[Vector2i(5,11)]
}}
