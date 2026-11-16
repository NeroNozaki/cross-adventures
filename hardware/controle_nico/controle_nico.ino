// Cross Adventures: ESP32 DevKit / WROOM-32 + joystick + dois botoes.
// Biblioteca ESP32-BLE-Gamepad 0.8.0 (lemmingDev) e NimBLE-Arduino.
// O USB alimenta/grava. Os comandos chegam ao Windows por Bluetooth.
#include <Arduino.h>
#include <BleGamepad.h>
#include <math.h>

constexpr uint8_t PINO_X = 34;
constexpr uint8_t PINO_Y = 35;
constexpr uint8_t PINO_AZUL = 25;
constexpr uint8_t PINO_VERMELHO = 26;
constexpr bool INVERTER_X = false;
constexpr bool INVERTER_Y = true;  // No protocolo Xbox, Y positivo aponta para cima.
constexpr float ZONA_MORTA = 0.06f;  // O jogo ja tem a propria zona morta de 0,24.

BleGamepad controle("Nico - Cross Adventures", "Cross Adventures", 100);
BleGamepadConfiguration configuracao;
int centroX = 2048;
int centroY = 2048;

// Um estado por botao evita golpes extras por trepidacao do contato.
struct Botao {
  uint8_t pino;
  uint8_t comando;
  bool leitura = false;
  bool pressionado = false;
  uint32_t mudouEm = 0;
};
void atualizarBotao(Botao &botao);
Botao azul{PINO_AZUL, BUTTON_3};      // X do controle = golpe (F no teclado).
Botao vermelho{PINO_VERMELHO, BUTTON_2};  // B = escudo enquanto segurar (G).

int lerAnalogico(uint8_t pino) {
  int soma = 0;
  for (int i = 0; i < 4; ++i) soma += analogRead(pino);
  return soma / 4;
}

int16_t converterEixo(int leitura, int centro, bool inverter) {
  float eixo = leitura - centro;
  eixo /= eixo >= 0 ? (4095 - centro) : centro;
  if (fabsf(eixo) <= ZONA_MORTA) return 0;
  eixo = copysignf((fabsf(eixo) - ZONA_MORTA) / (1 - ZONA_MORTA), eixo);
  eixo = constrain(eixo, -1.0f, 1.0f);
  return int16_t((inverter ? -eixo : eixo) * 32767);
}

void atualizarBotao(Botao &botao) {
  const bool agora = digitalRead(botao.pino) == LOW;
  if (agora != botao.leitura) {
    botao.leitura = agora;
    botao.mudouEm = millis();
  }
  if (uint32_t(millis() - botao.mudouEm) >= 20) {
    botao.pressionado = agora;
  }
  // Reenviar o estado tambem cobre uma reconexao com o botao pressionado.
  if (botao.pressionado) controle.press(botao.comando);
  else controle.release(botao.comando);
}

void setup() {
  Serial.begin(115200);
  pinMode(PINO_X, INPUT);
  pinMode(PINO_Y, INPUT);
  pinMode(PINO_AZUL, INPUT_PULLUP);
  pinMode(PINO_VERMELHO, INPUT_PULLUP);
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  Serial.println("Deixe o analogico solto: calibrando o centro...");
  delay(700);
  long somaX = 0, somaY = 0;
  for (int i = 0; i < 64; ++i) {
    somaX += lerAnalogico(PINO_X);
    somaY += lerAnalogico(PINO_Y);
    delay(4);
  }
  centroX = somaX / 64;
  centroY = somaY / 64;
  Serial.printf("Centro X=%d Y=%d\n", centroX, centroY);
  if (centroX < 500 || centroX > 3500 || centroY < 500 || centroY > 3500) {
    Serial.println("Confira VRx/VRy, 3V3 e GND. Solte o analogico e aperte EN.");
    // Nao transmitir um eixo travado por ligacao/calibracao incorreta.
    while (true) delay(1000);
  }

  configuracao.setGamepadMode(GamepadMode::XInputSeriesX);
  configuracao.setAutoReport(false);
  controle.begin(&configuracao);
  Serial.println("Pronto. Pareie Nico - Cross Adventures no Bluetooth do Windows.");
}

void loop() {
  // Manter o debounce atualizado mesmo entre conexoes Bluetooth.
  atualizarBotao(azul);
  atualizarBotao(vermelho);
  if (controle.isConnected()) {
    const int16_t x = converterEixo(lerAnalogico(PINO_X), centroX, INVERTER_X);
    const int16_t y = converterEixo(lerAnalogico(PINO_Y), centroY, INVERTER_Y);
    controle.setLeftThumb(x, y);
    controle.sendReport();
  }
  delay(10);
}
