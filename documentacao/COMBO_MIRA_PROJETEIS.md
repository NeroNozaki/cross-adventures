# Combos, mira e projéteis — Cross Adventures

Abra o projeto no Godot e pressione F5.

| Personagem | Movimento | Ataque | Utilidade |
|---|---|---|---|
| Lucas | WASD | Clique direito, Espaço ou J | Shift: escudo |
| Otto | Setas | Clique esquerdo ou Enter; segure e solte para carregar | Mouse: mira 360° |

R reinicia e M alterna os efeitos sonoros. Os dois continuam independentes e podem agir ao mesmo tempo.

## Combo de Lucas

Cada comando de ataque avança entre corte, corte de retorno e estocada. Os três têm clipes e efeitos diferentes nas quatro direções. A estocada causa mais dano. Uma pausa de 1,1 s desde o último golpe reinicia a sequência. Segurar o botão não repete o combo.

Um comando antecipado pode aguardar o fim do golpe atual; não é criada uma fila ilimitada. Defender, sofrer dano ou morrer cancela o comando pendente. As animações usam os quadros originais dos assets, sem o giro lateral que apontava a espada para o lado contrário.

## Mira e disparos de Otto

A linha e a marca de mira acompanham a posição do mouse em qualquer ângulo. A movimentação não altera o ângulo do disparo. O corpo usa as quatro direções dos sprites existentes; o emissor e a mira giram livremente.

Clique e solte para disparar uma esfera simples. Segure por pelo menos 0,85 s e solte para disparar a esfera maior. O anel ao redor do robô mostra o carregamento e fica dourado quando pronto. O tiro maior tem raio 9 e dano 38; o simples tem raio 4 e dano 18, antes da defesa do inimigo. Os valores ficam editáveis nos scripts/cenas.

As duas esferas ricocheteiam no cenário e apagam no quinto contato com parede. Ao acertar um inimigo, causam dano e desaparecem. Elas atravessam os protagonistas sem causar fogo amigo e não empurram os personagens. Em um mapa sem paredes, o limite de vida de 12 s evita esferas acumuladas indefinidamente.

A carga é cancelada ao sofrer dano, morrer, perder o foco da janela ou desabilitar o controle. Ao morrer, os tiros daquele robô são removidos. Soltar o botão depois de uma carga cancelada não cria um tiro.

## Interações verificadas

- Os protagonistas não bloqueiam a passagem um do outro.
- Espada e perseguição não atravessam paredes.
- Sofrer dano interrompe o preparo de um ataque, evitando acertos depois da interrupção.
- A colisão circular contínua impede tiros rápidos de atravessar paredes finas.
- A origem dos disparos tem margem de segurança para não nascer dentro da parede.
- Quinas e contatos repetidos com a mesma superfície não consomem cinco ricochetes de uma vez.
- A mira é ocultada na morte e o carregamento não permanece ativo ao perder o foco.
- Escudo, áudio, vida, IA e morte com armadura caída continuam funcionando.

Os casos acima têm testes em testes/verificar_combo_mira.gd, além das verificações de personagens e áudio já existentes.

## Organização

scripts/personagens/guerreiro.gd: combo e comando antecipado. scripts/personagens/robo.gd: mira, carga e disparo. scripts/combate/mira_360.gd: marcação do ângulo. cenas/combate/projetil.tscn e seu script: esfera, dano e ricochetes. cenas/combate/impacto_projetil.tscn: efeito e som de contato.

O restante do SGDD continua como referência em documentacao/CONTEXTO_DO_JOGO.md. Gamepad para Lucas, fases e puzzles seguem pendentes.
