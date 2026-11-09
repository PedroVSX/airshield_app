# AirShield

Aplicativo Flutter para receber telemetria de qualidade do ar de um ESP32 por MQTT.
Inclui configuração de conexão, identificação por BLE, painel, sensores, histórico
local e demonstração opcional. A primeira abertura não conecta automaticamente;
configure e toque em **Salvar e conectar**.

## Executar

Use Flutter com Dart **3.13.5 ou superior** dentro da série 3.x. O projeto foi
verificado com Flutter 3.47.9 / Dart 3.13.7. O Flutter 3.16/Dart 3.2 não atende
às dependências deste repositório.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

No Windows, `flutter pub get` pode pedir o Modo de Desenvolvedor para criar os
links dos plugins desktop. Isso é uma configuração do sistema; o projeto não a
altera. Android requer SDK, JDK/Gradle compatíveis e licenças do SDK já aceitas.
iOS/macOS precisam de macOS/Xcode. BLE requer adaptador e dispositivo físico para
validação completa.

## Conectar ao ESP32

1. Ligue o sistema com o firmware dos sensores e MQTT.
2. Para configurar Wi-Fi, conecte o celular à rede do AP mostrada no monitor serial
   (exemplo: `airshield_48:E7:29:B4:5F:4C`), senha **12345678**.
3. Abra `http://192.168.4.1`. O firmware também anuncia `http://airshield.com`.
   Configure a rede pelo portal e retorne a uma rede com acesso ao broker.
4. Em **Configurações**, informe o broker, transporte, porta, MAC e formato do tópico.
   O exemplo dos prints já está preenchido; confirme o MAC da sua placa.
5. Toque em **Salvar e conectar**. O estado primeiro informa a conexão ao broker e
   a assinatura, depois informa a chegada de leituras válidas.
6. Alternativamente, implemente o [contrato BLE](docs/ble-contract.md) no ESP32 e
   use **Identificar e conectar via Bluetooth**. O serviço BLE ainda precisa ser
   integrado ao firmware pela equipe.

O primeiro print é consistente com um portal WiFiManager; não demonstra uma API
HTTP de telemetria nem um broker rodando em `192.168.4.1`. Os avisos de NVS/rotas
do servidor devem ser investigados no firmware caso o portal não funcione. Não há
código desse firmware neste repositório.

### Broker informado pela equipe

| Transporte | Host | Porta | Caminho |
| --- | --- | --- | --- |
| TCP | `broker.emqx.io` | 1883 | — |
| TLS | `broker.emqx.io` | 8883 | — |
| WS | `broker.emqx.io` | 8083 | `/mqtt` |
| WSS | `broker.emqx.io` | 8084 | `/mqtt` |

O navegador usa WS/WSS; páginas HTTPS precisam de WSS. Ao mudar o transporte no
host EMQX, o formulário ajusta a porta correspondente. Certificados TLS são
validados normalmente. Usuário e senha são opcionais; a senha MQTT permanece
somente na sessão e deve ser informada novamente após reiniciar o app. A senha do
AP não é usada como senha MQTT.

O broker EMQX é público: o tópico identifica a placa, mas não limita quem pode
assinar/publicar. Para acesso privado, use um broker com autenticação e ACLs.
Não existe endpoint de comando/atuador definido nos prints; o app é assinante de
telemetria e não publica comandos no ESP32.

### Tópicos suportados

| Versão observada | Tópico do exemplo |
| --- | --- |
| Print mais recente | `airshield/48:E7:29:B4:5F:4C/dados-ambiente` |
| Print antigo | `airshield/dispositivo-48E729B45F4C/dados-ambiente` |

Escolha o formato correspondente à versão gravada na placa. A assinatura é do
tópico exato, QoS 0, sem curingas. Maiúsculas/minúsculas são significativas. O app
nunca deriva o identificador Wi-Fi a partir do endereço Bluetooth.

## Dados

Formato mais recente, transcrito do print:

