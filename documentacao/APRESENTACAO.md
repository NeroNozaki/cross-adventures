# Apresentação de Cross Adventures

> Cross Adventures é um jogo cooperativo para duas pessoas. Nico usa golpe e escudo. Otto mira e dispara esferas de energia. Em cada sala eles precisam combinar o que sabem fazer, e a amizade fica mais forte quando encontram a saída juntos.

## Demonstração de dois minutos

1. No menu, mostre a capa dos personagens e abra **Como jogar**. Explique que cada jogador controla um personagem ao mesmo tempo.
2. Selecione **Jogar**. Mostre a abertura e o primeiro diálogo. Use **Continuar** ou **Pular tudo** como faria uma criança.
3. Na primeira fase, use Nico em uma placa e peça que a outra pessoa mire e dispare com Otto. Mostre a resposta visual e sonora de uma grade ou de um cristal.
4. Mostre a amizade no HUD, abra o guia com **F1** e explique que a fase termina quando os dois chegam à saída. As fases seguintes introduzem plataformas móveis e corredores com armadilhas.

## Onde está cada parte

| Se a professora perguntar… | Abra no Godot ou no código |
| --- | --- |
| Onde começa o jogo? | [Configuração do projeto](../project.godot), [cena do menu](../cenas/screens/start_menu.tscn) e [código do menu](../scripts/screens/start_menu.gd). |
| Como a capa se mexe? | [Shader da capa](../recursos/capa_masmorra.gdshader). As áreas dos personagens, da água e da luz se movem em ritmos próprios. |
| Onde ficam as fases? | [Celas](../cenas/areas/area_1.tscn), [Galeria](../cenas/areas/area_2.tscn), [Saída](../cenas/areas/area_3.tscn). [BaseArea](../scripts/areas/base_area.gd) instala o HUD, a ambientação e a história em cada cena. |
| Como um cristal abre uma grade? | [Receptor](../scripts/objects/interactables/switch.gd), [placa](../scripts/objects/interactables/button.gd), [barramento](../scripts/signals/signal_bus.gd) e [combinação de condições](../scripts/signals/signal_gate.gd). |
| Onde ficam os controles e a esfera? | [Nico](../scripts/personagens/player1.gd), [Otto](../scripts/personagens/player2.gd), [mira](../scripts/combate/mira_360.gd), [projétil](../scripts/combate/projetil.gd) e os comandos em [project.godot](../project.godot). |
| Onde estão os diálogos e a amizade? | [Texto das falas](../recursos/historia_dupla.gd), [apresentação e progresso](../scripts/screens/historia_dupla.gd) e [gatilho da saída](../scripts/objects/level_specifics/level_end.gd). |
| Onde ajusto os botões e a interface? | [Tema](../scripts/screens/tema_masmorra.gd), [guia](../scripts/screens/guia_masmorra.gd), [HUD](../scripts/areas/hud_campanha.gd) e [fonte Cross Inscrição](../assets/INTERFACE/FONTES/). |
| Onde coloco uma tocha ou uma estátua? | [Posições por fase](../recursos/decoracao_areas.gd), [validação e desenho da alvenaria](../scripts/areas/decoracao_masmorra.gd) e [atlas das peças](../assets/mapa/CRAFTPIX_DUNGEON/talha_masmorra.svg). |
| Onde ficam a iluminação e o áudio? | [Acabamento da sala](../scripts/areas/acabamento_masmorra.gd), [música e efeitos de ambiente](../scripts/audio/ambiente_masmorra.gd) e [trilhas da galeria e da saída](../assets/SONS/AMBIENTE/MASMORRA/). |
| Como a passagem de fase funciona? | [Gatilho da saída](../scripts/objects/level_specifics/level_end.gd), [transição](../scripts/screens/fluxo_tela.gd) e [cena de encerramento](../cenas/screens/fim_aventura.tscn). |

## Como explicar um puzzle

Uma placa ou um receptor avisa que mudou pelo **SignalBus**. A grade escuta o canal configurado na cena. Quando o desafio exige mais de um objeto, o **SignalGate** só envia o sinal de saída quando todas as condições estão satisfeitas. O acabamento acompanha esse estado para atualizar a gema, a luz e o som.

## O que evoluiu nesta versão

- Os três mapas da `main` foram ligados ao fluxo de abertura, diálogos, encerramento e cooperação entre Nico e Otto.
- A interface ganhou guia ilustrado, fonte própria, sinais sonoros e um HUD compacto que deixa o mapa visível.
- A ambientação ganhou arandelas apoiadas na alvenaria, estátuas em nichos, pedras desgastadas, sombras e trilhos baseados nas posições reais das plataformas.
- Os cristais ganharam pedestais e cores de estado. O áudio sincroniza gotas com respingos e grades com seus movimentos. A Galeria e o Caminho da saída têm trilhas próprias.
