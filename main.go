package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/fiatjaf/go-lnurl"
	bstr "github.com/lnconsole/BeatCoin/service/nostr"
	pmnt "github.com/lnconsole/BeatCoin/service/payment"
	"github.com/lnconsole/BeatCoin/service/payment/lightning"
	"github.com/lnconsole/BeatCoin/service/payment/lightning/client/ibexhub"
	"github.com/nbd-wtf/go-nostr"
	"github.com/subosito/gotenv"
)

type BeatzcoinPayload struct {
	Secret string `json:"beatzcoin_secret"`
	BPM    int    `json:"bpm"`
}

type Workout struct {
	Date       string `json:"date"`
	SatsEarned int    `json:"sats_earned"`
}

type WorkoutsPayload struct {
	History []Workout `json:"workout"`
}

type Profile struct {
	Nip05       *string `json:"nip05"`
	Lud16       *string `json:"lud16"`
	Lud06       *string `json:"lud06"`
	Website     string  `json:"website"`
	Picture     string  `json:"picture"`
	DisplayName string  `json:"display_name"`
	About       string  `json:"about"`
	Name        string  `json:"name"`
	Pubkey      string  `json:"pubkey"`
}

const (
	thresholdRate  = 160
	rewardMsat     = 1000
	dailySatsQuota = rewardMsat / 1000 * 300
	// dailySatsQuota = rewardMsat / 1000 * 30
	dateFormat = "2006/01/02"
)

var (
	bcRelay *nostr.Relay
	// map[pubkey]map[date]sats
	history = map[string]*map[string]*int{}
)

