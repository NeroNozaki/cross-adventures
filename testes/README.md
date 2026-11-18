# Testes de Cross Adventures

Após importar o projeto no Godot, rode da raiz:

```powershell
godot --headless --path . --script res://testes/verificar_integracao_main.gd
godot --headless --path . --script res://testes/verificar_audio.gd
```

O primeiro teste percorre a abertura, o guia, os três mapas e o encerramento. Ele aciona os gatilhos de saída diretamente. O segundo verifica música, brasas, gotas e controle do som nas cenas da campanha.

| Para testar | Script |
| --- | --- |
| Pausa e guia | [verificar_pausa.gd](verificar_pausa.gd) |
| Cristais, placas e grades | [verificar_area1_switches.gd](verificar_area1_switches.gd), [verify_switch.gd](verify_switch.gd), [verificar_puzzle_botoes.gd](verificar_puzzle_botoes.gd) |
| Plataforma e vãos | [verify_moving_platform.gd](verify_moving_platform.gd), [verify_hole_field.gd](verify_hole_field.gd) |
| Câmera, ponto de retorno e mira | [verificar_camera_area.gd](verificar_camera_area.gd), [verify_respawn_rules.gd](verify_respawn_rules.gd), [verificar_mira_assistida.gd](verificar_mira_assistida.gd) |
| Canais e condições de puzzle | [verify_signals.gd](verify_signals.gd), [verificar_signal_gate.gd](verificar_signal_gate.gd) |

`verify_dash_respawn.gd` usa a arena de uma revisão anterior. `verificar_marcadores.gd` e `verificar_fim_fase.gd` incluem expectativas da interface antiga. Os scripts acima são os pontos de partida para validar a campanha atual.
