# Cross Adventures

Aventura cooperativa local em pixel art para dois jogadores. Nico e Otto acordam na mesma masmorra e precisam combinar habilidades para abrir caminho. Ao fim de cada fase, a amizade avança quando os dois chegam à saída.

## Abrir e jogar

1. Abra ou importe [project.godot](project.godot) no Godot 4.7.1.
2. Aguarde a importação dos recursos e pressione **F5**.
3. Escolha **Como jogar** para ver os controles ou **Jogar** para começar.

| Quem | Controle | Ações |
| --- | --- | --- |
| Nico | W, A, S, D ou analógico esquerdo | **F** ou **X** dá um golpe. Segure **G** ou **B** para usar o escudo. |
| Otto | Setas para andar e mouse para mirar | Clique esquerdo dispara. Segure e solte para carregar a esfera. Clique direito dá um impulso. |
| Ambos | **F1**, **Esc** e **M** | Abrem o guia, pausam o jogo e alternam o som, respectivamente. |

## Campanha

| Fase | O que os dois precisam fazer |
| --- | --- |
| 1. Celas e cristais | Sair das celas e combinar placas e cristais para abrir as grades. |
| 2. Galeria das plataformas | Usar placas e receptores para mover plataformas e cruzar os vãos. |
| 3. Caminho da saída | Passar pelos corredores com armadilhas, coordenar as placas e encontrar a saída. |

A campanha inclui capa animada, abertura e final, diálogos curtos com opção de pular, HUD de vida e amizade e um guia ilustrado. A identidade visual combina a fonte própria Cross Inscrição, molduras de bronze e cristal, iluminação de arandelas, estátuas, musgo e pedestais facetados. Cada fase tem sua ambientação sonora, com gotas, brasas e sons dos mecanismos.

## Para apresentar ou editar

- [Roteiro de apresentação e mapa do código](documentacao/APRESENTACAO.md)
- [Testes desta versão](testes/README.md)
- [Histórico das decisões](documentacao/CONTEXTO_DO_JOGO.md)
- [Documento original de design](<documentacao/SGDD - Cross Adventures.pdf>) e [créditos dos recursos](assets/DOCUMENTACAO/FONTES_E_LICENCAS.txt)

A sequência jogável termina em `area_3.tscn`. A cena `area_4.tscn` e os documentos antigos registram etapas anteriores do projeto.
