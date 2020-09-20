// Stupid little go script to test Esquew

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"net/http"
	"time"
)

var topics = []string{"T1", "T2", "T3"}
var subscriptions = []string{"S1", "S2", "S3"}

const (
	pubMax = 50
	subMax = 50
)

type Message struct {
	Ref     string `json:ref`
	Message string `json:message`
}

type MessageResp struct {
	Messages []Message `json:messages`
}

func post(url string, body []byte) (*http.Response, error) {
	return http.Post(fmt.Sprintf("http://localhost:4000/api/%s", url), "application/json", bytes.NewBuffer(body))
}

func get(url string) (*http.Response, error) {
	return http.Get(fmt.Sprintf("http://localhost:4000/api/%s", url))
}

func randomSleep() {
	time.Sleep(time.Duration(rand.Intn(150)) * time.Millisecond)
}

func pub() {
	randomSleep()
	topic := topics[rand.Intn(len(topics))]
	sent := rand.Intn(pubMax)

	for i := 0; i < sent; i++ {
		_, err := post(fmt.Sprintf("publish/%s", topic), []byte(fmt.Sprintf(`{"message":"%d"}`, i)))
		if err != nil {
			panic(err.Error())
		}
		randomSleep()
	}
	log.Printf("sent\t%d messages to %s\n", sent, topic)

}

func sub() {
	randomSleep()
	topic := topics[rand.Intn(len(topics))]
	subscription := subscriptions[rand.Intn(len(subscriptions))]
	count := rand.Intn(subMax)
	resp, err := get(fmt.Sprintf("subscriptions/read/%s/%s?count=%d", topic, subscription, count))

	if err != nil {
		panic(err.Error())
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		panic(err.Error())
	}

	var message MessageResp

	err = json.Unmarshal(body, &message)

	if err != nil {
		panic(err.Error())
	}

	log.Printf("read\t%d messages from %s:%s\n", len(message.Messages), topic, subscription)
	for _, r := range message.Messages {
		action := "ack"

		if rand.Intn(2) == 0 {
			action = "nack"
		}

		randomSleep()
		randomSleep()
		_, err = post(fmt.Sprintf("subscriptions/%s/%s/%s", action, topic, subscription), []byte(fmt.Sprintf(`{"refs": [%s]}`, r.Ref)))

		if err != nil {
			panic(err.Error())
		}
		log.Println(fmt.Sprintf("%sed\t%s", action, r.Ref))
	}

}

func main() {
	for _, topic := range topics {
		for _, sub := range subscriptions {
			post("/create", []byte(fmt.Sprintf(`{"topic":"%s", "subscriptions": ["%s"]}`, topic, sub)))
		}

	}

	for i := 0; i < 1000; i++ {
		log.Printf("launching\t%d\n", i)
		randomSleep()
		go pub()
		go sub()
		randomSleep()
	}

}
