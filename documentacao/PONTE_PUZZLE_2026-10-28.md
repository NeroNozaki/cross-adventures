# Ponte e puzzle do Jardim — revisão de 28/10/2026

Pedido do usuário: melhorar o desenho e o surgimento da ponte com som diferente, passar Otto de quatro para cinco ricochetes e separar os mecanismos para um puzzle um pouco mais desafiador. Esta decisão explícita substitui o limite anterior de quatro ricochetes e a disposição simples da revisão anterior.

## Regra de Otto

Tiros simples e carregados agora apagam no quinto contato com parede; continuam após o quarto. Os impactos, pontos de contatos restantes e previsão usam o novo limite. Limite, velocidades e duração padrão ficam centralizados em projetil.gd. A previsão respeita o alcance real de cada tiro, evitando indicar um caminho maior que os 12 segundos de vida da esfera. Os danos, elementos, independência de controles e ausência de fogo amigo foram preservados.

## Puzzle da primeira fase

- Placa de Lucas: célula (4,18).
- Cristal: célula (9,18), a cinco células/160 pixels da placa.
- Mureta: coluna 7 nas linhas 17–19, com arte e colisão; impede uma ligação direta entre os dois mecanismos.
- Espelho: célula (9,21), rotação -45°; separado do cristal por três células.
- Posição sugerida de tiro: célula (5,21), marcada discretamente no piso. Otto dispara para a direita; o espelho reflete o tiro para cima, até o cristal.

Lucas precisa manter a placa pressionada quando o tiro refletido atingir o cristal. Tiro direto não ativa o receptor e mostra uma orientação curta. O acerto fica memorizado: Lucas pode sair da placa e a ponte continua construindo/permanecerá aberta. A placa de texto e a planta próximas foram reposicionadas. O gerador também rejeita decoração sobre paredes, evitando urnas em cima da mureta do puzzle.

Objetivos da interface distinguem resolver o puzzle, aguardar o mecanismo, atravessar/enfrentar guardas e alcançar a porta elevada. A dificuldade vem de posicionamento, reflexão e cooperação, sem exigir uma reação rápida depois do acerto.

## Ponte

O controlador PonteAnimada é criado somente no Jardim, antes dos personagens na ordem de desenho. O tabuleiro tem lajes intercaladas, chanfros, juntas, bordas de bronze, encontros de pedra e pequenos vãos na face inferior. Três peças sobem da água com atraso entre elas e respingos curtos. A montagem dura 1,8 segundo.

A variável sinais.ponte significa que o puzzle destravou o mecanismo. A função fase.ponte_pronta("ponte") informa se a passagem física terminou de encaixar. Altura, salto, rotas da IA, água e abertura final do portal usam esse estado. Enquanto sobe, o chão permanece ausente; depois do encaixe, a água deixa de cobrir a travessia. As pontes das demais fases conservam seu funcionamento anterior.

Som exclusivo: assets/SONS/CENARIO/PONTE/ponte_mecanismo.wav. Efeito original sintetizado de 2,3 s (mecanismo grave, encaixes e confirmação final), mono PCM 22.050 Hz/16 bits, aproximadamente 101 kB. Toca uma vez por ativação em AudioStreamPlayer2D no bus SFX e respeita M/pausa. Não usa o som de digitação ou de clique do menu.

## Validação

Novo verificar_ponte.gd: 20 verificações. Cobre bloqueio físico durante a construção, liberação após o encaixe, água/ponte, destino de salto, som de uso único, reinício, separação real por mureta, rejeição de tiro direto, exigência do parceiro, cinco contatos na previsão e no tiro real, sobrevivência ao quarto contato e alcance previsto igual ao alcance efetivo de cada tipo de projétil.

As dez suítes passaram: Ponte (20), Ambiente (24), Jardim (28), personagens (4 cenas e 80 animações), áudio, combo/mira (46), fases (76), interface (61), cenários (90), acabamento (148). O percurso do Jardim usa comandos, tiro refletido e travessia reais. As verificações antigas foram ajustadas para esperar a montagem após destravar o mecanismo, mantendo as checagens de colisão e progressão.

Foi renderizada uma demonstração no Godot em que Lucas pressiona a placa, Otto dispara, o tiro reflete, o cristal ativa e a ponte sobe. A verificação da captura confirma o encaixe completo e um único acionamento do som. A prévia GIF não contém áudio; o som é um recurso do jogo.

Somente 01_jardim.tscn foi regenerada. Cinco ricochetes são a regra compartilhada de Otto em toda a campanha. As fases seguintes continuam aguardando revisão individual de mapa e puzzle.

## Layout substituído por decisão posterior

O usuário solicitou o cristal na sala superior. A disposição de placa/cristal na mesma sala e a mureta descritas acima são históricas e foram substituídas. Consulte CRISTAL_NORTE_2026-10-28.md para posições e solução atuais. Ponte e cinco ricochetes permanecem.
