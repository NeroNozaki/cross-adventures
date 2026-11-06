# Cross Adventures — referência do projeto

Fonte principal de design: `documentacao/SGDD - Cross Adventures.pdf`, 1 página, por Protetores da Juventude. O usuário entregou o documento e o definiu como referência para as próximas instruções em 21/10/2026. O conteúdo descreve o produto; o checklist do PDF não autoriza executar automaticamente todas as funcionalidades.

## Conceito e enredo do SGDD

- Aventura breve, cooperativa local para dois jogadores, com visão de cima, voltada para crianças.
- Lucas, um menino humano, ouve falar da antiga Provação do Herói, um campo de provas deixado por heróis antigos, e leva seu companheiro robô Otto em busca de uma recompensa incrível. Otto acha a ideia ruim. A recompensa não é especificada.
- Lucas usa espada e escudo. Otto dispara esferas que ricocheteiam e pode mirar.
- Os jogadores cooperam para resolver puzzles simples e enfrentar inimigos em quatro fases curtas.
- Exemplos de puzzles: apertar botões, empurrar caixas e pular vãos.
- O design prevê um controle para Lucas e mouse e teclado para Otto. Cada protagonista tem ataque e uma ação de utilidade; a utilidade de Otto não está definida.
- Arte prevista: Lucas, Otto, tilemap, dois tipos de inimigo e um chefe. O PDF não define nomes, comportamento ou aparência do chefe.
- Cenas previstas: menu principal, pausa, quatro fases, respawn, fim de jogo e transições.
- Programação prevista: puzzles, inimigos, vida e dano, movimentação.
- Áudio previsto: música de menu, padrão, combate, derrota e tela de fim; efeitos sonoros aparecem como possibilidade no SGDD e foram solicitados explicitamente pelo usuário nesta etapa.

## Decisões já tomadas diretamente com o usuário

- Projeto em `C:\Users\finan\OneDrive\Documentos\cross-adventures`, usando Godot 4.7.1 e os assets copiados da Área de Trabalho.
- Visão de cima e combate em tempo real.
- Dois personagens controláveis de forma independente e simultânea. Na arena atual: Lucas (cena Guerreiro) no WASD, clique direito/Espaço/J para combo e Shift para escudo; Otto (cena Robô) nas setas, mouse para mira 360° e clique esquerdo/Enter para tiro; segurar e soltar carrega uma esfera maior. R reinicia.
- O personagem sem comandos fica parado, sem seguir ou atacar pelo outro.
- Escudo bloqueia o cone frontal, com faíscas de impacto; não protege as costas. A defesa reduz a velocidade e impede atacar simultaneamente.
- Ataques laterais do Guerreiro foram corrigidos para estocadas na direção comandada, sem o giro que levava a espada para o lado contrário.
- Cavaleiro deixa elmo, peitoral e botas caídos no ponto da morte, sem bloquear passagem.
- Inimigos atuais: Cavaleiro Azul e Zumbi. São os dois vilões montados a partir dos assets disponíveis; o chefe atual é o Guardião da Provação, derivado do Cavaleiro Azul, com três selos de proteção e pulso anunciado.
- Efeitos sonoros são integrados nesta etapa para os quatro personagens, com perfis separados. M alterna o som dos efeitos.

## Estado de implementação e diferenças para o SGDD

Implementado: quatro cenas reutilizáveis, animações, colisões, combate corpo a corpo, vida, defesa, dano, invulnerabilidade temporária, morte, barras de vida, IA de perseguição/ataque com rotas pelo chão disponível, escudo, armadura caída, controles simultâneos e arena de teste. Também implementados: combo de três golpes de Lucas, mira 360° de Otto, tiro simples e carregado, colisão contínua e quatro ricochetes.

Áudio desta etapa: passos por deslocamento real, ataque, acerto confirmado, dano e morte dos quatro personagens; equipar/erguer escudo e bloqueio frontal de Lucas; som metálico da armadura sincronizado com a queda. As cenas usam o componente AudioPersonagem e os perfis em recursos/audio. O mapa dos arquivos está em documentacao/MAPA_DE_SONS.json.

