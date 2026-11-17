# Limpeza de recursos sem uso

## Revisão atual — 17/11/2026

Foram retirados 4842 arquivos de origem sem referência no projeto e 4552 arquivos `.import` associados. O total retirado do projeto foi 127.955.533 bytes. `assets/` passou de 5030 arquivos de origem (131.172.935 bytes) para 188 originais (3.217.402 bytes); com os imports restantes, a pasta ocupa 4,7 MB.

Permanecem 161 recursos carregáveis e 27 arquivos de licença/origem em `assets/DOCUMENTACAO`. Nenhum pacote completo foi mantido: saíram sprites, animações, músicas, sons e mapas sem uso dos pacotes Ninja Adventure, Tiny Swords, Tiny Questers, CraftPix, Kenney e Dungeon Gathering.

O cache de importação foi regenerado do zero. `.godot/` caiu de 146 MB e 12.020 arquivos importados para 15 MB e 328 arquivos, sem imports órfãos dos recursos removidos.

Originais, manifesto e restaurador: `/mnt/HD/godot-projects/cross-adventures-arquivo/limpeza_assets_20261117_143608`. A partir da raiz do projeto, execute `python3 /mnt/HD/godot-projects/cross-adventures-arquivo/limpeza_assets_20261117_143608/restaurar.py` para recuperar sem sobrescrever arquivos atuais. Não copie pacotes inteiros de volta ao projeto sem necessidade.

Método: dependências do `ResourceLoader` em todas as cenas e scripts do jogo, referências textuais em cenas, recursos e scripts, caminhos dinâmicos de história e interface, prefixos de áudio e recortes de atlas. Foi preservado tudo que é referenciado por alguma cena, recurso ou script do projeto, além das licenças. Arquivos e imports foram movidos juntos; diretórios vazios foram removidos.

O manifesto `LIMPEZA_ASSETS.json` registra caminho, tamanho, SHA-256 e import de cada original removido, além das referências de cada recurso preservado.

### Validação

- Reimportação do Godot concluída sem erros.
- Os 161 recursos carregáveis preservados foram carregados pelo `ResourceLoader`; as quatro áreas e o menu também carregam.
- Aprovados: área 1/switches (19), câmera (9), spawns por jogador (35), mira assistida (17), pausa (18), puzzle de botões (14), SignalGate (27), sinais (36), switch (19), hole field (21), plataforma móvel (46) e regras de respawn (27).
- Falhas restantes são anteriores à limpeza e não apontam recurso ausente: `verificar_audio` e `verify_dash_respawn` dependem de `cenas/testes/arena_teste.tscn`; `verificar_marcadores` procura o nó `Marcador`; `verificar_fim_fase` falha porque o Player2 continua andando para cima; `verify_wall_spitter` falha em 1 de 33 verificações porque o spitter começa ativo.

## Histórico — 27/10/2026

Data: 2026-10-27T16:07:17

Foram retirados 2023 arquivos de assets sem referências no jogo, incluindo imagens, itens, prévias e sons de reserva. Permanecem 257 recursos usados e 32 arquivos de licença/origem.

Também foram retirados 1953 arquivos de importação associados e 3906 arquivos de cache órfãos. Total retirado do projeto: 25,759,607 bytes. Assets de origem: de 15.43 MB para 1.21 MB.

Originais e manifesto de recuperação: `C:\Users\finan\OneDrive\Documentos\cross-adventures-arquivo\limpeza_20261027_160417`. Execute o restaurar.py dessa pasta com Python para recuperar sem sobrescrever arquivos alterados.

Verificação: referências do ResourceLoader, cenas, recursos, scripts, testes, sons com prefixos e recortes dinâmicos do gerador. Todos os quadros das animações referenciadas foram preservados, assim como recursos da arena de testes e da reconstrução das fases. Os pacotes arquivados não devem ser copiados integralmente de volta ao projeto sem necessidade.

Esta limpeza reduz o tamanho do projeto e o trabalho de importação. Recursos que não eram carregados já não ocupavam a memória da partida.

O manifesto JSON registra cada caminho, tamanho e SHA-256. A pasta externa é uma cópia de recuperação e continua ocupando espaço em disco fora do jogo.

### Validação concluída

Reimportação do Godot sem erros. Aprovados os sete testes existentes: personagens (4 cenas e 80 animações), áudio, combo/mira (46), fases (75), interface (61), cenários (87) e acabamento (163). As quatro fases também foram renderizadas e inspecionadas, sem texturas ausentes. Conferência final: 289 arquivos de origem em assets, somando 1.212.732 bytes, e todos os recursos preservados presentes.

### Duplicata de UIDs — 16/11/2026

O editor reportava 1285 avisos `UID duplicate detected` e falhas ao carregar `Actor/Character/Skeleton/SeparateAnim/NicoCape.svg`. A causa era uma cópia não rastreada de `assets/Ninja Adventure - Asset Pack/Actor/Actor/`, com os mesmos `.import` e UIDs dos arquivos originais. A comparação SHA-256 confirmou 1366 arquivos idênticos, nenhuma diferença de conteúdo e apenas `NicoCape.svg` ausente na árvore original.

A árvore duplicada foi movida para `backups/assets_duplicados_20261116_195216/Ninja Adventure - Asset Pack/Actor/Actor/`, fora do projeto e ignorada pelo Godot. O `NicoCape.svg` foi restaurado no caminho original usado por `player1.tscn` e reimportado. Depois da limpeza, o escaneamento do editor terminou sem erros ou avisos.
