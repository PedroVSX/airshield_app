#pragma once

// Integration helper for Arduino-ESP32's built-in BLE library.
// Call once from setup(), passing EXACTLY the Wi-Fi MAC used in the MQTT topic.
// This is not a replacement for your sensor/WiFi/MQTT firmware.
#include <Arduino.h>
#include <ctype.h>
#include <BLEDevice.h>
#include <BLEServer.h>

namespace AirShieldIdentity {
constexpr char kServiceUuid[] = "9b1d0001-6c2e-4b5a-8f10-4a6972736864";
constexpr char kIdentityUuid[] = "9b1d0002-6c2e-4b5a-8f10-4a6972736864";

class ServerCallbacks : public BLEServerCallbacks {
  void onDisconnect(BLEServer* server) override {
    BLEDevice::startAdvertising();
  }
};

inline bool begin(const String& mqttWifiMac) {
  // The default GATT read carries this 17-byte ASCII value without fragmentation.
  if (mqttWifiMac.length() != 17) return false;
  for (size_t i = 0; i < 17; ++i) {
    if (i % 3 == 2) {
      if (mqttWifiMac[i] != ':') return false;
    } else if (!isxdigit(static_cast<unsigned char>(mqttWifiMac[i]))) {
      return false;
    }
  }
  BLEDevice::init("AirShield");
  auto* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  auto* service = server->createService(kServiceUuid);
  auto* identity = service->createCharacteristic(kIdentityUuid, BLECharacteristic::PROPERTY_READ);
  identity->setValue(mqttWifiMac.c_str());
  service->start();
  auto* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(kServiceUuid);
  advertising->setScanResponse(true);
  BLEDevice::startAdvertising();
  return true;
}
}  // namespace AirShieldIdentity
