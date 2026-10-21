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

- Projeto em `C:\Users\finan\OneDrive\Documentos\MeuJogo`, usando Godot 4.7.1 e os assets copiados da Área de Trabalho.
- Visão de cima e combate em tempo real.
- Dois personagens controláveis de forma independente e simultânea. Na arena atual: Lucas (cena Guerreiro) no WASD, clique direito/Espaço/J para combo e Shift para escudo; Otto (cena Robô) nas setas, mouse para mira 360° e clique esquerdo/Enter para tiro; segurar e soltar carrega uma esfera maior. R reinicia.
- O personagem sem comandos fica parado, sem seguir ou atacar pelo outro.
- Escudo bloqueia o cone frontal, com faíscas de impacto; não protege as costas. A defesa reduz a velocidade e impede atacar simultaneamente.
- Ataques laterais do Guerreiro foram corrigidos para estocadas na direção comandada, sem o giro que levava a espada para o lado contrário.
- Cavaleiro deixa elmo, peitoral e botas caídos no ponto da morte, sem bloquear passagem.
- Inimigos atuais: Cavaleiro Azul e Zumbi. São os dois vilões montados a partir dos assets disponíveis; o chefe ainda não foi feito.
- Efeitos sonoros são integrados nesta etapa para os quatro personagens, com perfis separados. M alterna o som dos efeitos.

## Estado de implementação e diferenças para o SGDD

Implementado: quatro cenas reutilizáveis, animações, colisões, combate corpo a corpo, vida, defesa, dano, invulnerabilidade temporária, morte, barras de vida, IA direta de perseguição/ataque, escudo, armadura caída, controles simultâneos e arena de teste. Também implementados: combo de três golpes de Lucas, mira 360° de Otto, tiro simples e carregado, colisão contínua e quatro ricochetes.

Áudio desta etapa: passos por deslocamento real, ataque, acerto confirmado, dano e morte dos quatro personagens; equipar/erguer escudo e bloqueio frontal de Lucas; som metálico da armadura sincronizado com a queda. As cenas usam o componente AudioPersonagem e os perfis em recursos/audio. O mapa dos arquivos está em documentacao/MAPA_DE_SONS.json.

Otto agora usa projéteis. Clique curto gera esfera simples; segurar por 0,85 s e soltar gera esfera maior. Ambas ricocheteiam em paredes e apagam no quarto contato, ou ao atingir um inimigo. Mira, carga, disparo, dano e ricochete têm efeitos visuais/sonoros. Os tiros não causam dano nos aliados. Detalhes em documentacao/COMBO_MIRA_PROJETEIS.md.

O controle de gamepad para Lucas ainda NÃO foi implementado. Otto já usa teclado independente e mira pelo mouse. A utilidade final de Otto, além da ação de ataque carregado solicitada nesta etapa, continua sem definição no SGDD.

Ainda pendentes: quatro fases, puzzles, salto por vãos, menu, pausa, respawn, transições, tela final, chefe e músicas. O SGDD não especifica inventário, experiência ou progressão de níveis; não presumir esses sistemas apenas pela referência anterior a RPG.

Os efeitos usam arquivos existentes nos assets; não foram criadas vozes, falas ou músicas novas. As licenças permanecem em assets/DOCUMENTACAO.

## Como continuar

Usar esta referência e o SGDD para orientar novas solicitações. Decisões explícitas posteriores do usuário têm prioridade sobre este resumo. Registrar mudanças de design e manter o estado real separado do conteúdo planejado. Não anunciar um item do backlog como pronto sem implementação e verificação.

Abra project.godot no Godot e pressione F5. Verificação de jogabilidade: testes/verificar_personagens.gd. Verificação de áudio: testes/verificar_audio.gd. Combo, mira e interações: testes/verificar_combo_mira.gd.
