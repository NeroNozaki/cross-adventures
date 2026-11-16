# Campanha de quatro puzzles — Nico e Otto

Branch de trabalho: `dev/new-player1`. Projeto ativo no clone separado `cross-adventures-player1`. O menu agora abre a fase 01; a masmorra fornecida foi mantida como terceira etapa. Não foi recuperado o antigo Bosque.

## Percurso

| Etapa | Cena | O que a criança pratica |
|---|---|---|
| 1 — Celas do Despertar | `cenas/areas/puzzle_01.tscn` | Movimentação, observar causa e efeito, ajudar e esperar |
| 2 — Cisterna das Memórias | `cenas/areas/puzzle_02.tscn` | Explorar alcovas, relacionar formas e ordem, preservar os acertos |
| 3 — Masmorra existente | `cenas/areas/area_3.tscn` | Travessia, plataformas, interruptores e coordenação da dupla |
| 4 — Portão da Aurora | `cenas/areas/puzzle_04.tscn` | Combinar placa, tiro carregado, reflexão e ação simultânea |

As três fases novas não contêm inimigos, cronômetro ou dano ao errar o puzzle. A terceira conserva os perigos, checkpoints e plataformas do mapa fornecido. A dificuldade da campanha ainda precisa de observação com as crianças; os testes técnicos não substituem essa avaliação.

## Soluções e cuidados

1. Os dois acordam em celas distintas, com camas, armário e pertences. Nico fica na placa marcada NICO. Otto acerta o alvo dentro de sua cela; a primeira grade abaixa permanentemente. Depois os papéis se alternam: Otto mantém a placa do salão e Nico usa F perto da trava metálica da sala à direita. A segunda grade e a porta abrem de forma permanente. Os dois se reúnem na saída.
2. A cisterna tem uma galeria em U, três alcovas e uma ilha central. Nico golpeia a trava central com F para despertar os receptores. Ao se aproximar das alcovas, descobre as marcas **primeiro triângulo, depois círculo, por último quadrado**. Elas ficam registradas no HUD. Otto acerta os três receptores nessa ordem. Cada acerto acende um encaixe da ponte; erros preservam os acertos anteriores. A pista do passo precisa ter sido descoberta para seu acerto valer. A ponte de pedra sobe laje por laje, com som; só libera a colisão depois do último encaixe. Ela permanece aberta. A margem leste leva à saída e tem uma joia opcional.
3. A geometria do mapa colaborativo, perigos, plataformas, interruptores e checkpoint foi conservada. A sinalização agora identifica o abrigo e as duas placas da sala de cooperação. O checkpoint avisa por quatro segundos que a dupla voltará ali ao cair. A cadência da animação de caminhada também segue a distância percorrida. As duas placas abrem a grade superior; a saída leva à fase 04.
4. O salão final tem duas alas e um portão central. Nico sobe pela ala esquerda e golpeia a trava com F para girar o espelho da ala direita. Depois mantém a placa inferior esquerda. Otto vai à marca de disparo, segura o clique esquerdo por pelo menos 0,85 s e lança para a direita; o espelho reflete a esfera para o alvo no alto. Um disparo direto ou sem carga não resolve. A grade central abre e os dois se reencontram no salão superior. Uma placa para cada amigo abre a porta final, que ganha luz quente. Ambos entram na saída para concluir a história.

Os diálogos continuam curtos, com digitação, Continuar e Pular tudo. As dicas temporárias duram quatro segundos; o objetivo curto fica no canto para apoiar quem ainda precisa lembrar o próximo passo. Após 25 segundos sem avanço há uma dica adicional, sem contagem regressiva ou penalidade.

## Arte efetivamente utilizada

- **CraftPix Dungeon / Tiled_files:** `walls_floor.png` (paredes, bordas e mosaicos), `Objects.png` (baús, barris, armários de madeira, urnas, pedestais e espelho), `fire_animation.png`, `doors_lever_chest_animation.png` e `water_details_animation.png`.
- **Ninja Adventure:** `TilesetInteriorFloor.png` (pedra detalhada), botões e alvos das cenas existentes, `GemYellow.png` (joias opcionais), moldura `ThemeMetal3`, além dos personagens e música `21 - Dungeon.ogg` já disponíveis.
- **Tiny Swords:** `Water Background color.png`, com coloração de reservatório, ondas CraftPix, sombras de contato e ondulações por gotas. A água é bloqueada fisicamente; nenhuma decoração foi colocada dentro dela.
- **Áudio existente:** clique de placa, acerto de receptor, tentativa incorreta e `ponte_mecanismo.wav`. M mantém o controle de silêncio.

