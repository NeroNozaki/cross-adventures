# Atualização de 28/10/2026

A primeira fase passou a exigir cooperação entre salas: Lucas mantém a placa inferior enquanto Otto sobe ao norte e reflete um tiro no espelho para ativar o cristal superior. Após o acerto, Otto retorna e a equipe atravessa a ponte. Este é o layout atual, substituindo as disposições intermediárias descritas nos relatórios da revisão.

- Jardim: percurso, circulação, sinalização, objetivos por etapa, posicionamento dos itens e textura de pedra/musgo refinados. Somente a primeira cena foi regenerada.
- Ponte: três trechos sobem da água com lajes, chanfros, respingos e som exclusivo. Física, água e IA só liberam a passagem ao terminar o encaixe, após 1,8 s.
- Otto: cinco ricochetes em tiros simples e carregados; previsão, contagem e alcance seguem a mesma regra do projétil real. Pode disparar em movimento.
- Personagens: aceleração curta, parada imediata, caminhada baseada em deslocamento real, suavização visual de altura e respiração discreta em repouso. Interações consideram altura e paredes.
- Ambientação: gotas, ondulações aleatórias e peixes submersos com limites de quantidade; plantas com movimento sutil; inimigos do Jardim patrulham devagar e pausam antes de detectar os heróis.
- Itens: placa com pressão animada, pedestais/cristais mais detalhados, baú funcional de cura única e materiais refinados. Recorte do baú corrigido para usar seus cinco quadros próprios, sem incluir a alavanca do mesmo atlas.
- Gerador: opção --fase=1 para reconstruir apenas o Jardim; evita decoração sobre paredes e libera entradas dos corredores.
- Documentação: contexto, controles, soluções e decisões atualizados. Backups e prévias permanecem fora do versionamento.

Validação realizada nas etapas finais: dez suítes aprovadas, incluindo Ponte (20), Ambiente (24), Jardim (28), personagens (quatro cenas e 80 animações), áudio, combo/mira (46), fases (76), interface (61), cenários (90) e acabamento (148). Após mover o cristal e corrigir o recorte do baú, foram repetidas as seis suítes afetadas. O percurso foi executado por comandos e tiros reais; a câmera também foi renderizada com os heróis em salas separadas.

As outras três cenas não foram redesenhadas nesta revisão. Permanecem pendentes músicas, gamepad de Lucas e arte exclusiva do chefe.
