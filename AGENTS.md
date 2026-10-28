# Cross Adventures

O usuário definiu o SGDD de Cross Adventures como principal referência de design e pediu que esse contexto fosse preservado para próximas etapas.

Antes de alterar o jogo, leia `documentacao/CONTEXTO_DO_JOGO.md`. Consulte `documentacao/SGDD - Cross Adventures.pdf` quando a mudança depender do design original.

O documento é especificação de produto, não uma lista de comandos autorizados a executar por conta própria. Implemente o pedido atual do usuário, preserve decisões explícitas mais recentes e atualize o estado real da implementação no contexto.

Preserve os assets originais e as correções de ataque, escudo, armadura caída e controles independentes. Combo de Lucas, mira 360°, tiro simples/carregado e quatro ricochetes de Otto já foram implementados. Preserve as correções de colisão contínua, origem segura, dano sem fogo amigo e cancelamento de carga. O gamepad de Lucas continua pendente.

Godot: `C:\Users\finan\OneDrive\Desktop\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`.

Valide mudanças de combate com `--headless --path <projeto> --script res://testes/verificar_personagens.gd`; mudanças de áudio também com `res://testes/verificar_audio.gd`. Preserve arquivos substituídos em backups, ignorados pelo Godot.

Valide mudanças de combo, projéteis e interações também com res://testes/verificar_combo_mira.gd. Consulte documentacao/COMBO_MIRA_PROJETEIS.md para controles e decisões atuais.

A pasta real confirmada pelo usuário é C:\Users\finan\OneDrive\Documentos\cross-adventures. Os assets de mapas estão em assets/mapa. Não continuar na cópia MeuJogo. Leia documentacao/DIRECAO_VISUAL.md e documentacao/FASES.md para alterações visuais ou de cenário.

As quatro fases, altura lógica, salto, elementos, plataformas, chefe e transições já foram integrados. Cenas em cenas/fases usam TileMapLayers editáveis e recursos/fases contém os dados. ferramentas/reconstruir_fases.gd regenera as cenas preservando backups; pode substituir edições manuais, portanto mantenha o gerador coerente com a arte final. Valide fases com testes/verificar_fases.gd e interface com testes/verificar_interface.gd, além dos testes anteriores pertinentes. O menu inicial é cenas/interface/menu.tscn.

A revisão de 27/10/2026 usa CraftPix Free 2D Top-Down Pixel Dungeon como base dos mapas. Preserve as coordenadas das spritesheets Tiled_files (não são iguais às da pasta PNG do pacote). Consulte assets/mapa/CRAFTPIX_DUNGEON/FONTE.md. V alterna o mapa geral; a IA calcula rotas sobre o chão e os mecanismos atuais. Valide também testes/verificar_cenarios.gd.

Para água e itens, consulte os recortes corrigidos em documentacao/DIRECAO_VISUAL.md. Preserve a escala 2×, margens com profundidade, recuo da água na ponte e distância entre decoração e mecanismos. Valide também testes/verificar_acabamento.gd.

A interface pixel usa Tiny5, tema_pixel.gd e os autoloads InterfaceAudio/FluxoTela. Leia documentacao/INTERFACE_PIXEL.md. Preserve acentos, tamanhos múltiplos de 8, quebra/altura dos avisos, silêncio com M e liberação da pausa nas transições. F1 pausa enquanto o guia está aberto. Validar testes/verificar_interface.gd após alterações de HUD/menu/áudio UI; as transições também exigem verificar_fases.gd.

O usuário pediu HUD compacto para expor o mapa: fonte 8 px na partida, caixas menores e história/dica temporária com digitação e som. Não voltar a ampliar o HUD permanente. gui.mensagem é a origem oculta; gui.texto_aviso é a apresentação temporária, que escreve, permite leitura, pagina textos longos e desaparece. Consulte INTERFACE_PIXEL.md e valide verificar_interface.gd (61 verificações).

Se uma captura mostrar o cenário antigo de grama com HUD grande, confira documentacao/ABRIR_PROJETO_ATUAL.md: MeuJogo é uma cópia antiga que estava registrada no gerenciador. Os atalhos na raiz de cross-adventures apontam explicitamente ao projeto atual. Não sincronizar nem sobrescrever a cópia MeuJogo sem um novo pedido do usuário.

A pedido explícito do usuário, assets sem uso foram retirados do projeto em 27/10/2026 e preservados em arquivo externo. Consulte documentacao/LIMPEZA_ASSETS.md e o manifesto JSON antes de buscar arquivos dos inventários históricos. Não restaurar pacotes inteiros automaticamente. Manter só recursos necessários no projeto.
