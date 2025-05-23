#include <EEPROM.h>
#include "GravityTDS.h"
#include "DHT.h"
#include <WiFi.h>
#include <PubSubClient.h>  // Library MQTT

#define tds_sensor_pin     32
#define dht_pin            5
#define dht_type           DHT22
#define ldr_pin            22

// relay pin
#define relay_air_bersih   23  // pompa air bersih
#define relay_nutrisi      18  // pompa nutrisi hidroponik
#define relay_lampu        19  // lampu grow-light

GravityTDS gravity_tds;
DHT dht(dht_pin, dht_type);

float tds_value = 0;

// Wi-Fi credentials
const char* ssid = "WS Family";   // Ganti dengan SSID Wi-Fi kamu
const char* password = "mbulganteng2020";   // Ganti dengan password Wi-Fi kamu

// MQTT Broker settings
const char* mqttServer = "broker.emqx.io";   // Ganti dengan EMQX broker atau broker lain yang kamu gunakan
const int mqttPort = 1883;   // Port untuk broker MQTT (biasanya 1883 untuk MQTT)
const char* topic = "/sdh-auto-hydroponic";   // Topik untuk mengirimkan data sensor

WiFiClient espClient;
PubSubClient client(espClient);

void setup() {
  Serial.begin(115200);

  gravity_tds.setPin(tds_sensor_pin);
  gravity_tds.setAref(3.3);
  gravity_tds.setAdcRange(4096);
  gravity_tds.begin();

  dht.begin();

  pinMode(relay_air_bersih, OUTPUT);
  pinMode(relay_nutrisi, OUTPUT);
  pinMode(relay_lampu, OUTPUT);
  digitalWrite(relay_air_bersih, LOW);
  digitalWrite(relay_nutrisi, LOW);
  digitalWrite(relay_lampu, LOW);

  pinMode(ldr_pin, INPUT);

  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");

  // Set MQTT server
  client.setServer(mqttServer, mqttPort);
}

void reconnect() {
  // Loop until we're reconnected
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP32Client")) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void loop() {
  // Reconnect if disconnected from MQTT
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Read sensor values
  float suhu = dht.readTemperature();
  float kelembaban = dht.readHumidity();
  
  if (isnan(suhu) || isnan(kelembaban)) {
    Serial.println("Failed to read DHT22 sensor!");
  } else {
    Serial.printf("Temperature: %.1f °C, Humidity: %.1f %%\n", suhu, kelembaban);
    gravity_tds.setTemperature(suhu); // Compensate TDS with temperature
  }

  // Read TDS
  gravity_tds.update();
  tds_value = gravity_tds.getTdsValue();
  Serial.printf("TDS: %.0f ppm\n", tds_value);

  // Read LDR
  int cahaya = analogRead(ldr_pin);
  Serial.printf("Light (LDR): %d\n", cahaya);

  // Create JSON payload
  String payload = String("{\"temperature\":") + suhu + 
                   String(", \"humidity\":") + kelembaban + 
                   String(", \"tds\":") + tds_value + 
                   String(", \"light\":") + cahaya + "}";

  // Publish data to MQTT
  client.publish(topic, payload.c_str());

  // Relay logic (does not send to MQTT, just controls devices)
  if (tds_value > 1200) {
    digitalWrite(relay_air_bersih, HIGH);
    Serial.println("Pompa air bersih: NYALA (TDS > 1200)");
  } else {
    digitalWrite(relay_air_bersih, LOW);
    Serial.println("Pompa air bersih: MATI");
  }

  if (tds_value < 800) {
    digitalWrite(relay_nutrisi, HIGH);
    Serial.println("Pompa nutrisi: NYALA (TDS < 800)");
  } else {
    digitalWrite(relay_nutrisi, LOW);
    Serial.println("Pompa nutrisi: MATI");
  }

  if (cahaya < 1500) {
    digitalWrite(relay_lampu, HIGH);
    Serial.println("Lampu: NYALA (Cahaya rendah)");
  } else {
    digitalWrite(relay_lampu, LOW);
    Serial.println("Lampu: MATI (Cukup terang)");
  }

  Serial.println("-------------------------");
  delay(2000); // Sampling tiap 2 detik
}
