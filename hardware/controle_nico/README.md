# Controle de Nico: ESP32-WROOM-32

Um joystick de dois eixos movimenta somente Nico (o esqueleto). O botão azul equivale ao X/golpe/F; o vermelho ao B/escudo/G. O escudo permanece ativo enquanto o botão está pressionado. Otto continua nas setas e mouse, independente. Os controles de gamepad já estão no projeto Godot; este firmware não muda suas cenas ou regras.

## Peças

- ESP32 DevKit com ESP32-WROOM-32.
- Módulo analógico de dois eixos, com GND, VCC/+5V, VRx, VRy e SW, do tipo KY-023 ou equivalente com potenciômetros passivos.
- Dois botões momentâneos normalmente abertos: azul e vermelho.
- Protoboard, jumpers e cabo USB de dados para a placa.
- Computador com Bluetooth LE habilitado (ou adaptador USB compatível).

## Ligações — com o cabo USB desconectado

Use os NOMES dos pinos impressos na placa, não conte a posição física: as versões DevKit de 30 e 38 pinos têm disposições diferentes.

| Componente / terminal | ESP32 | Função |
|---|---|---|
| Analógico VCC (às vezes escrito +5V no módulo) | **3V3** | Alimentação em 3,3 V |
| Analógico GND | GND | Terra comum |
| Analógico VRx | GPIO34 / D34 | Esquerda e direita |
| Analógico VRy | GPIO35 / D35 | Cima e baixo |
| Analógico SW | Deixar desconectado | Clique do analógico não utilizado |
| Botão azul, um contato | GPIO25 / D25 | Golpe |
| Botão azul, outro contato | GND | Fecha o circuito ao apertar |
| Botão vermelho, um contato | GPIO26 / D26 | Escudo |
| Botão vermelho, outro contato | GND | Fecha o circuito ao apertar |

**Alimente o módulo analógico em 3V3, mesmo se o terminal dele estiver marcado +5V. Não aplique 5 V a VRx/VRy ou aos GPIOs.** A marcação é comum em módulos passivos de joystick. Se o seu módulo tiver circuito eletrônico diferente de dois potenciômetros, confirme suas especificações antes de usar esta ligação.

```text
ESP32 3V3 ---- VCC do analógico
ESP32 GND --- GND do analógico e os dois botões
ESP32 34 ---- VRx
ESP32 35 ---- VRy
ESP32 25 ---- [ botão AZUL ] ----- GND
ESP32 26 ---- [ botão VERMELHO ] -- GND
```

O código usa INPUT_PULLUP: os botões fecham para GND e dispensam resistor externo. Em botão tátil de quatro pernas, use dois contatos que só tenham continuidade ao apertar; duas pernas do mesmo par já podem estar ligadas internamente. Em botão arcade, ligue COM ao GND e NO ao GPIO. Se houver terminais de iluminação, deixe-os desconectados nesta primeira montagem.

Alimente o ESP32 pelo próprio USB. Não conecte outra fonte simultaneamente. O USB desta placa é uma ponte serial: neste projeto, a comunicação de controle acontece por Bluetooth, mesmo que o cabo continue conectado para alimentação.

## Gravar no Arduino IDE

1. Instale o Arduino IDE. Em Preferências, adicione à lista de URLs de placas:
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`
2. No Gerenciador de Placas, instale **esp32 by Espressif Systems** (série 3.x). Selecione **ESP32 Dev Module** e a porta COM correspondente ao cabo USB.
3. Instale **NimBLE-Arduino**, de h2zero, pelo Gerenciador de Bibliotecas (série 2.x).
4. Baixe **ESP32-BLE-Gamepad 0.8.0**: [ZIP da versão](https://github.com/lemmingDev/ESP32-BLE-Gamepad/archive/refs/tags/v0.8.0.zip). No Arduino IDE, use Sketch → Incluir Biblioteca → Adicionar biblioteca .ZIP. Este código usa o modo XInputSeriesX da versão 0.8.0; exemplos de versões antigas não têm essa API.
5. Abra `controle_nico.ino`, dentro da pasta de mesmo nome. Clique em Verificar e depois Carregar. Se ficar em “Connecting...”, mantenha BOOT pressionado no início da gravação e solte quando a transferência começar.
6. Deixe o analógico solto ao reiniciar: o primeiro segundo mede o centro. O Monitor Serial a 115200 mostra o centro e avisa se a ligação parece incorreta. Nessa situação, corrija os fios e pressione EN para calibrar de novo.

## Conectar e jogar

1. No Windows, abra Configurações → Bluetooth e dispositivos → Adicionar dispositivo → Bluetooth.
2. Pareie **Nico - Cross Adventures**. O Windows pode identificá-lo como um controle Xbox.
3. Pressione Win+R, digite `joy.cpl` e confira em Propriedades: analógico parado no centro, movimento nos dois eixos, e os dois botões acendendo separadamente.
4. Abra Cross Adventures na pasta original. Entre em uma fase: analógico move Nico, azul golpeia, vermelho segura o escudo. Faça alguns cliques separados no azul para o combo. Teste Otto pelo mouse e setas ao mesmo tempo.
5. O menu e as conversas continuam disponíveis pelo mouse/teclado. Este controle mínimo não acrescenta botões de salto, interação, pausa ou confirmação de menu. Não foi atribuído nada ao SW do analógico.

Se um eixo estiver invertido, troque apenas `INVERTER_X` ou `INVERTER_Y` entre true/false, grave novamente e confira. A orientação física dos módulos varia. Se Nico andar sozinho, solte o analógico e pressione EN; evite mover a haste durante a calibração. Se a COM não aparecer, confira o cabo de dados e o driver da ponte USB da sua placa (CP210x ou CH340, conforme o chip).

Se o Bluetooth não localizar a placa, confira a mensagem do Monitor Serial e se o PC tem Bluetooth LE. Em caso de pareamento antigo após mudar o firmware/perfil, remova o controle nas configurações do Windows e pareie de novo. Um cabo USB sozinho não transporta os comandos deste firmware.

## Estado da validação

Os pinos foram conferidos na documentação da Espressif. A API e os números X=BUTTON_3/B=BUTTON_2 foram conferidos na ESP32-BLE-Gamepad 0.8.0. O InputMap do projeto usa analógico esquerdo, X para golpe e B para escudo de Nico. O firmware contém média de leitura, calibração inicial, zona morta, debounce independente e envio conjunto dos comandos.

Não houve compilação com o toolchain ESP32 nem gravação ou teste em hardware nesta entrega: o ambiente local não tem Arduino/PlatformIO instalado e não há um controle montado validado. A montagem, a polaridade de cada eixo, o pareamento e a resposta real no jogo ainda precisam ser confirmados na placa. O modo Series X é o recomendado pela biblioteca para Windows; isso não substitui o teste na combinação real de placa, Bluetooth e Windows.

## Referências

- [Pinos e alimentação do ESP32-DevKitC — Espressif](https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32/esp32-devkitc/user_guide.html)
- [ADC no Arduino-ESP32 — Espressif](https://docs.espressif.com/projects/arduino-esp32/en/latest/api/adc.html)
- [Instalar Arduino-ESP32 — Espressif](https://docs.espressif.com/projects/arduino-esp32/en/latest/installing.html)
- [API XInput e botões — ESP32-BLE-Gamepad 0.8.0](https://github.com/lemmingDev/ESP32-BLE-Gamepad/blob/v0.8.0/docs/XInputMode.md)