Otto agora usa projéteis. Clique curto gera esfera simples; segurar por 0,85 s e soltar gera esfera maior. A simples para no primeiro contato com parede; somente a carregada ricocheteia, apagando no quinto contato. As duas desaparecem ao atingir um inimigo. Mira, carga, disparo, dano e ricochete têm efeitos visuais/sonoros. Os tiros não causam dano nos aliados. Detalhes em documentacao/COMBO_MIRA_PROJETEIS.md.

O controle de gamepad para Lucas ainda NÃO foi implementado. Otto já usa teclado independente e mira pelo mouse. A utilidade final de Otto, além da ação de ataque carregado solicitada nesta etapa, continua sem definição no SGDD.

Implementados em 26/10/2026: quatro fases curtas — Jardim da Provação, Galeria dos Ecos, Oficina das Quatro Fontes e Santuário do Guardião — com TileMapLayers editáveis por altura, saltos de mesmo Z, rampas, ponte ativável, previsão de ricochetes e trava da mira, placas cooperativas exclusivas de Lucas, água/gelo empurrável, fogo/choque/onda, objetos destrutíveis com fragmentos, plataforma móvel que transporta os heróis, exploradores em rotas, chefe com três selos, respawn individual após três segundos, portais para a equipe completa, transições automáticas e mensagem final com Medalha da Equipe. Essa recompensa foi definida na implementação; o SGDD não a especificava. Os mecanismos da sala permanecem no respawn, mas não há save permanente. A cena inicial passou a cenas/fases/01_jardim.tscn.

Controles novos: Lucas F salta e E interage/empurra; Otto P salta e I interage; C alterna elementos nas fases 3/4; Tab trava a mira; F1 mostra ajuda. Detalhes e soluções em documentacao/FASES.md. Cenários originais com assets existentes e o pacote gratuito oficial CraftPix; inspiração mecânica enviada pelo usuário, sem baixar mapas ou arte de CrossCode.

Menu principal, ajuda integrada e pausa com Continuar/Reiniciar/Menu foram implementados na reformulação visual. Ainda pendentes: arte exclusiva de chefe, músicas e gamepad de Lucas. O SGDD não especifica inventário, experiência ou progressão de níveis; não presumir esses sistemas apenas pela referência anterior a RPG.

Os efeitos usam arquivos existentes nos assets; não foram criadas vozes, falas ou músicas novas. As licenças permanecem em assets/DOCUMENTACAO.

## Como continuar

Usar esta referência e o SGDD para orientar novas solicitações. Decisões explícitas posteriores do usuário têm prioridade sobre este resumo. Registrar mudanças de design e manter o estado real separado do conteúdo planejado. Não anunciar um item do backlog como pronto sem implementação e verificação.

Abra project.godot no Godot e pressione F5. Verificação de jogabilidade: testes/verificar_personagens.gd. Verificação de áudio: testes/verificar_audio.gd. Combo, mira e interações: testes/verificar_combo_mira.gd. Fases, puzzles, alturas e progressão: testes/verificar_fases.gd.

## Reformulação visual — 26/10/2026

O usuário esclareceu que a PASTA REAL é C:\Users\finan\OneDrive\Documentos\cross-adventures, e que os novos assets estão em assets/mapa. Usar este projeto nas próximas alterações. MeuJogo é uma cópia anterior; as quatro fases e os ajustes de altura foram integrados ao projeto real nesta etapa.

523 arquivos originais catalogados em quatro pacotes (documentacao/INVENTARIO_MAPA.json). Na primeira revisão, a base visual foi 0x72_16x16DungeonTileset.v5: piso próprio, paredes, acabamentos, colunas, estandartes, tochas animadas, caixotes e NPCs. Os demais pacotes foram avaliados e mantidos como reserva para evitar mistura de escalas e estilos. Os originais não foram alterados.

Cada fase tem paleta própria: verde das ruínas, azul da galeria, cobre da oficina e violeta/dourado do santuário. Novas divisórias têm colisão real; os caminhos e os puzzles foram preservados e testados. O HUD possui vida dos dois heróis, nome da fase, objetivo, contador de mecanismos e ajuda. Objetos de puzzle ganharam acabamento coerente de pedra/metal, sinais e portais próprios.

