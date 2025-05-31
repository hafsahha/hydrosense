#include <Arduino.h>
#include <EEPROM.h>
#include "DHT.h"
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// === PIN & KONSTANTA ===
#define tds_sensor_pin     33
#define dht_pin            23
#define dht_type           DHT22
#define ldr_pin            32
#define PH_SENSOR_PIN      34
#define ONE_WIRE_BUS       25

#define relay_lampu        5
#define relay_air_bersih   19
#define relay_nutrisi      18

// === OBJEK ===
DHT dht(dht_pin, dht_type);
LiquidCrystal_I2C lcd(0x27, 16, 2);

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature ds18b20(&oneWire);

WiFiClient espClient;
PubSubClient client(espClient);

// === TDS ===
float tds_value = 0;
const float VREF = 3.3;
const float EC_CALIBRATION = 1.0;
const float OFFSET = 0.14;

// === pH Sensor ===
float calibration_value = 21.34 - 1;
//float calibration_value = 21.24 - 1;
unsigned long int avgval;
int buffer_arr[10], temp;
float ph_act;

// === WiFi & MQTT ===
const char* ssid = "IBUBAPATAHU";
const char* password = "antisipasi";
const char* mqttServer = "broker.emqx.io";
const int mqttPort = 1883;
const char* topic = "/sdh-auto-hydroponic";

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    if (client.connect("ESP32HydroponicClient")) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(2000);

  dht.begin();
  ds18b20.begin();
  lcd.init();
  lcd.backlight();
  lcd.clear();

  pinMode(relay_air_bersih, OUTPUT);
  pinMode(relay_nutrisi, OUTPUT);
  pinMode(relay_lampu, OUTPUT);
  pinMode(ldr_pin, INPUT);

  digitalWrite(relay_air_bersih, LOW);
  digitalWrite(relay_nutrisi, LOW);
  digitalWrite(relay_lampu, LOW);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
    lcd.setCursor(0, 0);
    lcd.print("Connecting WiFi ");
    lcd.setCursor(0, 1);
    lcd.print("Please wait...  ");
  }
  Serial.println("Connected to WiFi");
  lcd.setCursor(0, 0);
  lcd.print("WiFi Connected  ");
  lcd.setCursor(0, 1);
  lcd.print("IP: ");
  lcd.print(WiFi.localIP());
  delay(2000);
  lcd.clear();

  client.setServer(mqttServer, mqttPort);
  Serial.println("pH Sensor Ready");
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop();

  float suhu = dht.readTemperature();
  float kelembaban = dht.readHumidity();

  ds18b20.requestTemperatures();
  float suhu_air = ds18b20.getTempCByIndex(0);  // DS18B20

  // Baca pH sensor
  for (int i = 0; i < 10; i++) {
    buffer_arr[i] = analogRead(PH_SENSOR_PIN);
    delay(30);
  }

  for (int i = 0; i < 9; i++) {
    for (int j = i + 1; j < 10; j++) {
      if (buffer_arr[i] > buffer_arr[j]) {
        temp = buffer_arr[i];
        buffer_arr[i] = buffer_arr[j];
        buffer_arr[j] = temp;
      }
    }
  }

  avgval = 0;
  for (int i = 2; i < 8; i++) avgval += buffer_arr[i];
  float volt = (float)avgval * 3.3 / 4095.0 / 6;
  ph_act = -5.70 * volt + calibration_value;

  // Baca TDS dan cahaya
  int analogValue = analogRead(tds_sensor_pin);
  float voltage = analogValue * VREF / 4095.0;
  float ec = (voltage * EC_CALIBRATION) - OFFSET;
  if (ec < 0) ec = 0;
  tds_value = (133.42 * pow(ec, 3) - 255.86 * pow(ec, 2) + 857.39 * ec) * 0.5;
  int cahaya = analogRead(ldr_pin);

  // Tampilkan ke LCD
  if (isnan(suhu) || isnan(kelembaban)) {
    lcd.setCursor(0, 0);
    lcd.print("Sensor DHT error ");
    lcd.setCursor(0, 1);
    lcd.print("                ");
  } else {
    lcd.setCursor(0, 0);
    lcd.print("suhu: ");
    lcd.print(suhu, 1);
    lcd.print(" C   ");
    lcd.setCursor(0, 1);
    lcd.print("lembab: ");
    lcd.print(kelembaban, 1);
    lcd.print(" %   ");
  }

  // Serial Monitor
  Serial.printf("suhu: %.1f °C, kelembaban: %.1f %%\n", suhu, kelembaban);
  Serial.printf("suhu air (ds18b20): %.2f °C\n", suhu_air);
  Serial.printf("pH Value: %.2f\n", ph_act);
  Serial.printf("TDS: %.0f ppm\n", tds_value);
  Serial.printf("Cahaya (LDR): %d\n", cahaya);
  Serial.println("-------------------------");

  // JSON Payload
  String payload = String("{\"temperature\":") + suhu +
                   String(", \"humidity\":") + kelembaban +
                   String(", \"tds\":") + tds_value +
                   String(", \"light\":") + cahaya +
                   String(", \"ph\":") + ph_act +
                   String(", \"water_temp\":") + suhu_air +
                   String(", \"relay_air_bersih\":") + (digitalRead(relay_air_bersih) ? "true" : "false") +
                   String(", \"relay_nutrisi\":") + (digitalRead(relay_nutrisi) ? "true" : "false") +
                   String(", \"relay_lampu\":") + (digitalRead(relay_lampu) ? "true" : "false") + "}";

  if (client.connected()) {
    client.publish(topic, payload.c_str());
    Serial.println("Data sent to MQTT: " + payload);
  }

  // Relay Logic
  if (tds_value > 1200) {
    digitalWrite(relay_air_bersih, HIGH);
    Serial.println("pompa air bersih: nyala (tds > 1200)");
  } else {
    digitalWrite(relay_air_bersih, LOW);
    Serial.println("pompa air bersih: mati");
  }

  if (tds_value < 650) {
    digitalWrite(relay_nutrisi, HIGH);
    Serial.println("pompa nutrisi: nyala (tds < 650)");
  } else {
    digitalWrite(relay_nutrisi, LOW);
    Serial.println("pompa nutrisi: mati");
  }

  if (cahaya < 1500) {
    digitalWrite(relay_lampu, HIGH);
    Serial.println("lampu: nyala (cahaya rendah)");
  } else {
    digitalWrite(relay_lampu, LOW);
    Serial.println("lampu: mati (cukup terang)");
  }

  delay(1000);  // Sampling 1 detik
}