Também foram usados `tileset_bed.png` (Ninja Adventure, camas das celas) e `Structure.png` (Dungeon Gathering, colunas com base e capitel). Um shader simples desatura a pedra dos conjuntos e aproxima sua paleta, preservando as imagens originais. Coroamentos e sombras de contato reforçam a profundidade das paredes. A água tem ondas animadas do pacote e ondulações por gotas; não é uma simulação de fluido. Nenhum móvel ou tocha fica dentro da água.

Nenhuma imagem de mapa foi criada com IA ou usada como fundo. O cenário é composto por tiles e objetos reais. A variação de ladrilhos é determinística; os percursos e posições dos mecanismos são definidos manualmente em `recursos/mapas_puzzle.gd`. A câmera acompanha a dupla e ajusta a distância conforme a separação, revelando os setores durante a exploração.

## Edição

As cenas contêm TileMapLayers, colisões, objetos, animações, câmera e personagens editáveis. O TileSet comum é `recursos/puzzles_tileset.tres`. `ferramentas/construir_puzzles.gd` reconstrói **somente 01, 02 e 04** a partir dos dados e preserva as versões anteriores em `backups/puzzles` (fora do Git e ignorado pelo Godot). Ajustes manuais das cenas devem ser refletidos nos dados/gerador antes de uma nova reconstrução. O gerador não altera `area_3.tscn`.

## Verificação

`testes/verificar_campanha_puzzles.gd` testa menu, rotas com colisões de raio 9, celas realmente separadas, impedimento de atalhos, alternância das placas, golpes reais de Nico na trava, leitura das pistas por proximidade, tiros reais de Otto, preservação de acertos, travessia física dos dois sobre a ponte, rotação e ricochete real, placas simultâneas e transições até o fim. Também verifica que os móveis e as tochas não ocupam água. Pode executar somente o primeiro puzzle com `-- --somente-celas`.

A travessia completa de todos os obstáculos internos da antiga area_3 não é simulada por esse teste; ele verifica suas duas placas e sua saída. `testes/verify_switch.gd` cobre o interruptor original. Capturas renderizadas dos três mapas foram revisadas para conferir recortes, escala e leitura. Ainda é necessário observar as crianças jogando para avaliar duração, compreensão e dificuldade.

Resultado em Godot 4.7.1: 60 verificações da campanha e 19 dos interruptores, sem falhas. Importação pelo editor e renderização OpenGL também concluídas. Uma mutação controlada da condição de ajuda de Otto fez o teste das celas falhar no ponto esperado; a condição correta foi restaurada antes da execução final.

## Referências aplicadas

- [Radical Fish, criação de puzzles de CrossCode](https://www.reddit.com/r/nintendo/comments/ha6fjf/we_are_radical_fish_games_deck13_developer_and/): introduzir ações distintas e combiná-las. Aplicação própria: alternância de ajuda nas celas e retomada das regras no portão.
- [Radical Fish, acabamento de dungeon](https://www.radicalfishgames.com/?p=2627): referência de profundidade e leitura do ambiente. Aplicação própria: bordas, colunas apoiadas, sombras e pedra com paleta comum.
- [Nintendo, Echoes of Wisdom](https://www.nintendo.com/us/whatsnew/ask-the-developer-vol-13-the-legend-of-zelda-echoes-of-wisdom-part-4/): exploração compacta. Aplicação própria: alcovas de pistas e pequenos desvios opcionais.
- [Saralie Wågström, cenários de It Takes Two](https://saraliewagstrom.artstation.com/projects/xJ6OyO): orientação e distinção de setores. Aplicação própria: duas alas com funções complementares no final.

São referências de princípios; nenhum layout ou asset desses jogos foi copiado.