A cena inicial agora é cenas/interface/menu.tscn. F5 abre o menu; Iniciar aventura entra no Jardim. Esc pausa de verdade e permite continuar, reiniciar a sala ou voltar ao menu. F1 abre o guia. A mira mostra o primeiro segmento durante o repouso; ao carregar ou travar com Tab, mostra as reflexões seguintes. O cálculo da trajetória continua disponível antes do tiro.

Testes de personagens, áudio, combo/mira, fases e interface foram aprovados. Consulte documentacao/DIRECAO_VISUAL.md para decisões de arte, inventário e edição.

## Segunda revisão dos cenários — 27/10/2026

Após rejeitar o desenho anterior, o usuário forneceu referências de masmorras detalhadas. A base atual passou a CraftPix Free 2D Top-Down Pixel Dungeon, obtida no perfil oficial do autor: https://free-game-assets.itch.io/free-2d-top-down-pixel-dungeon-asset-pack . É o pacote da primeira referência. A terceira referência é um produto pago; seus arquivos não foram adquiridos nem copiados. Licença e origem preservadas em assets/mapa/CRAFTPIX_DUNGEON.

As quatro fases foram reconstruídas em grades de 38×26, com salas e corredores conectados, reservatórios e canais animados, paredes de pedra, beirais, escadas, nichos, decoração e tochas animadas com PointLight2D. As mecânicas foram reposicionadas para os novos percursos. A câmera acompanha os dois protagonistas e V alterna a visão geral. Os heróis, sons, controles e combate anteriores foram preservados.

A IA agora calcula rotas pelo chão da fase e considera portas, pontes e obstáculos atuais; evita perseguir através da água. A reflexão em espelhos usa a normal exata do espelho tanto na previsão como no projétil, evitando desvios numéricos em tiros longos. O quarto ricochete continua encerrando o projétil.

O gerador e os JSONs são a fonte das cenas; preservam backups. Não trocar as imagens de Tiled_files pelas de PNG: possuem layouts diferentes. testes/verificar_cenarios.gd complementa os testes anteriores com apoio dos mecanismos, colisão inicial, rotas e câmera cooperativa.

## Acabamento de água e itens — 27/10/2026

O usuário rejeitou o aspecto artificial da água e os itens cortados. Corrigidos os recortes de baús, barris, caixas e urnas, escala inteira 2×, apoio visual e sobreposições entre decoração e objetos interativos. Placas, sinais, plantas, cristais, pedestais e proporções das portas foram refinados. A água passou a usar profundidade por distância da margem, sombras, alvenaria na borda e os seis quadros completos das ondulações nativas. A superfície deixa livre a ponte ativada. Scripts: scripts/visual/agua_cenario.gd e agua_profundidade.gdshader. Detalhes de atlas e validação em DIRECAO_VISUAL.md. Testes de acabamento (163), fases (75), cenários (87) e combo/mira (46) passaram; quatro fases renderizadas sem erros.

## Interface pixel — 27/10/2026

HUD, menu, guia, pausa e conclusão agora compartilham fonte Tiny5 com acentos, moldura própria em grade, paleta azul/metal e detalhes dourados/ciano. Foram examinadas as pastas de interface e sons; não havia fonte local. Tiny5 foi acrescentada com licença OFL. Retratos, vida segmentada animada e estados reais de escudo, combo e carga compõem o HUD. Avisos têm revelação progressiva e altura adaptativa. F1 agora pausa enquanto o guia está aberto. As trocas de fase, reinícios e navegação usam cortina em blocos e bloqueiam comandos durante a animação.

Novos autoloads: InterfaceAudio e FluxoTela. Sete efeitos Kenney existentes foram integrados em bus Interface enviado para SFX; M controla também esses sons. O áudio de personagens foi preservado. Teste de interface ampliado para 55 verificações; detalhes e inventário em documentacao/INTERFACE_PIXEL.md e INVENTARIO_INTERFACE.json.

## HUD compacto e história temporária — 27/10/2026

