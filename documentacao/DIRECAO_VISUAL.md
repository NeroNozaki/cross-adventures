# Direção visual — Cross Adventures

Projeto real: C:\Users\finan\OneDrive\Documentos\cross-adventures. Revisão de 27/10/2026, após as referências de masmorras enviadas pelo usuário.

## Base de arte

A base atual dos cenários é o pacote oficial gratuito CraftPix Free 2D Top-Down Pixel Dungeon, correspondente à primeira imagem de referência: https://free-game-assets.itch.io/free-2d-top-down-pixel-dungeon-asset-pack . Origem e licença estão em assets/mapa/CRAFTPIX_DUNGEON/FONTE.md e license.txt. A referência azul de gelo é um produto pago diferente, sem arquivos adquiridos nesta etapa.

Foram usados os spritesheets de Tiled_files: walls_floor 272×464, Objects 384×144, portas 160×240, água 464×512 e animações de fogo/ondas. Os arquivos homônimos da pasta PNG possuem layouts diferentes; não substituí-los sem ajustar os recortes.

Os 523 arquivos previamente fornecidos em assets/mapa permanecem intactos e catalogados em documentacao/INVENTARIO_MAPA.json: 0x72 (249), 2D Pixel Dungeon v2 (184), Dungeon assets pack (26) e ícones de mapa (64). O primeiro conjunto ainda fornece o explorador ambiental; os demais ficam disponíveis. Lucas, Otto, Cavaleiro e Zumbi preservam seus sprites e animações anteriores.

## Composição

Quatro mapas originais de 38×26 células, com salas ligadas por corredores, paredes de pedra de duas peças, bordas, escadas, nichos e decoração junto às paredes. Os pisos usam as peças de piso do pacote, com variação de ladrilhos. Vãos e terraços mantêm altura lógica e colisão. A água animada separa espaços e define os percursos; não é chão caminhável.

Jardim: cinco setores de ruínas em torno de um reservatório, ligação cooperativa por ponte e terraço final com salto. Galeria: cinco salas com placas, espelho, receptor e acesso por grade. Oficina: seis salas, fontes elementais e travessia por plataforma móvel. Santuário: alas de selos, salão de combate e torre com dois níveis elevados. Nomes e funções preservam a campanha do SGDD.

Tochas animadas de seis quadros usam PointLight2D e luz ambiente fria discreta. Arcos e tochas só são colocados quando existe apoio de parede. Tesouros, urnas, caixas e detritos compõem as margens; caminhos essenciais e linhas dos puzzles devem ficar livres.

## Câmera e interface

A câmera acompanha os dois protagonistas e ajusta o zoom. V alterna uma visão geral da fase, útil para localizar salas e objetivos. HUD com vida dos dois heróis, objetivo e contador de mecanismos; F1 abre o guia. Esc pausa de verdade e oferece Continuar, Reiniciar sala e Menu principal. A mira mostra o primeiro trecho em repouso; carregar ou travar com Tab revela os ricochetes seguintes.

## Edição e validação

Cenas em cenas/fases/*.tscn; TileSet em recursos/fases/tileset_cross.tres; dados em recursos/fases/*.json; gerador ferramentas/reconstruir_fases.gd. Os dados incluem salas, água, chão e altura, colisões, mecanismos e posições. Alterar somente o JSON não atualiza os tiles salvos; regenerar substitui edições manuais nas cenas e preserva backups.

Validação: verificar_personagens, verificar_audio, verificar_combo_mira, verificar_fases, verificar_interface e verificar_cenarios. O último cobre apoio dos mecanismos, entradas sem sobreposição, rotas da IA e câmera nas quatro fases. A revisão visual usa capturas renderizadas pelo Godot; testes funcionais não substituem a avaliação estética do usuário.

## Correção de itens e água — 27/10/2026

O usuário apontou itens cortados e água artificial. Os recortes anteriores estavam errados: por exemplo, a região de um barril incluía parte de um baú. Os itens agora usam recortes inteiros do atlas Tiled, com escala 2× e pés alinhados ao chão: baú (144,16,32,16), barril (192,80,16,16), caixa (80,80,16,16) e urna (208,80,16,16). As regiões são x,y,largura,altura em pixels da imagem Objects.png. Decoração adicional fica a pelo menos duas células dos itens interativos, entradas e inimigos; rampas e rotas ambientais também são respeitadas.

Placas, sinais, plantas e pedestais receberam desenho em pixels inteiros, sombras e volumes. Cristais têm faces claras/escuras. Portas preservam a proporção do atlas, sem achatamento. As plantas continuam destrutíveis. Baús e urnas decorativos não ganharam sistema de inventário ou saque.

A água usa água_cenario (arquivo sem acento: scripts/visual/agua_cenario.gd) e agua_profundidade.gdshader: campo de distância das margens, centro mais profundo, sombras de contato, reflexos discretos, bordas animadas e capeamento de pedra no encontro com o vazio. O efeito é pixel art, com variação suave de profundidade. As ondas originais vêm de water_details_animation.png em seis quadros de 592×208; não usar tiras arbitrárias de water_detilazation_v2. A superfície recua quando a ponte abre, preservando a travessia.

Validação adicional: testes/verificar_acabamento.gd, com 163 verificações de cobertura da água, perfil de profundidade, atualização da ponte, limites dos recortes, escala inteira e separação da decoração. Também passaram verificar_fases (75), verificar_cenarios (87) e verificar_combo_mira (46), além da renderização das quatro fases no Godot.

## HUD e menus em pixel art

A revisão atual da interface está em documentacao/INTERFACE_PIXEL.md: Tiny5 sem suavização em tamanhos múltiplos de 8, moldura própria em grade, retratos, barra segmentada, estados reais e avisos com altura adaptativa. Menu, guia, pausa e conclusão compartilham o tema. F1 pausa durante o guia. As transições em blocos e os sete sons Kenney são integrados por autoloads; M controla também a UI. O teste de interface agora possui 55 verificações.

### Ajuste posterior: HUD compacto

O HUD da partida usa fonte 8 px e retratos de 16×16; cartões de vida de 122×36 e identificação de fase de 164×36. O objetivo ocupa uma faixa baixa de 24 px com largura variável. Avisos/história têm no máximo três linhas e 44 px de altura, escrita sonora e desaparecimento após leitura. A caixa de dica não permanece e não há faixa grande no centro na entrada. Referência vigente: INTERFACE_PIXEL.md.

## Disponibilidade após limpeza — 27/10/2026

Os pacotes de reserva e imagens sem referência foram arquivados fora do jogo a pedido do usuário. Os atlas efetivamente usados pelas quatro fases, NPC, HUD, animações e gerador continuam presentes, junto às licenças. Inventários anteriores são históricos. Consulte LIMPEZA_ASSETS.md para recuperação seletiva, sem recarregar todo o acervo.
