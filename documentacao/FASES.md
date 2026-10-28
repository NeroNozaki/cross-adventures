# Cross Adventures — quatro fases

Cenários originais com o pacote oficial gratuito CraftPix Free 2D Top-Down Pixel Dungeon, complementado pelos assets existentes. Mantêm Lucas, Otto, a Provação do Herói, o cooperativo local, a visão de cima e o combate em tempo real do SGDD. Os princípios de altura, reflexão e puzzles enviados pelo usuário orientam as mecânicas; não foram copiados mapas ou artes de CrossCode.

## Jogar

Abra project.godot no Godot 4.7.1 e pressione F5. A cena inicial agora é cenas/interface/menu.tscn. Escolha INICIAR AVENTURA para entrar no Jardim. F1 mostra os controles e pausa a partida enquanto o guia estiver aberto. V alterna a visão geral do mapa; a câmera normal acompanha os dois heróis. A arena de testes anterior permanece em cenas/testes/arena_teste.tscn.

| Ação | Lucas / Guerreiro | Otto / Robô |
|---|---|---|
| Mover | WASD | Setas |
| Atacar | Espaço, J ou clique direito: combo de 3 golpes | Mouse para mirar; clique esquerdo ou Enter para disparar |
| Utilidade | Shift: escudo frontal | Segurar o disparo por 0,85 s e soltar: esfera carregada |
| Saltar | F com direção, ou direção atual | P com direção, ou direção da mira |
| Interagir | E: placas, fontes e empurrar blocos | I: placas e fontes |

C alterna Normal, Fogo, Gelo, Choque e Onda nas fases 3 e 4. Tab trava/destrava o ângulo da mira. M alterna efeitos sonoros. R reinicia a sala atual; na conclusão final, volta à primeira fase. Os dois personagens continuam independentes e simultâneos.

## 1. Jardim da Provação — cooperação entre salas

Lucas mantém a placa dourada na sala inferior. Otto sobe pelo corredor até a sala ao norte, se posiciona na marca abaixo à esquerda do espelho e dispara para a direita. O espelho diagonal reflete a esfera para cima, até o cristal da sala superior. Tab permite examinar a trajetória. O cristal exige pelo menos um ricochete e Lucas na placa no momento do impacto.

O acerto destrava a ponte definitivamente. Lucas pode sair da placa e Otto retorna pelo corredor. Aguardem as três partes encaixarem (1,8 s, com som de mecanismo), atravessem juntos, derrotem os guardas e sigam para a escada e o salto até a porta. A câmera acompanha a equipe mesmo durante a separação entre salas.

O baú opcional fica no canto inferior esquerdo da sala norte, separado do espelho e do cristal. E/I abre e recupera até 30 de vida de cada herói vivo, uma única vez. A antiga mureta inferior foi retirada para facilitar a circulação.

## 2. Galeria dos Ecos — desenvolver

Galeria de pedra com uma parede central, espelho diagonal e receptor R. Lucas fica na placa dourada da parte inferior esquerda. Otto contorna a parede por baixo e atira da esquerda do espelho para refletir a esfera para cima, até o receptor. A previsão pontilhada mostra as próximas reflexões. A grade abre após a ativação; derrotem os guardas e avancem juntos.

O receptor exige pelo menos um ricochete, além da placa de Lucas. Um tiro direto não resolve o puzzle. O portal está no terraço superior direito, depois da grade.

## 3. Oficina das Quatro Fontes — misturar

Oficina de pedra com seis salas, canais de água, estações elementais e plataforma móvel.

1. Selecione Gelo e atire no bloco azul de água. Lucas fica à esquerda, olha para a direita e usa E duas vezes, acompanhando o bloco, até a placa quadrada.
2. Use Fogo na barreira de gelo central.
3. Use Choque em um tiro refletido pelo espelho diagonal até o condutor R acima dele.
4. Use Onda para dissipar a bolha azul à direita.
5. Derrotem o Zumbi. Subam a escada à esquerda do vão inferior e atravessem na plataforma móvel, um de cada vez se desejarem. O portal está no terraço direito.

As fontes coloridas também selecionam um elemento ao interagir. C permite alternar sem retornar às fontes.

