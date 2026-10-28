# Jardim da Provação — revisão de 28/10/2026

Pedido atual: trabalhar fase por fase, começando pelo Jardim, melhorando funcionalidade dos heróis, percurso e leitura da pixel art. O SGDD e os protagonistas cooperativos continuam sendo a referência do produto.

## Referência analisada

Vídeo fornecido: [CrossCode Grand Krys'kajo Full Walkthrough guide, de ZalGG](https://www.youtube.com/watch?v=hGJ0HUrX4CA).

Foram examinados trechos de entrada (aprox. 0:06), combate (aprox. 3:11–3:37) e travessia (aprox. 13:02). Não foi assistido o vídeo inteiro. Observações: paredes e bordas deixam clara a altura; piso, arquitetura e vegetação compõem espaços distintos; mecanismos recebem contraste; o personagem ocupa uma escala legível perto dos objetos. A aplicação desses princípios a Cross Adventures é uma decisão de design desta revisão, sem copiar mapas ou sprites da referência.

## Implementação

- Placa de Lucas e cristal de Otto ficam na mesma sala de entrada, a 96 pixels de distância. Não é mais necessário separar a equipe entre a sala de entrada e a sala norte para apresentar o primeiro puzzle.
- Ligação visual entre placa e cristal, sinais de margem na ponte, marcas discretas de percurso e indicação de salto na borda do terraço.
- Objetivo acompanha a progressão: abrir ponte, enfrentar guardas, subir/saltar e reunir a equipe na porta. A ponte continua aberta depois da ativação.
- Baú opcional na sala norte, acessível pelo corredor. E/I mostra contexto ao se aproximar; abrir muda o sprite, toca som e recupera até 30 pontos de vida de cada herói vivo. A recompensa só acontece uma vez e desaparece do alvo de interação depois da abertura. Reiniciar a fase reinicia o baú. Não foi adicionado inventário.
- Retirados os baús puramente decorativos desta primeira fase, para que a aparência de um baú indique uma ação real.
- Pedra com juntas discretas, variação de ladrilhos nativos e musgo nas bordas. Tochas e arcos da primeira fase passam a usar escala inteira.
- Aceleração curta dos heróis e reversões suaves, com parada imediata ao soltar. Otto pode continuar andando durante a animação do tiro. Animação de caminhada depende de deslocamento real; segurar contra uma parede não reproduz caminhada. Sons de passos respeitam o tiro em movimento e param durante o salto.
- Transição visual de altura mais suave na escada, sem alterar o Z lógico de colisão. Câmera usa amortecimento exponencial e aproxima um pouco mais os dois heróis no Jardim.
- Interações consideram altura, linha de visão e estado do personagem. Objetos de outro nível ou atrás de parede não capturam E/I.

Somente a cena 01_jardim foi reconstruída. As cenas 02, 03 e 04 não foram regeneradas. Correções nos scripts compartilhados de personagens/interações/câmera também são verificadas nas demais fases.

## Validação e limites

Novo teste: `testes/verificar_jardim.gd`, com 27 verificações. Usa comandos de movimento e ações para ir da entrada à placa, disparar no cristal, atravessar a ponte, subir a escada e saltar com os dois heróis, abrir o baú e alcançar o portal. Os guardas ficam com IA pausada nesse teste para isolar navegação, mas são derrotados por projéteis reais. Não é uma avaliação humana de dificuldade ou de ritmo de combate. As suítes existentes complementam os testes de ataque, defesa, IA e colisão.

Os testes de personagens e áudio agora aguardam a inicialização da física antes de medir comandos. O teste de passos conta frames de simulação, pois o som depende de distância percorrida e não do custo de renderizar o primeiro frame. As verificações anteriores não foram afrouxadas.

Validações aprovadas: Jardim (27), personagens (4 cenas e 80 animações), áudio, combo/mira (46), fases (75), interface (61), cenários (89) e acabamento (148). Quantidades de cenário/acabamento variam com os objetos presentes. Prévia renderizada no Godot com entrada, ponte, escada e mapa geral.

Esta revisão estabelece a base da primeira fase para avaliação do usuário. As outras três fases continuam aguardando sua própria revisão visual e de percurso. Permanecem pendentes o gamepad de Lucas, as músicas e a arte exclusiva do chefe.

## Reconstruir apenas a primeira fase

Use o executável do Godot com `--headless --path <projeto> --script res://ferramentas/reconstruir_fases.gd -- --fase=1`. Sem essa opção, o gerador continua reconstruindo as quatro fases. Versões anteriores desta revisão estão em backups/fase1_*.