Por pedido explícito do usuário, o HUD da partida foi reduzido: fonte 8 px, retratos de 16×16, cartões menores nos cantos, fase discreta e objetivo em faixa de 24 px. Foi retirada a faixa grande de entrada da fase; o mapa fica mais exposto. Menu, pausa e guia continuam modais e mantêm a leitura maior quando abertos.

A caixa “Dica da equipe” foi substituída por texto temporário, sem título, escrito letra a letra com som. Depois da escrita completa há 2,4 s de leitura e a caixa desaparece. Textos longos são paginados em no máximo três linhas; a caixa não ultrapassa 44 px. O texto continua até terminar se a origem expirar antes, e não reaparece por permanecer ativo na fase. Guia/pausa suspendem a escrita e o som para ao terminar. A fase ainda entrega o texto por gui.mensagem (Label oculto); gui.texto_aviso é a apresentação visível. Preservar essa separação.

verificar_interface.gd agora tem 61 verificações, incluindo desaparecimento, retenção correta do texto, silêncio após escrita, paginação e pausa da história. Prévias foram renderizadas no Godot, com escrita, leitura e mapa livre após sumir.

## Conferência das quatro fases e cópia antiga — 27/10/2026

O usuário enviou uma imagem de cenário com grama e HUD grande. Foi confirmado que esse desenho e o objetivo “Placa + cristal > ponte. Derrotem os guardas. Subam a rampa e saltem o vao.” estão na cópia MeuJogo. O gerenciador do Godot registrava apenas essa cópia, sem cross-adventures. A cópia antiga foi preservada; o projeto real foi cadastrado como favorito e ganhou atalhos “Jogar - Cross Adventures.lnk” e “Abrir no Godot.lnk”, ambos apontando a cross-adventures. Ver ABRIR_PROJETO_ATUAL.md.

Jardim, Galeria, Oficina e Santuário foram renderizados individualmente com o HUD compacto e confirmação de que a história some. A revisão também corrigiu a fonte dos rótulos elementais na Oficina e dos nomes dos personagens no cenário. O gerador foi mantido coerente com essas alterações.

## Limpeza de assets — 27/10/2026

A pedido explícito do usuário, foram arquivados fora da pasta do jogo 2.023 arquivos de assets sem referência, suas importações e caches órfãos. Permanecem 257 recursos usados e 32 arquivos de licença/origem. Os inventários anteriores descrevem o acervo histórico, não a lista atual de arquivos presentes. Originais, hashes e restauração estão registrados em LIMPEZA_ASSETS.md e LIMPEZA_ASSETS.json. Essa limpeza reduz tamanho/importação; não representa ganho garantido de RAM ou desempenho da partida.

## Revisão da primeira fase — 28/10/2026

O usuário pediu evoluir fase por fase usando o vídeo de Grand Krys’kajo (CrossCode) como referência visual/mecânica. Trechos foram analisados; não foi assistido integralmente. A primeira fase recebeu puzzle inicial na mesma sala, objetivo por etapas, baú interativo de cura única, prompts E/I, pedra/musgo, marcos de travessia e salto. Heróis têm aceleração curta, parada imediata, caminhada por deslocamento real e Otto atira em movimento. Interações respeitam altura e paredes; elevação e câmera ficaram mais suaves. Ver REVISAO_JARDIM_2026-10-28.md. O teste verificar_jardim tem 27 verificações de percurso por comandos e projéteis reais, com IA pausada para isolar navegação. As outras três cenas não foram regeneradas nem receberam essa revisão individual.

## Ambientação viva — 28/10/2026

A pedido do usuário, Jardim recebeu gotas/impactos, ondulações aleatórias e seis peixes submersos com rotas apenas na água; limites de partículas evitam crescimento de memória. A placa ganhou pedra/bronze e pressão animada, cristais e itens receberam acabamento, baú usa dez quadros nativos de abertura, plantas têm movimento discreto. Personagens têm respiração de um pixel só em repouso, sem mover pés/colisões. Zumbi e Cavaleiro patrulham devagar com pausas apenas na primeira fase, retomando combate ao detectar os heróis. Ver AMBIENTACAO_VIVA_2026-10-28.md e verificar_ambiente.gd (24 verificações), além das oito suítes anteriores aprovadas. Prévia é demonstração de ambientação com HUD oculto somente na captura.

