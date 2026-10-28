# Atualização de 27/10/2026

Revisão dos cenários e da interface, consolidando as quatro fases jogáveis de Cross Adventures.

## Cenários e jogabilidade

- Quatro mapas de masmorra com salas e corredores conectados, TileMapLayers editáveis, atlas CraftPix, iluminação e tochas animadas.
- Água animada com profundidade e sombras nas margens; corrigidos os recortes, a escala e a posição de baús, barris, caixas e urnas.
- Campanha com alturas lógicas, rampas, saltos, placas cooperativas, pontes, elementos, plataformas móveis, chefe, portais e transições.
- Rotas dos inimigos seguem o chão e os obstáculos; previsão de mira e projéteis refletem com a mesma normal dos espelhos.
- Preservados os controles simultâneos, combo de Lucas, escudo frontal, armadura caída e tiros simples/carregados de Otto com quatro ricochetes.

## Interface e áudio

- Menu, pausa, guia e HUD compartilham fonte Tiny5, molduras e paleta pixel; licença da fonte incluída.
- HUD reduzido para mostrar mais do mapa; cartões compactos de vida, fase e objetivo.
- História e dicas com escrita progressiva, som de digitação, paginação e desaparecimento após leitura.
- Sons de interface integrados ao controle de áudio; guia pausa a partida e as transições bloqueiam comandos durante a animação.

## Organização

- 2.023 arquivos de assets sem uso retirados da pasta do projeto, além de importações associadas e caches órfãos: 25.759.607 bytes retirados localmente.
- Mantidos 257 recursos utilizados e 32 arquivos de licença/origem; assets de origem passaram de 15,43 MB para 1,21 MB.
- Originais arquivados fora do repositório local com manifesto, hashes e recuperação. Isso reduz tamanho/importação e não implica ganho garantido de RAM durante a partida.
- Backups, cache do Godot e atalhos locais não entram no Git. O projeto correto foi documentado para evitar abrir a cópia antiga MeuJogo.
- Gerador de fases, inventários históricos, controles, soluções e contexto atual documentados.

## Validação

Importação pelo Godot 4.7.1 sem erros e sete testes aprovados:

- Personagens: quatro cenas e 80 animações.
- Áudio: perfis, clipes, passos, combate, defesa, morte e silêncio.
- Combo e mira: 46 verificações.
- Fases: 75 verificações.
- Interface: 61 verificações.
- Cenários: 87 verificações.
- Acabamento: 163 verificações.

As quatro fases foram renderizadas e inspecionadas após a limpeza, sem texturas ausentes.

Continuam pendentes: gamepad para Lucas, músicas e arte exclusiva do chefe.
