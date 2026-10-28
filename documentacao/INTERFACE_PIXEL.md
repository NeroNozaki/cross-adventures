# Interface pixel — Cross Adventures

Revisão de 27/10/2026. O usuário pediu HUD, tipografia, entradas e sons coerentes em pixel art.

## Materiais examinados

Foram percorridas todas as pastas do projeto, excluindo cache, Git e backups. Não havia fontes TTF/OTF/FNT. Foram localizadas 29 imagens de interface e 100 sons de interface; lista em INVENTARIO_INTERFACE.json.

HUD.png, do pacote Dungeon assets pack fornecido pelo usuário, oferece corações e outros ícones; o coração é usado na missão. As peças de quadro e setas do 2D Pixel Dungeon foram avaliadas, mas os quadros não deram um bom resultado ao esticar. A moldura final é um SVG próprio de 20×20 em grade, com recorte de cantos, sombra e margem de nove partes. Os arquivos originais permanecem.

A fonte adicionada é Tiny5, obtida em https://github.com/google/fonts/tree/main/ofl/tiny5 . Licença OFL junto à fonte em assets/INTERFACE/FONTES/TINY5. Usa tamanhos múltiplos de 8, sem antialiasing, sem posição subpixel e com filtro nearest. Acentos em português foram verificados. A interface compartilha scripts/visual/tema_pixel.gd.

## Comportamento

- HUD com retratos recortados da arte real, vida numérica, barra segmentada com perda gradual e status de escudo, combo, elemento/carga e recuperação. Não são sistemas novos de atributos.
- Cartões de herói de 122×36 no canto, identificação da fase de 164×36 e objetivo em faixa de 24 px com largura ajustada ao texto. Fonte de 8 px no HUD durante a partida.
- Entrada breve dos painéis em posições inteiras, sem faixa grande no centro do mapa.
- Histórias e dicas em caixa temporária de no máximo três linhas (44 px), com fonte de 8 px, escrita a cerca de 36 letras/s e pequenas pausas na pontuação. Som de digitação nas letras, com limitação de repetição. Depois da escrita há 2,4 s de leitura, seguidos de desaparecimento suave. Textos maiores passam automaticamente para páginas seguintes. Não há mais cabeçalho “DICA DA EQUIPE” nem caixa fixa vazia. A apresentação guarda sua cópia do texto até terminar e não reaparece apenas porque a fase manteve a dica ativa. Pausa/guia suspendem a escrita e a leitura.
- F1 abre o guia em duas colunas e pausa a partida; F1/Esc fecha. Esc abre a pausa; Continuar retoma. O guia é compartilhado com o menu.
- Cortina em blocos no início, reinício, retorno ao menu e avanço de fases. Durante a transição a simulação e os comandos são bloqueados; ao terminar, a pausa é liberada.
- Menu, guia, pausa e conclusão usam a mesma fonte, moldura e paleta de aço azul, marfim, ouro e ciano.

## Sons

InterfaceAudio é autoload persistente; evita cortar sons durante trocas de cena. Usa sete efeitos Kenney Interface Sounds já presentes, com licença CC0 preservada em assets/DOCUMENTACAO/KENNEY_INTERFACE_SOUNDS. Seleção, confirmação, abrir/fechar, aviso, mecanismo concluído e revelação de texto têm efeitos distintos, volumes moderados e limite de repetição. Os clipes curtos são decodificados uma vez para PCM em memória. O bus Interface envia para SFX; M silencia e restaura também os sons de interface. Os efeitos anteriores dos personagens foram preservados.

FluxoTela é o autoload da transição. O tema e a interface ficam em scripts/visual; o áudio em scripts/audio/audio_interface.gd. Ajustes de layout devem respeitar a área lógica 640×400 e ser revisados no Godot, incluindo textos das quatro fases.

## Verificação

verificar_interface.gd passou com 61 verificações: fonte, acentos, tamanhos dos textos, sons, entrada/retorno, revelação completa, vida animada, guia e pausa real. Também foram executados os testes de personagens, áudio, combo/mira (46), fases (75), cenários (87) e acabamento (163). As telas e a prévia animada são capturas reais do Godot.