## Estado atual: ponte, puzzle e cinco ricochetes — 28/10/2026

O usuário pediu explicitamente mais desafio e separação dos mecanismos. O limite anterior de quatro foi substituído por CINCO ricochetes para tiros simples/carregados em toda a campanha, inclusive previsão. No Jardim, a placa (4,18) e o cristal (9,18) ficam separados por uma mureta; Otto usa o EspelhoJardim (9,21) para um tiro refletido enquanto Lucas segura a placa. O acerto fica travado. A ponte sobe em três partes com som próprio e só libera a passagem após 1,8 s, por ponte_pronta. Esse desenho substitui a versão de tiro direto com mecanismos próximos. Ver PONTE_PUZZLE_2026-10-28.md. Dez suítes aprovadas; novo teste de ponte com 20 verificações e percurso do Jardim com 28.

## Decisão mais recente: cristal ao norte — 28/10/2026

O usuário pediu explicitamente o cristal na parte de cima, em sala separada da placa. Implementado: Lucas na placa inferior (4,18), Otto percorre o corredor até a sala norte e usa o espelho (9,8) para atingir o cristal (9,5), disparando da região (5,8). O acerto fica travado; Otto volta à ponte para atravessarem juntos. A mureta inferior foi removida e o cabo de energia segue o corredor. Baú, barril e rota do explorador foram afastados dos mecanismos superiores. Ver CRISTAL_NORTE_2026-10-28.md; substitui o layout anterior com mecanismos na mesma sala. Percurso real e câmera com os dois heróis em salas distintas foram verificados.

## Ajustes atuais de Otto — 02/11/2026

O usuário pediu explicitamente que somente a esfera carregada ricocheteie e que Otto não pare de andar ao disparar. Implementado: a esfera simples desaparece no primeiro contato com parede; a carregada mantém o limite de cinco contatos. A previsão da mira mostra o trajeto correspondente ao tipo de tiro. O ataque de Otto não zera mais a velocidade: um gancho `pode_mover_atacando()` na base mantém o movimento mesmo quando a cena sobrescreve o nome do personagem. Também permanecem implementados o dash no clique direito, os buracos sólidos na camada 7, queda com dano/renascimento e as cenas reutilizáveis LevelSpawn/Checkpoint. Validação: testes/verify_dash_respawn.gd (31), testes/verificar_combo_mira.gd (53), além de switch, signals e áudio.

A mira de Otto usa comprimento visual fixo, definido por `comprimento_maximo` (520 px). O cursor define somente o ângulo: a linha pode ultrapassá-lo quando perto ou não alcançá-lo quando longe. A previsão percorre paredes e ricochetes dentro desse orçamento fixo, parando na primeira parede para o tiro simples e mostrando os ricochetes da esfera carregada. O comprimento nunca ultrapassa o valor configurado; testes/verificar_combo_mira.gd cobre cursor perto/longe, parada simples e ricochete carregado.

## Ajustes atuais de Lucas — 02/11/2026

O usuário pediu que o combo não gerasse um golpe extra ao spammar e soltar o ataque e que o escudo mantivesse a orientação ao recuar. Implementado: cada golpe exige um comando; o buffer só aceita um novo comando depois que o golpe atual já saiu (fim do preparo), então toques repetidos antes disso são ignorados. O terceiro golpe também aceita buffer depois de sair e reinicia o combo, a pedido do usuário; o tempo dos golpes continua igual ao dos clipes. Com o escudo erguido, `defendendo` bloqueia a troca de direção no `Heroi` e no `PersonagemBase`; Lucas anda mais devagar, recua de costas e mantém `frente`/`direcao` para a defesa frontal. `verificar_combo_mira.gd` passou com 53 verificações, incluindo comandos antes do primeiro golpe, buffer no terceiro e escudo recuando. `verificar_personagens.gd` voltou a passar com os mapeamentos atuais de teclado.

## Canais compartilhados e FenceSet — 03/11/2026

