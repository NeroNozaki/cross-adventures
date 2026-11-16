# Campanha de quatro puzzles — Nico e Otto

Branch de trabalho: `dev/new-player1`. Projeto ativo no clone separado `cross-adventures-player1`. O menu agora abre a fase 01; a masmorra fornecida foi mantida como terceira etapa. Não foi recuperado o antigo Bosque.

## Percurso

| Etapa | Cena | O que a criança pratica |
|---|---|---|
| 1 — Celas do Despertar | `cenas/areas/puzzle_01.tscn` | Movimentação, observar causa e efeito, ajudar e esperar |
| 2 — Galeria dos Símbolos | `cenas/areas/puzzle_02.tscn` | Ler uma pista numérica, ordenar três ações, tentar novamente |
| 3 — Masmorra existente | `cenas/areas/area_3.tscn` | Travessia, plataformas, interruptores e coordenação da dupla |
| 4 — Portão da Aurora | `cenas/areas/puzzle_04.tscn` | Combinar placa, tiro carregado, reflexão e ação simultânea |

As três fases novas não contêm inimigos, cronômetro ou dano ao errar o puzzle. A terceira conserva os perigos, checkpoints e plataformas do mapa fornecido. A dificuldade da campanha ainda precisa de observação com as crianças; os testes técnicos não substituem essa avaliação.

## Soluções e cuidados

1. Nico fica na placa marcada NICO. Otto anda até o corredor e acerta o alvo revelado. Sair da placa antes do acerto recolhe o alvo. O acerto é permanente: a grade abaixa, a porta abre e os dois precisam entrar no círculo de saída.
2. Nico mantém a placa. Otto acerta os pedestais **2, 1, 3**. Os números estão nos pedestais e na pista do chão. Um erro limpa a sequência e permite tentar novamente; não retira vida nem progresso de amizade. A ponte sobe com som e só libera a colisão ao terminar. Ela fica aberta mesmo quando Nico deixa a placa. Atravessem e cheguem juntos à porta.
3. O mapa original continua usando seus botões, alvos, plataformas e checkpoint. Foi acrescentada a ativação explícita da grade superior quando as duas placas são pressionadas. A saída agora leva à fase 04. O capítulo narrativo desta cena é 3.
4. Nico mantém a placa à esquerda. Otto vai até a marca de disparo à direita, segura o botão esquerdo por pelo menos 0,85 s e atira para a direita no espelho diagonal; a esfera é desviada para cima e acerta o alvo. Um disparo direto ou sem carga não resolve. Depois de abrir a grade, cada amigo ocupa uma das duas placas no salão superior. A porta fica aberta após a ativação simultânea. Ambos chegam ao círculo e assistem à conclusão da amizade antes da tela final.

Os diálogos continuam curtos, com digitação, Continuar e Pular tudo. As dicas temporárias duram quatro segundos; o objetivo curto fica no canto para apoiar quem ainda precisa lembrar o próximo passo. Após 25 segundos sem avanço há uma dica adicional, sem contagem regressiva ou penalidade.

## Arte efetivamente utilizada

- **CraftPix Dungeon / Tiled_files:** `walls_floor.png` (paredes, bordas e mosaicos), `Objects.png` (baús, barris, armários de madeira, urnas, pedestais e espelho), `fire_animation.png`, `doors_lever_chest_animation.png` e `water_details_animation.png`.
- **Ninja Adventure:** `TilesetInteriorFloor.png` (pedra detalhada), botões e alvos das cenas existentes, `GemYellow.png` (joias opcionais), moldura `ThemeMetal3`, além dos personagens e música `21 - Dungeon.ogg` já disponíveis.
- **Tiny Swords:** `Water Background color.png`, com coloração de reservatório, ondas CraftPix, sombras de contato e ondulações por gotas. A água é bloqueada fisicamente; nenhuma decoração foi colocada dentro dela.
- **Áudio existente:** clique de placa, acerto de receptor, tentativa incorreta e `ponte_mecanismo.wav`. M mantém o controle de silêncio.

Nenhuma imagem de mapa foi criada com IA ou usada como fundo. O cenário é composto por tiles e objetos reais. A variação de ladrilhos é determinística; os percursos e posições dos mecanismos são definidos manualmente em `recursos/mapas_puzzle.gd`.

## Edição

As cenas contêm TileMapLayers, colisões, objetos, animações, câmera e personagens editáveis. O TileSet comum é `recursos/puzzles_tileset.tres`. `ferramentas/construir_puzzles.gd` reconstrói **somente 01, 02 e 04** a partir dos dados e preserva as versões anteriores em `backups/puzzles` (fora do Git e ignorado pelo Godot). Ajustes manuais das cenas devem ser refletidos nos dados/gerador antes de uma nova reconstrução. O gerador não altera `area_3.tscn`.

## Verificação

`testes/verificar_campanha_puzzles.gd` testa menu, rotas com colisões de raio 9, impedimento de atalhos, papel exclusivo de Nico na placa, tiros reais, sequência errada/correta, travessia física dos dois sobre a ponte, ricochete real, placas simultâneas e as transições até o fim. A travessia completa de todos os obstáculos internos da antiga area_3 não é simulada por esse teste; ele verifica suas duas placas e sua saída. `testes/verify_switch.gd` cobre o interruptor original. Capturas renderizadas dos três mapas foram revisadas para conferir recortes e escala.
