# Limpeza de recursos sem uso

Data: 2026-10-27T16:07:17

Foram retirados 2023 arquivos de assets sem referências no jogo, incluindo imagens, itens, prévias e sons de reserva. Permanecem 257 recursos usados e 32 arquivos de licença/origem.

Também foram retirados 1953 arquivos de importação associados e 3906 arquivos de cache órfãos. Total retirado do projeto: 25,759,607 bytes. Assets de origem: de 15.43 MB para 1.21 MB.

Originais e manifesto de recuperação: `C:\Users\finan\OneDrive\Documentos\cross-adventures-arquivo\limpeza_20261027_160417`. Execute o restaurar.py dessa pasta com Python para recuperar sem sobrescrever arquivos alterados.

Verificação: referências do ResourceLoader, cenas, recursos, scripts, testes, sons com prefixos e recortes dinâmicos do gerador. Todos os quadros das animações referenciadas foram preservados, assim como recursos da arena de testes e da reconstrução das fases. Os pacotes arquivados não devem ser copiados integralmente de volta ao projeto sem necessidade.

Esta limpeza reduz o tamanho do projeto e o trabalho de importação. Recursos que não eram carregados já não ocupavam a memória da partida.

O manifesto JSON registra cada caminho, tamanho e SHA-256. A pasta externa é uma cópia de recuperação e continua ocupando espaço em disco fora do jogo.

## Validação concluída

Reimportação do Godot sem erros. Aprovados os sete testes existentes: personagens (4 cenas e 80 animações), áudio, combo/mira (46), fases (75), interface (61), cenários (87) e acabamento (163). As quatro fases também foram renderizadas e inspecionadas, sem texturas ausentes. Conferência final: 289 arquivos de origem em assets, somando 1.212.732 bytes, e todos os recursos preservados presentes.
