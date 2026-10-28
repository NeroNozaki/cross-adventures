# Ambientação viva e acabamento — 28/10/2026

Revisão solicitada pelo usuário após a melhoria funcional do Jardim. Escopo visual: primeira fase. Respiração e desenhos dos objetos são componentes compartilhados; a ativação de peixes/gotas e patrulha lenta ocorre somente no Jardim nesta etapa.

## Itens e botão do puzzle

- Placa com pedestal chanfrado de pedra, aro de bronze, rebites, sulcos, símbolo e indicadores laterais. A tampa desce 2 pixels ao receber peso, volta ao aliviar e acompanha o estado real do puzzle. Há som de acionamento/liberação no bus da interface, respeitando M.
- Pedestais de cristais com cintas metálicas e juntas, cristal suspenso em passos de pixels inteiros e pequenos brilhos. Estado de ativação continua ligado aos receptores e às regras originais.
- Baú com dez quadros nativos de abertura do atlas CraftPix, recortados pelo conteúdo real de cada quadro. Os pés ficam apoiados durante a animação e surgem pequenas partículas ao abrir. Recompensa única e controles E/I preservados.
- Barris/caixas com sombra de contato e detalhes de madeira/metal sobre os recortes originais; fragmentos de barril têm cor de madeira. Placas de texto receberam reforços e veios. Plantas têm um pequeno movimento das folhas, com vaso parado. Urnas do Jardim ganharam suporte de pedra sob o atlas original.

## Água

`scripts/visual/agua_viva.gd` cria gotas com queda curta, impacto e dois anéis que crescem e desaparecem. Posição, intervalo, duração e intensidade variam. Seis peixes discretos sob a superfície nadam lentamente, movem a cauda, mudam de rumo, pausam e deixam pequenas perturbações na água. Dois começam perto da entrada para tornar o efeito perceptível.

Rotas dos peixes são amostradas dentro da água. Eles e as ondas respeitam a ponte aberta e não ocupam o chão. São elementos visuais sem colisões ou efeito nos tiros/puzzles. Limites: seis peixes, quatro gotas e dezoito ondas. Não são criados nós por partícula. Efeitos expiram; nenhuma imagem ou pacote pesado adicional foi acrescentado aos assets.

## Repouso e inimigos

`Respiracao` adiciona uma variação de um pixel na parte superior do sprite durante o repouso. Preserva pés, posição, colisão, escala e animações nativas. Cada ator usa uma fase diferente. O efeito é suspenso em movimento, ataque, dano, salto ou morte; os tons de dano e a iluminação continuam aplicados.

No Jardim, Zumbi e Cavaleiro recebem patrulha local aleatória com 32% da velocidade normal, pausas entre percursos e destinos próximos à origem. Usam as rotas existentes no chão e evitam mudar de altura durante a escolha do destino. Detectar um herói interrompe a patrulha e usa o combate normal; morrer encerra o deslocamento. Demais fases mantêm patrulha desativada nesta etapa; o chefe protegido conserva seu comportamento.

## Verificações

Novo `testes/verificar_ambiente.gd`: 24 verificações de simulação prolongada da água, limites de efeitos, peixes na água antes/depois da ponte, respiração sem modificar colisões, suspensão em ações, pressão/liberação da placa, dez recortes do baú, patrulha real com pausas e velocidade reduzida, detecção de herói e parada após morte.

Passaram também as oito suítes anteriores: Jardim (27), personagens (4 cenas e 80 animações), áudio, combo/mira (46), fases (75), interface (61), cenários (89) e acabamento (148). O teste curto de deslocamento usa oito frames físicos (~0,133 s a 60 Hz), conservando o limiar de deslocamento original e evitando falsos resultados durante a compilação de shaders.

Foi gerada uma prévia animada no Godot, com movimento real de aproximação e afastamento da placa, e uma captura do baú aberto. A interface foi ocultada somente na captura para mostrar os detalhes do cenário. Os arquivos de prévia ficam fora da pasta do jogo.