O usuário relatou que cerca e interruptor no mesmo canal causavam `Invalid call. Nonexistent 'bool' constructor.` em area_1. `NonInteractable._interpret()` agora usa `match` por tipo e ignora `null`, vetores, arrays e outros valores sem conversão `bool()`; `area1.gd` também deixou de converter `btn.pressed` por `bool()`. O switch continua publicando o estado visual (`red`/`blue`/`gold`) e, em seguida, o booleano ligado/desligado no mesmo canal; `verify_switch.gd` foi alinhado a esse contrato.

Novo `FenceSet` (`scripts/objects/non-interactables/fence_set.gd` e `cenas/objects/non-interactable/fence_set.tscn`): um único canal/receiver no pai controla todas as cercas/paredes filhas, limpa os canais individuais dos filhos e repassa o estado por `definir_ativado()`, sem depender do `invert_receive` de cada parte. Os grupos `fence_set_1..4` de area_1 foram preservados para não alterar o layout em edição. Validação: `verify_signals.gd` (20, incluindo payloads inválidos, grupo por um canal e switch compartilhado), `verify_switch.gd` (19), `verificar_combo_mira.gd` (53), `verificar_personagens.gd`, `verify_dash_respawn.gd` (31) e boot headless.

Em `area_3`, o puzzle dos botões 2 e 3 agora usa `$objects/fence_set3` e chama `definir_ativado(true)` no `FenceSet`; o comportamento de exigir os dois botões simultaneamente e travá-los depois de abrir foi preservado. Boot headless e uma verificação direta da cena (três cercas abaixando juntas, colisões abrindo e botões em `single_use` pressionados) passaram.

## Torre de parede e projétil — 04/11/2026

Novo `wall_spitter` em `scripts/objects/non-interactables/wall_spitter.gd`, herdando de `NonInteractable`. Ele usa o `SignalReceiver` da cena e o `channel` exportado para ligar/desligar; começa desligado, salvo `start_activated`, e também aceita `definir_ativado()`/`definir_canal()`. Ao ligar, respeita o atraso inicial; ao desligar, para de disparar sem remover os projéteis já criados. Atira pelo `projectile_scene` exportado, com `shoot_interval` padrão de 1,0 s, direção exportada (padrão para baixo), distância da boca e velocidade/dano/empurrão configuráveis. A direção considera a rotação/escala do nó; o projétil nasce fora do corpo estático da torre.

Novo `wall_spitter_projectile.gd` com `ShapeCast2D` contínuo contra ambiente (camada 1) e hurtbox dos heróis (camada 4). Ele desaparece ao tocar parede ou personagem, aplica 6 de dano padrão e usa o `knockback_force` do próprio projétil (300 padrão) no sentido do disparo. Os overrides da torre usam sentinela `-1`: velocidade, dano ou empurrão só substituem o projétil quando configurados. A colisão com herói chama `receive_projectile_hit()` na base. O escudo frontal bloqueia dano e empurrão, toca efeito/som e consome o projétil; costas/laterais continuam causando dano e empurrão. `receber_dano()` mantém a checagem de escudo em `_blocks_hit_from()`/`_block_hit()`.

O empurrão agora impõe `tempo_empurrao` proporcional ao impulso; enquanto durar, o personagem ignora entrada de movimento, ataque, escudo, carga e dash. O deslocamento forçado ignora a camada de buracos e a queda interrompe imediatamente o empurrão/stun assim que o corpo cruza o buraco; o personagem sofre `dano_queda` e renasce no último piso seguro caminhado, não necessariamente no checkpoint. `LevelSpawn` inicializa esse ponto. Otto não grava piso seguro durante o dash. O `Checkpoint` passou a ser um `Node2D` com `Trigger` (`Area2D`) e `RespawnPoint` (`Marker2D`) separados; o gatilho pode ficar longe do ponto de renascimento. A câmera adia o snap para depois do `LevelSpawn`, evitando nascer na posição antiga dos heróis.

