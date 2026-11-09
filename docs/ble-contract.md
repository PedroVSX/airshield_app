# Identificação AirShield por BLE — contrato proposto v1

Este contrato foi criado para a integração app/ESP32. **O firmware atual ainda não
o implementa**, conforme informado pela equipe. Os UUIDs abaixo são novos, não
foram extraídos dos prints. O app já busca esse serviço e lê a característica.

| Item | Valor |
| --- | --- |
| Serviço anunciado | `9b1d0001-6c2e-4b5a-8f10-4a6972736864` |
| Característica do identificador | `9b1d0002-6c2e-4b5a-8f10-4a6972736864` |
| Propriedade GATT | READ |
| Valor | MAC Wi-Fi em UTF-8/ASCII, 17 bytes: `48:E7:29:B4:5F:4C` |
| Nome sugerido | `AirShield` (a busca filtra pelo serviço, não pelo nome) |

O valor precisa ser **exatamente o identificador usado para montar o tópico MQTT**.
Preserve maiúsculas/minúsculas. Não envie o endereço Bluetooth, o identificador
opaco do sistema operacional, bytes binários do MAC nem uma string terminada em
NUL. Os 17 bytes cabem em uma leitura GATT com o MTU padrão.

O app permite selecionar um dos formatos observados:

- Atual: `airshield/48:E7:29:B4:5F:4C/dados-ambiente`.
- Antigo: `airshield/dispositivo-48E729B45F4C/dados-ambiente`.

Após a leitura, o app encerra a conexão BLE, preenche o MAC, salva as configurações
escolhidas e conecta ao broker. A telemetria continua por MQTT. Este serviço não
recebe senha Wi-Fi, não provisiona a rede e não controla atuadores.

## Integração no firmware

O arquivo [airshield_ble_identity.h](../firmware/airshield_ble_identity.h) é um
helper para a API `BLEDevice` da biblioteca BLE incorporada ao Arduino-ESP32 3.x.
Ele deve ser adicionado ao firmware existente, em uma placa com BLE. Não é um
firmware completo. A API Bluetooth mudou no Arduino-ESP32 4.x; adapte o helper se
essa for a versão usada pela equipe. O contrato GATT permanece igual.

Exemplo de uso **quando a telemetria usa o MAC da interface STA**:

```cpp
#include <WiFi.h>
#include "airshield_ble_identity.h"

void setup() {
  // Preserve a configuração WiFiManager e a inicialização dos sensores existentes.
  WiFi.mode(WIFI_STA);  // Ou WIFI_AP_STA, conforme o firmware.
  const String mqttWifiMac = WiFi.macAddress();
  const String topic = "airshield/" + mqttWifiMac + "/dados-ambiente";
  const bool bleReady = AirShieldIdentity::begin(mqttWifiMac);
  // Use o MESMO mqttWifiMac no publicador MQTT existente.
  // Trate bleReady == false no diagnóstico do firmware.
}
```

Não substitua o `setup()` atual pelo exemplo. Se o publicador usa outro
identificador/interface, passe o valor que ele já usa. MAC STA, MAC do AP e endereço
BLE podem ser diferentes. Chame `begin` uma única vez, após inicializar Wi-Fi.
Se já houver um servidor BLE no firmware, acrescente o serviço a ele em vez de
inicializar uma segunda pilha. A validação na placa e a integração com o firmware
completo ainda precisam ser feitas.

## Validação com duas placas

1. Grave o helper integrado ao firmware e confirme os UUIDs no anúncio BLE.
2. No app, escolha o broker e o formato do tópico da versão do firmware.
3. Toque em **Identificar e conectar via Bluetooth**, depois **Buscar dispositivos**.
4. Selecione a placa e compare o tópico exibido com o log do publicador MQTT.
5. Confirme que as medições da outra placa não aparecem nesse tópico/histórico.
6. Desligue a placa: o app deve avisar quando transcorrer o limite sem dados,
   mesmo que o broker continue conectado.
7. Negue a permissão Bluetooth, desligue o adaptador e cancele a busca; o app deve
   continuar permitindo a configuração manual.

Android solicita as permissões BLE no primeiro uso; versões antigas também
exigem localização para descobrir dispositivos. No navegador, use HTTPS ou
localhost e suporte a Web Bluetooth. O projeto não solicita coleta BLE em segundo
plano nem pareamento permanente do sistema operacional.

Referências: [Universal BLE](https://pub.dev/packages/universal_ble),
[exemplo BLE Arduino-ESP32 3.3.7](https://github.com/espressif/arduino-esp32/blob/3.3.7/libraries/BLE/examples/Server/Server.ino),
[mudança da API no Arduino-ESP32 4.0](https://developer.espressif.com/blog/2026/10/arduino-bluetooth-refactor/).
