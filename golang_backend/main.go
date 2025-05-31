package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

// SensorData matches the ESP32 format
type SensorData struct {
	Temperature    float64 `json:"temperature"`
	Humidity       float64 `json:"humidity"`
	TDS            float64 `json:"tds"`
	Light          int     `json:"light"`
	Ph             float64 `json:"ph"`
	WaterTemp      float64 `json:"water_temp"`
	RelayAirBersih bool    `json:"relay_air_bersih"`
	RelayNutrisi   bool    `json:"relay_nutrisi"`
	RelayLampu     bool    `json:"relay_lampu"`
}

var sensorData = "{}"

func messageHandler(client mqtt.Client, msg mqtt.Message) {
	fmt.Printf("Pesan diterima: %s\n", msg.Payload())

	// Validate JSON structure
	var data map[string]interface{}
	if err := json.Unmarshal(msg.Payload(), &data); err != nil {
		log.Printf("Invalid JSON received: %v", err)
		return
	}

	// Add timestamp to the data
	data["timestamp"] = time.Now().Format(time.RFC3339)

	// Marshal back to JSON
	enhancedData, err := json.Marshal(data)
	if err != nil {
		log.Printf("Error adding timestamp: %v", err)
		return
	}

	sensorData = string(enhancedData)
	log.Printf("Updated sensor data with timestamp")
}

func fetchData(w http.ResponseWriter, r *http.Request) {
	// Supaya Flutter Web bisa akses (CORS)
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprint(w, sensorData)
}

func main() {
	opts := mqtt.NewClientOptions()
	opts.AddBroker("tcp://broker.emqx.io:1883")
	opts.SetClientID("GolangClient")
	opts.SetDefaultPublishHandler(messageHandler)

	// Set reconnection parameters
	opts.SetAutoReconnect(true)
	opts.SetMaxReconnectInterval(1 * time.Minute)
	opts.SetKeepAlive(30 * time.Second)

	client := mqtt.NewClient(opts)

	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatal(token.Error())
	}

	topic := "/sdh-auto-hydroponic"

	if token := client.Subscribe(topic, 0, nil); token.Wait() && token.Error() != nil {
		log.Fatal(token.Error())
	}

	log.Println("Connected to MQTT broker and subscribed to topic:", topic)

	http.HandleFunc("/getSensorData", fetchData)

	log.Println("Starting server on :8080")
	log.Fatal(http.ListenAndServe("0.0.0.0:8080", nil))
}