```json
{
  "medidas": {
    "co2": 0, "temperatura": 0, "umidade": 0, "cov": 0,
    "pm 0.1": 0, "pm 10": 0, "pm 2.5": 0
  },
  "indices_qualidade": {
    "qualidade_umidade": 3, "qualidade_cov": 0, "qualidade_co2": 0,
    "qualidade_pm01": 0, "qualidade_pm25": 0, "qualidade_pm10": 0
  }
}
```

Formato antigo também aceito:

```json
{
  "co2": 0, "temperatura": 0, "umidade": 0, "indice_cov": 0,
  "pm 0.1": 0, "pm 1.0": 0, "pm 2.5": 0
}
```

`cov` tem prioridade sobre o alias antigo `indice_cov`. Os valores precisam ser
números JSON finitos; strings numéricas, JSON inválido e campos básicos ausentes
são rejeitados sem encerrar a conexão. `pm 1.0` e `pm 10` são canais diferentes;
campos ausentes são exibidos como indisponíveis, nunca como zero. Códigos ausentes
do firmware antigo não recebem uma classificação inventada.

A escala semântica dos códigos 0–4 não foi fornecida. Nas leituras reais o app
mostra **Código N**, sem afirmar que 0 significa ar bom. As classificações nomeadas
do protótipo são usadas apenas na demonstração. A equipe deve confirmar a faixa
do campo `pm 0.1`, as unidades de PM/COV, a escala dos índices e a frequência de
publicação antes de interpretar as medições como indicadores ambientais.

Como os exemplos não têm timestamp do sensor, o horário exibido é o **recebimento
no app**. Mensagens MQTT retidas são identificadas como potencialmente antigas.
O limite sem nova leitura é configurável (padrão: 60 segundos). Uma conexão ao
broker, sozinha, não prova que a placa está publicando.

## Histórico e recuperação

- Últimas 100 leituras por broker/porta/usuário/tópico; demonstração separada.
- Histórico disponível mesmo desconectado. O histórico antigo do protótipo
  (`air_quality_history`) não é importado, pois continha dados simulados sem origem.
- Gravações ordenadas, recuperação de linhas válidas em arquivos corrompidos e
  aviso se uma gravação falhar. O armazenamento é local, não um banco na nuvem.
- Reconexão automática a cada 5 segundos após falha e nova assinatura do tópico.
  **Desconectar** cancela as tentativas. Sessões e timers antigos são encerrados
  ao trocar a configuração.
- A coleta depende do app em execução. Não há serviço garantido em segundo plano,
  recuperação de mensagens perdidas, exportação ou persistência remota.

## Testes

`flutter test` cobre os JSONs dos prints, formato dos tópicos, validação BLE,
seleção do identificador Wi-Fi, histórico, navegação sem dados, troca de fonte,
telas estreitas e conexões MQTT TCP/WS reais em loopback. O broker de testes é uma
fixture mínima de protocolo, não um serviço público nem o ESP32.

Para repetir o diagnóstico de conexão ao EMQX (somente assinatura dos dois tópicos
de exemplo, sem publicação), execute `dart run tool/check_broker.dart --tls`.
Use `--wss` para conferir WSS ou sem argumento para TCP.

O [registro de validação](docs/validation.md) contém resultados e limitações desta
integração, incluindo o caminho do APK de teste.

Antes de considerar a integração física concluída:

1. Implemente o helper BLE no firmware e confira identificação/tópico.
2. Compare valores recebidos com o monitor serial em uma placa real.
3. Desligue e religue placa/rede, verificando o aviso sem dados e a recuperação.
4. Teste permissões e conexão no celular alvo, incluindo a troca do Wi-Fi do AP.

Referências: [broker público EMQX](https://www.emqx.com/en/mqtt/public-mqtt5-broker),
[WiFiManager](https://github.com/tzapu/WiFiManager),
[mqtt_client](https://pub.dev/packages/mqtt_client).
