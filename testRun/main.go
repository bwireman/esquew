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
	"sync"
	"time"
)

const (
	pubMax     = 20
	subMax     = 20
	numWorkers = 1500
)

var topics = []string{"T1", "T2", "T3"}
var subscriptions = []string{"S1", "S2", "S3"}

type Message struct {
	Ref     string `json:ref`
	Message string `json:message`
}

type MessageResp struct {
	Messages []Message `json:messages`
}

func randomSleep() {
	time.Sleep(time.Duration(rand.Intn(100)) * time.Millisecond)
}

func post(url string, body []byte) (*http.Response, error) {
	return http.Post(fmt.Sprintf("http://localhost:4000/api/%s", url), "application/json", bytes.NewBuffer(body))
}

func get(url string) (*http.Response, error) {
	return http.Get(fmt.Sprintf("http://localhost:4000/api/%s", url))
}

func pub(id int, wg *sync.WaitGroup) {
	randomSleep()
	topic := topics[rand.Intn(len(topics))]
	sent := rand.Intn(pubMax) + 1

	for i := 0; i < sent; i++ {
		_, err := post(fmt.Sprintf("publish/%s", topic), []byte(fmt.Sprintf(`{"message":"id: %d, message: %d"}`, id, i)))
		if err != nil {
			panic(err.Error())
		}
		randomSleep()
	}
	log.Printf("worker:%d\tsent\t%d messages to %s\n", id, sent, topic)
	wg.Done()
}

func sub(id int, wg *sync.WaitGroup) {
	randomSleep()
	topic := topics[rand.Intn(len(topics))]
	subscription := subscriptions[rand.Intn(len(subscriptions))]
	count := rand.Intn(subMax) + 1
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

	log.Printf("worker:%d\tread\t%d messages from %s:%s\n", id, len(message.Messages), topic, subscription)
	for _, r := range message.Messages {
		action := "ack"

		if rand.Intn(2) == 0 {
			action = "nack"
		}

		randomSleep()
		_, err = post(fmt.Sprintf("subscriptions/%s/%s/%s", action, topic, subscription), []byte(fmt.Sprintf(`{"refs": [%s]}`, r.Ref)))

		if err != nil {
			panic(err.Error())
		}
		log.Printf("worker:%d\t%sed\t%s", id, action, r.Message)
	}

	wg.Done()
}

func main() {
	for _, topic := range topics {
		for _, sub := range subscriptions {
			log.Printf("creating topic: %s, subscription %s", topic, sub)
			post("/create", []byte(fmt.Sprintf(`{"topic":"%s", "subscriptions": ["%s"]}`, topic, sub)))
		}
	}

	var waitgroup sync.WaitGroup
	for id := 0; id < numWorkers; id++ {
		waitgroup.Add(2)
		log.Printf("worker:%d\tready\n", id)
		go pub(id, &waitgroup)
		go sub(id, &waitgroup)
	}

	waitgroup.Wait()
}
