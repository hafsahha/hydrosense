package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

var sensorData = "{}"

func messageHandler(client mqtt.Client, msg mqtt.Message) {
	fmt.Printf("Pesan diterima: %s\n", msg.Payload())
	sensorData = string(msg.Payload())
}

func fetchData(w http.ResponseWriter, r *http.Request) {
	// Supaya Flutter Web bisa akses (CORS)
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprint(w, sensorData)
}

func publishRandomData(client mqtt.Client, topic string) {
	for {
		data := map[string]interface{}{
			"temperature": float64(rand.Intn(350))/10 + 15,
			"humidity":    float64(rand.Intn(1000)) / 10,
			"tds":         rand.Intn(2000),
			"light":       rand.Intn(4000),
			"pH":          float64(rand.Intn(140)) / 10,
		}

		payload, err := json.Marshal(data)
		if err != nil {
			log.Println("Error marshal random data:", err)
			continue
		}

		token := client.Publish(topic, 0, false, payload)
		token.Wait()
		log.Println("Published random data:", string(payload))

		time.Sleep(5 * time.Second)
	}
}

func main() {
	rand.Seed(time.Now().UnixNano())

	opts := mqtt.NewClientOptions()
	opts.AddBroker("tcp://broker.emqx.io:1883")
	opts.SetClientID("GolangClient")
	opts.SetDefaultPublishHandler(messageHandler)

	client := mqtt.NewClient(opts)

	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatal(token.Error())
	}

	topic := "/sdh-auto-hydroponic"

	if token := client.Subscribe(topic, 0, nil); token.Wait() && token.Error() != nil {
		log.Fatal(token.Error())
	}

	go publishRandomData(client, topic)

	http.HandleFunc("/getSensorData", fetchData)

	log.Println("Starting server on :8080")
	log.Fatal(http.ListenAndServe("0.0.0.0:8080", nil))
}