Nova camada física 8, `TerrenoInstavel` (`PhysicsLayers.UNSTABLE_GROUND`): objetos/chão nela não são usados como piso seguro nem como destino de renascimento. O `PersonagemBase` consulta a camada ao gravar `ultima_posicao_segura` e ao escolher o destino de `respawn`; se o ponto preferido estiver instável, tenta o último piso seguro e depois o ponto inicial do `LevelSpawn`. A camada não bloqueia movimento por si só; o objeto ainda precisa ter colisão física normal se for sólido.

Morte de herói agora agenda renascimento automático após `tempo_renascimento_morte` (1,0 s padrão), com vida cheia, no checkpoint mais recente. Cada `Checkpoint` mantém apenas um ativo: ao acionar outro, o anterior perde `is_active` e deixa de fornecer o ponto de renascimento. Reacionar um checkpoint antigo o torna novamente o ativo. Inimigos não renascem por esse fluxo.

## Plataforma móvel — 04/11/2026

`cenas/objects/non-interactable/moving_platform.tscn` agora usa `scripts/objects/non-interactables/moving_platform.gd`, herdando de `NonInteractable`. O nó `Platform` começa na `InactiveAnchor`; ao receber sinal ligado, percorre suavemente até `ActiveAnchor` com `move_speed` (96 px/s padrão), e volta ao desligar. Uma inversão no meio do caminho parte da posição atual, sem salto. `start_activated` faz a plataforma começar na âncora ativa. As duas `Marker2D` são independentes e ficam no espaço local do nó raiz, que não se move; apenas o filho `Platform` viaja.

O TileMapLayer mantém a camada física 8 (`TerrenoInstavel`), então o piso não é aceito como destino de renascimento. A plataforma não bloqueia os heróis pela máscara atual; uma `Area2D` dinâmica cobre o retângulo usado pelo TileMap e transporta os heróis sobrepostos pelo delta do movimento. `carry_riders` pode ser desligado.

A camada física 1 do TileSet de `area_3` não cria mais colisão própria: o novo `HoleField` (`cenas/objects/hazards/hole_field.tscn`, ligado a `Terrain map layer`) lê os polígonos dessa camada e cria um corpo estático fixo por célula inteira na camada 7. Cada plataforma registra o retângulo mundial do seu `TileMapLayer`; o `HoleField` desliga a colisão das células que intersectam esse retângulo e as reativa quando a plataforma sai. Uma célula parcialmente coberta também é desligada por inteiro, decisão deliberada para evitar recriar formas físicas a cada frame. A atualização só escreve `collision_layer` quando o estado da célula muda. A busca de células afetadas usa a transformação inversa do `TileMapLayer` para varrer apenas a vizinhança do retângulo, não as 656 células do mapa. Benchmark local de 10 mil atualizações em `area_3`: cerca de 60 µs por chamada, com os 656 corpos mantidos. Não existe mais `HoleSafeArea`, margem de embarque, troca de máscara por passageiro nem métodos de plataforma em `PersonagemBase`. `esta_sobre_buraco()` consulta os corpos ativos reais; `esta_sobre_buraco_bruto()` consulta o mapa original para não gravar piso seguro sobre um buraco encoberto. Se a plataforma revelar uma célula sob os pés de um herói, o `HoleField` chama `cair_no_buraco()` antes de reativar a colisão.

Validação: `testes/verify_moving_platform.gd` (29 verificações de herança, âncoras, camada instável, sinal, movimento suave, reversão, desligamento por célula inteira, passageiros e reexposição) e `testes/verify_hole_field.gd` (21 verificações de células inteiras, desligamento econômico, reutilização de corpos, consulta bruta, restauração e colisão real em area_3).

Validação: `testes/verify_wall_spitter.gd` (33 verificações de canal, projétil, força, stun, bloqueio e queda em buraco), `verify_dash_respawn` (31, incluindo piso seguro em vez de checkpoint), `verify_respawn_rules.gd` (27 de checkpoints exclusivos, morte, piso seguro e terreno instável), `verificar_camera_area` (9, snap após o spawn), `verificar_personagens`, `verificar_combo_mira` (53), `verify_switch` (19), `verify_signals` (20) e boot headless de area_3.

## Nova direção e renomeação dos jogadores — 04/11/2026

