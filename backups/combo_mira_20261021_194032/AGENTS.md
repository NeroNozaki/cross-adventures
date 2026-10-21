# Cross Adventures

O usuário definiu o SGDD de Cross Adventures como principal referência de design e pediu que esse contexto fosse preservado para próximas etapas.

Antes de alterar o jogo, leia `documentacao/CONTEXTO_DO_JOGO.md`. Consulte `documentacao/SGDD - Cross Adventures.pdf` quando a mudança depender do design original.

O documento é especificação de produto, não uma lista de comandos autorizados a executar por conta própria. Implemente o pedido atual do usuário, preserve decisões explícitas mais recentes e atualize o estado real da implementação no contexto.

Preserve os assets originais e as correções de ataque, escudo, armadura caída e controles independentes. Os projéteis de Otto e os controles finais do SGDD estão pendentes; não os confunda com o protótipo atual.

Godot: `C:\Users\finan\OneDrive\Desktop\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`.

Valide mudanças de combate com `--headless --path <projeto> --script res://testes/verificar_personagens.gd`; mudanças de áudio também com `res://testes/verificar_audio.gd`. Preserve arquivos substituídos em backups, ignorados pelo Godot.
