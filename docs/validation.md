# Validação da integração — 09/11/2026

Branch: `codex/esp32-integration`.

## Ambiente

- Flutter 3.47.9 / Dart 3.13.7, instalado separadamente em
  `C:\Users\igorg\AppData\Local\codex-toolchains\airshield-sdk\flutter`.
- A instalação original em `C:\src\flutter` (3.16.0) e o PATH não foram alterados.
- O download do SDK foi conferido com o SHA-256 do manifesto oficial.
- As dependências foram resolvidas; o Windows avisou sobre falta de suporte a
  symlinks para plugins desktop. Nenhuma configuração de segurança do sistema
  foi modificada. As compilações Android e web foram executadas com `--no-pub`.

Para usar o SDK desta validação no PowerShell:

```powershell
$flutter = 'C:\Users\igorg\AppData\Local\codex-toolchains\airshield-sdk\flutter\bin\flutter.bat'
& $flutter analyze --no-pub
& $flutter test --no-pub
& $flutter build apk --debug --no-pub
```

## Resultados

- Análise estática sem erros ou avisos.
- 25 testes automatizados aprovados.
- Compilação web aprovada (`build/web`).
- Compilação Android debug aprovada:
  `build/app/outputs/flutter-apk/app-debug.apk`.
- Conexão real TLS com `broker.emqx.io:8883` aprovada, com SUBACK dos tópicos atual
  e antigo do dispositivo de referência. Nenhuma leitura válida recebida nos
  cinco segundos de observação. Nenhuma mensagem foi publicada pelo diagnóstico.
- Interface web conferida: configuração acessível sem dados, demonstração com
  medições, histórico sendo preenchido, troca para fonte real descartando o
  painel de demonstração e conexão WSS ao EMQX na porta 8084 com assinatura aceita.
- JSON dos dois prints validado; o formato antigo não produz um PM10 fictício.
- TCP e WebSocket testados com sockets reais em loopback: recebimento, retenção,
  JSON inválido seguido de leitura válida, autenticação enviada, queda de rede,
  nova assinatura, recusa/ausência de SUBACK e aviso por ausência de telemetria.
- Identificação BLE testada com transporte simulado: valor Wi-Fi distinto do
  identificador Bluetooth, validação do contrato e liberação da tela/serviço.

## Limitações que dependem do sistema físico

- Não havia ESP32/celular disponível para validar rádio BLE, sensores e permissões
  nativas. O teste BLE não é uma certificação da comunicação física.
- O helper `firmware/airshield_ble_identity.h` não foi compilado/gravado na placa.
  Ele deve ser integrado ao firmware existente seguindo `docs/ble-contract.md`.
- Significado dos índices, unidades PM/COV, faixa do campo `pm 0.1` e periodicidade
  de publicação precisam ser confirmados com a equipe de firmware.
- iOS/macOS e instalação/execução do APK no celular não foram testados neste Windows.
- O APK é de desenvolvimento, assinado com chave de debug; publicação em loja
  exige configuração de identificação e assinatura de distribuição.
- O Android SDK emitiu aviso de diferenças de versões de XML entre SDK e ferramentas
  de linha de comando; isso não impediu a compilação.