Decisão atual do usuário: o jogo passa a ser focado em puzzles, sem combate. Os personagens e sprites serão substituídos depois; por enquanto, os protagonistas foram renomeados para **Player1** e **Player2** em todo o código, cenas, recursos, controles, textos e testes. Os assets originais **não** foram renomeados nem apagados: pastas e arquivos como `GUERREIRO_*`, `ROBO` e `Robot*` continuam válidos em `assets/`.

Renomeações principais: `guerreiro.gd/.tscn/.tres` → `player1.*`; `robo.gd/.tscn/.tres` → `player2.*`; perfis de áudio equivalentes; ações de entrada `guerreiro_*`/`robo_*` → `player1_*`/`player2_*`; nós e rótulos `Guerreiro`/`Robo`/`Lucas`/`Otto` → `Player1`/`Player2`. O mapeamento atual de teclado foi preservado: Player1 usa WASD, F para atacar, G para defender, teclado numérico para salto/interação; Player2 usa setas, mouse para tiro/dash, Espaço e E. A busca por nomes antigos usa limites de palavra para não confundir `Otto` com `bottom`.

O `HoleField` de `area_3` agora usa um corpo estático por célula inteira e só altera `collision_layer` quando o estado muda. A cena declara `node_paths=PackedStringArray("tile_map_layer")`, corrigindo o vínculo real com `Terrain map layer`. Benchmark de 10 mil atualizações: cerca de 60 µs por chamada, mantendo 656 corpos.

Validação após a renomeação: `verificar_personagens` (4 cenas, 80 animações, teclas reais e controles simultâneos), `verificar_audio`, `verificar_combo_mira` (53), `verify_dash_respawn` (31), `verificar_camera_area` (9), `verify_respawn_rules` (27), `verify_wall_spitter` (33), `verify_hole_field` (21), `verify_moving_platform` (29) e boot headless de `area_3` passaram. `verificar_jardim` e `verificar_ponte` continuam bloqueados pela ausência preexistente de `cenas/fases/` e `cenas/interface/menu.tscn`.

## Estado explícito de Fence — 05/11/2026

`Fence` agora usa `STATE {CLOSED, CLOSING, OPEN, OPENING}` como única fonte de verdade, substituindo `_lowered`, `_target_lowered` e `_animating`. O estado terminal sincroniza animação e colisão; durante `OPENING` a passagem continua bloqueada e durante `CLOSING` continua liberada até terminar. Reativar um estado já alcançado não reinicia a animação e apenas corrige eventual dessincronia de visual/colisão. Um token de animação descarta callbacks antigos quando o sentido é invertido no meio do movimento. `FenceSet` continua aplicando o mesmo estado às partes. Validação: `testes/verify_signals.gd` com 36 verificações, incluindo `start_activated`, reativação sem replay e reversão no meio da animação; `verify_switch` (19), `verify_hole_field` (21), `verify_moving_platform` (29) e boot de `area_3` também passaram.

## Fim de fase — 05/11/2026

`cenas/objects/level_specifics/level_end.tscn` recebeu `scripts/objects/level_specifics/level_end.gd`. A área detecta heróis pelo grupo `herois` e só inicia quando todos os jogadores existentes estão sobrepostos ao mesmo tempo. Ao iniciar, desliga `controlado`, processamento de física, defesa, ataque, carga e dash dos dois, guarda a direção `frente` de cada um, move manualmente nessa direção por `tempo_caminhada` (1,0 s padrão) e, no mesmo instante, emite `saida_iniciada` e chama `FluxoTela.trocar(proxima_cena)`. A caminhada e o fade começam juntos; `LevelEnd` e os jogadores usam `PROCESS_MODE_ALWAYS` para continuar andando durante a pausa do FluxoTela. `proxima_cena` é exportada; o padrão atual é `res://cenas/screens/start_menu.tscn`. Se o caminho ficar vazio, a caminhada roda até o fim sem transição. Validação: `testes/verificar_fim_fase.gd` (15 verificações de sobreposição dupla, bloqueio de controles, caminhada simultânea ao fade, carregamento real da próxima cena pelo FluxoTela e retomada da árvore) e boot de `area_3`.