## 4. Santuário do Guardião — testar

Sala final com dois níveis de terraços e três selos que protegem o Guardião da Provação.

- Congele o bloco de água da parte inferior esquerda e empurre-o duas casas para a direita, sobre a placa quadrada. Se uma planta bloquear o acesso, corte-a.
- Mantenha Lucas sobre a outra placa e faça Otto atingir o receptor R superior com um ricochete no espelho. O barril diante do espelho pode ser destruído.
- Suba Otto pela escada da direita até o primeiro terraço. Use uma esfera CARREGADA de Choque no núcleo C, na mesma altura.

Os três selos removem a proteção do chefe. Ele persegue os heróis e anuncia um pulso circular antes de causar dano: recuem ou saltem. Depois de derrotá-lo, subam a segunda escada e reúnam os dois no portal mais alto. A conclusão concede a Medalha da Equipe, uma recompensa definida para esta implementação.

## Regras dos cenários

- Cada posição do chão tem altura lógica Z. Andar para o vazio ou atravessar uma borda de altura diferente é bloqueado; escadas mudam o nível. Saltos têm alcance de 64 pixels e aceitam apenas pousos na mesma altura, sem atravessar paredes.
- Ataques, projéteis e colisões entre personagens respeitam a altura. As paredes externas refletem em qualquer nível. As esferas desaparecem no quinto contato com paredes; receptores e obstáculos elementais podem consumi-las antes disso.
- Água congela em um bloco que Lucas pode empurrar. Fogo derrete gelo. Choque aciona condutores. Onda dissipa bolhas. Objetos mudam sua colisão durante a partida.
- Plantas e barris quebram com espada ou tiros, espalhando fragmentos e liberando passagem. Os fragmentos não interceptam projéteis.
- Exploradores percorrem rotas ambientais e têm um pequeno salto visual. São NPCs de ambientação, sem combate ou diálogo.
- O personagem derrotado reaparece no início da sala após três segundos, com vida restaurada. O estado dos mecanismos permanece enquanto a sala estiver carregada. R reinicia tudo na sala; não há save permanente nesta etapa.
- O portal só aceita a equipe completa, viva, no mesmo nível, depois dos objetivos e inimigos da sala. A troca para a próxima fase é automática.

## Editar e verificar

As quatro cenas ficam em cenas/fases, com TileMapLayers SoloZ0, SoloZ1 e SoloZ2, objetos de puzzle, personagens, exploradores e câmera compartilhada. O TileSet comum está em recursos/fases/tileset_cross.tres. Os objetos possuem configuração exportada e nós de colisão editáveis.

Os JSONs em recursos/fases são a fonte da geração inicial. ferramentas/reconstruir_fases.gd reconstrói cenas e tiles a partir deles e preserva versões anteriores em backups. Essa reconstrução substitui edições manuais nas cenas geradas; use apenas quando desejar regenerá-las. Alterar só o JSON não atualiza automaticamente os tiles visuais da cena.

Validação: testes/verificar_fases.gd cobre altura, saltos, cooperação, tiros reais nos espelhos, elementos, empurrões, transporte, chefe, portais, respawn e transições. testes/verificar_cenarios.gd verifica apoio no chão, colisões de entrada, rotas de inimigos e enquadramento da equipe nas quatro fases. Os testes anteriores de personagens, áudio e combo/mira permanecem obrigatórios para mudanças nesses sistemas.

Os assets originais e suas licenças foram mantidos. Menu principal e pausa com Esc já foram integrados. Ainda ficam para outras etapas: músicas, suporte ao gamepad de Lucas e arte exclusiva para o chefe; o Guardião atual reaproveita o Cavaleiro Azul com escala e comportamento próprios.

A reformulação usa assets/mapa como base visual. A previsão completa de ricochetes aparece ao carregar ou travar a mira com Tab. Esc pausa a partida e oferece Continuar, Reiniciar sala e Menu principal.

Interface: fonte pixel Tiny5 com acentos, entrada dos painéis, avisos progressivos e transições em blocos. Ver documentacao/INTERFACE_PIXEL.md. M controla também os sons de interface.
