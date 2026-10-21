# Base de personagens RPG — Godot 4

Abra `project.godot` e pressione **F5**. A cena principal é `cenas/testes/arena_teste.tscn`. É uma arena de teste para os personagens, sem campanha ou mapa definitivo.

## Controles

- WASD ou setas: mover em oito direções, com animações em quatro direções.
- Espaço ou J: atacar na direção para a qual o personagem está olhando.
- Tab: alternar Guerreiro e Robô. O companheiro acompanha e ataca inimigos próximos.
- R: reiniciar a arena, restaurando personagens e inimigos.

## Cenas prontas

- `cenas/personagens/guerreiro.tscn`: protagonista com espada, mais dano e defesa.
- `cenas/personagens/robo.tscn`: protagonista mais rápido, ataque corpo a corpo.
- `cenas/personagens/cavaleiro_azul.tscn`: vilão resistente que persegue e ataca.
- `cenas/personagens/zumbi.tscn`: vilão mais lento que persegue e ataca.

Arraste essas cenas para um mapa para reutilizar os personagens. Para controlar um herói fora da arena, marque **Controlado** no Inspetor; apenas um herói deve receber comandos por vez. A troca de protagonista e a atribuição do líder são feitas pelo script da arena.

## Nós de cada personagem

`CharacterBody2D` é a raiz. `Visual/AnimatedSprite2D` contém as animações editáveis; `CollisionShape2D` representa os pés; `AreaDano` recebe golpes; `PivoAtaque/AreaAtaque` detecta alvos à frente; `EfeitoGolpe` sinaliza o ataque. Há timers de preparo, recarga e invulnerabilidade, além de nome e barra de vida.

Os atributos **Vida maxima**, **Velocidade**, **Dano ataque**, **Defesa**, **Alcance ataque**, **Intervalo ataque** e os parâmetros de IA ficam no Inspetor da raiz. A vida atual é inicializada ao executar a cena. Para ampliar o alcance, ajuste também o raio da forma da AreaAtaque.

## Scripts

- `scripts/personagens/personagem_base.gd`: vida, defesa, dano, recarga, invulnerabilidade, morte, direção e animações.
- `scripts/personagens/heroi.gd`: controles e comportamento do companheiro.
- `scripts/personagens/vilao.gd`: detecção, perseguição, retorno e ataque.
- `scripts/arena_teste.gd`: troca de heróis, interface e reinício da demonstração.

Camadas físicas: 1 cenário, 2 heróis, 3 vilões, 4 área de dano dos heróis, 5 área de dano dos vilões. As áreas de ataque consultam apenas a equipe adversária. Não há fogo amigo. O dano mínimo após defesa é 1; a invulnerabilidade temporária evita múltiplos acertos no mesmo golpe.

## Animações e limitações dos assets

Guerreiro e Robô são os dois protagonistas completos encontrados. `GUERREIRO_CORPO` é a variante modular do Guerreiro. Os dois grupos de vilões são Cavaleiros e Zumbis; foram usados Cavaleiro Azul e Zumbi. A variante verde continua disponível nos assets.

As animações estão em `recursos/personagens/*.tres`, referenciando os PNGs originais. Não foram alteradas as imagens de origem. As imagens têm tamanhos diferentes; escala e deslocamento foram ajustados para manter os pés próximos da colisão.

O Guerreiro não possui idle lateral dedicado: usa um quadro de caminhada para ficar parado lateralmente. Cavaleiro e Zumbi não possuem animações de ataque nesses arquivos: o ataque usa pose disponível e efeito de golpe. Robô e Cavaleiro não possuem morte dedicada: usam pose disponível e transparência. O Zumbi possui animação de morte; seus quadros brancos de dano foram evitados como animação normal. O Robô usa ataque corpo a corpo nesta base, sem projéteis.

Esta base não inclui inventário, níveis, experiência, salvamento ou navegação com obstáculos. A perseguição é direta; para mapas com paredes internas, acrescente navegação. As licenças dos assets permanecem em `assets/DOCUMENTACAO`.

O arquivo de configuração anterior e quaisquer arquivos substituídos ficam preservados em `backups/` com data e hora.