func main() {
	fmt.Println("Drop the beats, Pick up the sats")
	// load env
	if err := gotenv.Load(); err != nil {
		log.Printf("gotenv: %s", err)
		return
	}
	relayUrl := os.Getenv("RELAY_URL")
	// init ln payment service
	if err := pmnt.InitIBEXHub(ibexhub.Credentials{
		Email:     os.Getenv("IBEXHUB_USER_EMAIL"),
		Password:  os.Getenv("IBEXHUB_USER_PASS"),
		AccountID: os.Getenv("IBEXHUB_ACCOUNT_ID"),
	}); err != nil {
		log.Printf("Error initiating ibexhub service: %s", err)
		return
	}
	// get pk
	sk := os.Getenv("BEATZCOIN_PRIVATE_KEY")
	pk, err := nostr.GetPublicKey(sk)
	log.Printf("pk: %s", pk)
	if err != nil {
		log.Printf("Error getting pk from sk: %s", err)
		return
	}
	// connect to relay
	bcRelay, err = nostr.RelayConnect(context.Background(), relayUrl)
	if err != nil {
		log.Printf("failed to connect to %s: %s", relayUrl, err)
		return
	}

	log.Printf("connected to: %s", bcRelay)
	go func() {
		for notice := range bcRelay.Notices {
			log.Printf("(%s) notice: %s", bcRelay.URL, notice)
		}
	}()
	// listen for kind 33333 for a few seconds to init data store
	var (
		t          = time.Now()
		subHistory = bcRelay.Subscribe(context.Background(), nostr.Filters{{
			Kinds:   []int{33333},
			Authors: []string{pk},
		}})
		historyCh = bstr.Unique(subHistory.Events)
		events    = []nostr.Event{}
	)

LOOP:
	for {
		select {
		case evt := <-historyCh:
			events = append(events, evt)
		case <-time.After(5 * time.Second):
			break LOOP
		}
	}
	subHistory.Unsub()

	// handle kind 33333
	for _, evt := range events {
		dTag := evt.Tags.GetFirst([]string{"d"})
		if dTag == nil {
			continue
		}

		workout := WorkoutsPayload{}
		err := json.Unmarshal([]byte(evt.Content), &workout)
		if err != nil {
			log.Print(err)
			continue
		}
		// initialize each beatzcoin client
		if _, ok := history[dTag.Value()]; !ok {
			history[dTag.Value()] = &map[string]*int{}
		}
		// build history
		for _, session := range workout.History {
			(*history[dTag.Value()])[session.Date] = &session.SatsEarned
		}
	}
	for key, value := range history {
		for key2, value2 := range *value {
			log.Printf("history: %s, %s, %d", key, key2, *value2)
		}
	}
	// listen for kind 4
	var (
		subDM = bcRelay.Subscribe(context.Background(), nostr.Filters{{
			Kinds: []int{nostr.KindEncryptedDirectMessage},
			Since: &t,
			Tags:  nostr.TagMap{"p": []string{pk}},
		}})
		profilech = make(chan Profile)
		payload   BeatzcoinPayload
	)
	// handle kind 4
	go func(sub *nostr.Subscription) {
		uniqueCh := bstr.Unique(sub.Events)
		for evt := range uniqueCh {
			log.Printf("got kind 4 by %s", evt.PubKey)
			// decrypt content
			decrypted, err := bstr.Decrypt(evt.PubKey, sk, evt.Content)
			if err != nil {
				log.Printf("Failed to decrypt: %s", err)
				continue
			}
			err = json.Unmarshal([]byte(*decrypted), &payload)
			if err != nil {
				log.Print(err)
				continue
			}
			// validate daily quota
			now := time.Now()
			// get sats disbursed for today
			todayStr := now.Format(dateFormat)
			if sessions, exists := history[evt.PubKey]; exists {
				if satsEarned, sessionExists := (*sessions)[todayStr]; sessionExists {
					if *satsEarned >= dailySatsQuota {
						log.Printf("quota met for: %s", evt.PubKey)
						continue
					}
				}
			}
			// validate secret
			if os.Getenv("BEATZCOIN_SECRET") != payload.Secret {
				log.Printf("invalid secret: %s", payload.Secret)
				continue
			}
			// validate bpm
			if payload.BPM < thresholdRate {
				log.Printf("did not meet BPM threshold(%d): %d", thresholdRate, payload.BPM)
				continue
			}
			// fetch profile
			fetchMetadataAsync(evt.PubKey, profilech)
		}
	}(subDM)
	// handle profile
	go func() {
		for p := range profilech {
			log.Printf("handling profile of %s", p.Pubkey)

			today := time.Now()

			if p.Lud16 == nil {
				log.Printf("client has no lud16: %s", p.Name)
				continue
			}
			// validate lud16
			_, params, err := lnurl.HandleLNURL(*p.Lud16)
			if err != nil || params.LNURLKind() != "lnurl-pay" {
				log.Printf("invalid lud16: %s", *p.Lud16)
				continue
			}
			// send sats
			payParams, ok := params.(lnurl.LNURLPayParams)
			if !ok {
				log.Printf("invalid lud16 params: %v", params)
				continue
			}
			values, err := payParams.Call(int64(rewardMsat), "", nil)
			if err != nil {
				log.Printf("Failed to get Lightning Address values: %v", payParams)
				continue
			}
			// send workout payload
			_, exists := history[p.Pubkey]
			if !exists {
				history[p.Pubkey] = &map[string]*int{}
			}
			// update current date
			var (
				sessions                  = history[p.Pubkey]
				todayStr                  = today.Format(dateFormat)
				satsEarned, sessionExists = (*sessions)[todayStr]
				rewardSat                 = rewardMsat / 1000
			)
			if sessionExists {
				*satsEarned += rewardSat
			} else {
				(*sessions)[todayStr] = &rewardSat
			}
			payload := WorkoutsPayload{}
			for date, satsEarned := range *sessions {
				// construct payload to be published
				payload.History = append(payload.History, Workout{
					Date:       date,
					SatsEarned: *satsEarned,
				})
			}
			// publish event
			bytes, err := json.Marshal(payload)
			if err != nil {
				log.Print(err)
				continue
			}
			if _, err := bstr.Publish(context.Background(), nostr.Event{
				CreatedAt: time.Now(),
				Kind:      33333,
				Tags: nostr.Tags{
					nostr.Tag{"d", p.Pubkey},
				},
				Content: string(bytes),
			}, sk, relayUrl); err != nil {
				log.Printf("Failed to publish: %s", err)
				continue
			}

			// make payment
			if _, err := pmnt.MakePayment(lightning.PaymentParams{
				Bolt11: values.PR,
			}); err != nil {
				log.Printf("Failed to pay Lightning Address: %s", err)
				continue
			}
			log.Printf("sending %d sats to %s", rewardMsat/1000, *p.Lud16)
		}
	}()
	// wait
	<-make(chan struct{})
}

func fetchMetadataAsync(pubkey string, ch chan Profile) {
	log.Printf("fetchMetadataAsync for %s", pubkey)
	go func() {
		var (
			subMetadata = bcRelay.Subscribe(context.Background(), nostr.Filters{{
				Kinds:   []int{nostr.KindSetMetadata},
				Authors: []string{pubkey},
			}})
			metadatach = bstr.Unique(subMetadata.Events)
			events     []nostr.Event
			counter    int
		)
	LOOP:
		for {
			select {
			case evt := <-metadatach:
				events = append(events, evt)
			case <-time.After(1 * time.Second):
				if len(events) == 0 && counter == 0 {
					// no events and this is the first second. Wait for another second
					counter += 1
					continue
				} else {
					// either we got an event, or we waited enough. Break
					break LOOP
				}
			}
		}

		var latest *nostr.Event
		for i := range events {
			e := events[i]
			if latest == nil ||
				events[i].CreatedAt.After(latest.CreatedAt) {
				latest = &e
			}
		}

		// parse profile metadata
		profile := Profile{Pubkey: pubkey}
		if latest == nil {
			log.Print("did not get any profile")
			return
		}

		err := json.Unmarshal([]byte(latest.Content), &profile)
		if err != nil {
			log.Print(err)
			return
		}

		ch <- profile
	}()
}
