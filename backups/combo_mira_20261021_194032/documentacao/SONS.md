# Efeitos sonoros dos personagens

Os efeitos usam exclusivamente os arquivos OGG que já estão em assets/SONS. As licenças originais estão em assets/DOCUMENTACAO. Não foram adicionadas vozes ou músicas.

| Personagem | Identidade sonora |
|---|---|
| Lucas / cena Guerreiro | Passos, lâmina, acerto, dano, queda, escudo erguido e bloqueio metálico. |
| Otto / cena Robô | Passos metálicos, ação eletrônica, acerto metálico, falha ao sofrer dano e desligamento. |
| Cavaleiro Azul | Passos pesados, golpe de arma, acerto, impacto na armadura e queda metálica atrasada em 0,25 s para acompanhar a separação das peças. |
| Zumbi | Passos abafados, movimento de ataque, acerto corporal, dano e queda suaves. |

Passos são disparados pela distância realmente percorrida, não pela tecla pressionada. Não tocam parado ou tentando atravessar uma parede. Não há som de acerto no vazio ou em um alvo invulnerável. Bloqueios e danos possuem sons diferentes. O som de erguer o escudo toca ao ativar a defesa, não a cada frame.

Os quatro personagens usam a cena cenas/audio/audio_personagem.tscn com nós AudioStreamPlayer2D separados para Passos, Acoes, Impactos e Estado. Os efeitos têm posição estéreo, variações pequenas de tom e evitam repetir imediatamente a mesma variante. Cada cena aponta para um perfil editável em recursos/audio.

Volumes: ajuste os perfis no Inspetor ou os buses Passos e Combate no painel Audio do Godot. Ambos passam pelo bus SFX e pelo Master. M alterna o mute de SFX. Os volumes iniciais são conservadores para o jogo cooperativo.

O efeito eletrônico atual de Otto acompanha o ataque corpo a corpo provisório. O perfil também prepara um som de ricochete, ainda sem conexão porque os projéteis não estão implementados. A mecânica final do SGDD continua registrada como pendente.

Lista exata dos arquivos: documentacao/MAPA_DE_SONS.json. Referência do jogo e estado real: documentacao/CONTEXTO_DO_JOGO.md.

Verificação automática: execute Godot com --headless --path <projeto> --script res://testes/verificar_audio.gd.
