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

Otto agora usa projéteis. Clique curto gera esfera simples; segurar por 0,85 s e soltar gera esfera maior. Ambas ricocheteiam em paredes e apagam no quarto contato, ou ao atingir um inimigo. Mira, carga, disparo, dano e ricochete têm efeitos visuais/sonoros. Os tiros não causam dano nos aliados. Detalhes em documentacao/COMBO_MIRA_PROJETEIS.md.

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
