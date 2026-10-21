# Personagens RPG — controles independentes

Abra o projeto no Godot 4 e pressione F5 para testar a arena.

| Personagem | Movimento | Ataque | Defesa |
|---|---|---|---|
| Guerreiro | WASD | Espaço ou J | Segurar Shift |
| Robô | Setas | Enter | Sem escudo |

R reinicia a arena. Os dois protagonistas recebem comandos simultaneamente, cada um com suas próprias teclas. Nenhum segue ou luta automaticamente pelo outro. O personagem sem comandos fica parado. A morte de um não troca os controles do sobrevivente.

## Guerreiro

Os ataques laterais usam preparação, estocada na direção comandada e recuperação. O trecho giratório que levava a espada para o lado contrário foi retirado desses clipes, usando os próprios quadros originais. O arco e a área de dano usam a direção do personagem, travada durante o ataque. Foi corrigida a associação antiga da seta esquerda à direção direita.

Segure Shift para erguer o escudo. O escudo aparece à frente e produz faíscas ao bloquear. Golpes dentro do cone frontal são bloqueados integralmente; golpes laterais e pelas costas continuam causando dano. Defender reduz a velocidade a 45% e impede atacar. O bloqueio não tem custo de energia nesta base. Solte o escudo para atacar. Não é possível defender durante o ataque ou a reação de dano.

## Cavaleiro

Ao morrer, elmo, peitoral e botas se separam em uma animação de queda. As peças usam os sprites da própria armadura. Os restos permanecem no local até reiniciar a cena, sem bloquear passagem ou receber dano.

## Cenas e scripts

As quatro cenas reutilizáveis ficam em `cenas/personagens/`. Os atributos de vida, velocidade, dano, defesa e alcance ficam no Inspetor da raiz.

`heroi.gd` lê o **Prefixo controle** de cada instância (`guerreiro` ou `robo`), correspondente às ações no Input Map. **Controlado** habilita ou desabilita a entrada de comandos daquela instância.

`personagem_base.gd` gerencia combate, animações e escudo. `vilao.gd` gerencia perseguição. `cavaleiro.gd` acrescenta a morte com armadura caída.

`EfeitosCombate` desenha arcos de ataque, escudo e faíscas; o script fica em `scripts/efeitos/efeitos_combate.gd`. A cena `cenas/efeitos/armadura_caida.tscn` e seu script permitem ajustar as peças e a queda.

Camadas físicas: 1 cenário; 2 heróis; 3 vilões; 4 áreas de dano dos heróis; 5 áreas de dano dos vilões. Não há fogo amigo. O dano após defesa é no mínimo 1, exceto quando totalmente bloqueado pelo escudo.

## Limitações dos assets

O Guerreiro não possui idle lateral e usa um quadro de caminhada. Cavaleiro e Zumbi não possuem ataque dedicado nos arquivos disponíveis; usam poses disponíveis com o arco do golpe. O Robô usa ataque corpo a corpo e, sem morte dedicada, usa pose e transparência.

A base inclui personagens e arena de teste. Inventário, experiência, salvamento e navegação com paredes internas ainda não foram implementados. As imagens originais e suas licenças permanecem em `assets/`. Arquivos substituídos são preservados em `backups/`.


## Cross Adventures: referência e sons

O Guerreiro corresponde a Lucas e o Robô a Otto. O SGDD e as decisões atuais estão preservados em documentacao/CONTEXTO_DO_JOGO.md. Consulte esse arquivo antes das próximas etapas.

Os quatro personagens agora têm efeitos sonoros. M liga ou silencia os efeitos. Veja documentacao/SONS.md para volumes e perfis. O áudio de Otto acompanha a ação provisória atual; projéteis e ricochete ainda serão implementados.
