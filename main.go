package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	sm "github.com/SaveTheRbtz/generic-sync-map-go"
	"github.com/fiatjaf/go-lnurl"
	pmnt "github.com/lnconsole/BeatCoin/service/payment"
	"github.com/lnconsole/BeatCoin/service/payment/lightning"
	"github.com/lnconsole/BeatCoin/service/payment/lightning/client/ibexhub"
	"github.com/nbd-wtf/go-nostr"
	"github.com/nbd-wtf/go-nostr/nip04"
	"github.com/subosito/gotenv"
)

/*
generate & store public key
listen for kind4
if secret is valid, check map[pubkey]map[day]sats > threshold
if not, grab lightning address from profile. check if lightning address is valid
if yes, add entry to map
send to lightning address
send parameterized replaceable event
*/

type BeatzcoinPayload struct {
	Secret string `json:"beatzcoin_secret"`
	BPM    int    `json:"bpm"`
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
}

const (
	thresholdRate = 180
	rewardMsat    = 1000
	relayUrl      = "wss://nostr-pub.wellorder.net"
)

var bcRelay *nostr.Relay

func main() {
	fmt.Println("Drop the beats, Pick up the sats")

	if err := gotenv.Load(); err != nil {
		log.Printf("gotenv: %s", err)
		return
	}
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
	relay, err := nostr.RelayConnect(context.Background(), relayUrl)
	if err != nil {
		log.Printf("failed to connect to %s: %s", relayUrl, err)
		return
	}
	bcRelay = relay
	log.Printf("connected to: %s", bcRelay)
	go func() {
		for notice := range relay.Notices {
			log.Printf("(%s) notice: %s", relay.URL, notice)
		}
	}()
	// listen for kind 4
	var (
		t   = time.Now()
		sub = relay.Subscribe(context.Background(), nostr.Filters{{
			Kinds: []int{nostr.KindEncryptedDirectMessage},
			Since: &t,
			Tags:  nostr.TagMap{"p": []string{pk}},
		}})
		profilech = make(chan Profile)
	)
	// handle events
	var (
		payload BeatzcoinPayload
	)
	// handle kind 4
	go func(sub *nostr.Subscription) {
		uniqueCh := unique(sub.Events)
		for evt := range uniqueCh {
			// decrypt content
			decrypted, err := decrypt(evt.PubKey, sk, evt.Content)
			if err != nil {
				log.Printf("Failed to decrypt: %s", err)
				continue
			}
			err = json.Unmarshal([]byte(*decrypted), &payload)
			if err != nil {
				log.Print(err)
				continue
			}
			// validate secret
			if os.Getenv("BEATZCOIN_SECRET") != payload.Secret {
				log.Printf("invalid secret: %s", payload.Secret)
				continue
			}
			// validate bpm
			if payload.BPM < thresholdRate {
				log.Printf("did not meet BPM threshold(180): %d", payload.BPM)
				continue
			}
			// fetch profile
			fetchMetadataAsync(evt.PubKey, profilech)
		}
	}(sub)
	// handle profile
	go func() {
		for p := range profilech {
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

			if _, err := pmnt.MakePayment(lightning.PaymentParams{
				Bolt11: values.PR,
			}); err != nil {
				log.Printf("Failed to pay Lightning Address: %s", err)
				return
			}

			log.Printf("sending %d sats to %s", rewardMsat/1000, *p.Lud16)
		}
	}()
	// wait
	<-make(chan struct{})
}

func fetchMetadataAsync(pubkey string, ch chan Profile) {
	go func() {
		var (
			sub = bcRelay.Subscribe(context.Background(), nostr.Filters{{
				Kinds:   []int{nostr.KindSetMetadata},
				Authors: []string{pubkey},
			}})
			events  []nostr.Event
			counter int
		)
	LOOP:
		for {
			select {
			case evt := <-sub.Events:
				events = append(events, *evt)
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
		profile := Profile{}
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

func decrypt(destPubkey string, sk string, encrypted string) (*string, error) {
	sec, err := nip04.ComputeSharedSecret(destPubkey, sk)
	if err != nil {
		return nil, err
	}

	decrypted, err := nip04.Decrypt(encrypted, sec)
	if err != nil {
		return nil, err
	}

	return &decrypted, nil
}

func unique(all chan *nostr.Event) chan nostr.Event {
	uniqueEvents := make(chan nostr.Event)
	emittedAlready := sm.MapOf[string, struct{}]{}

	go func() {
		for event := range all {
			if _, ok := emittedAlready.LoadOrStore(event.ID, struct{}{}); !ok {
				uniqueEvents <- *event
			}
		}
	}()

	go func() {
		for {
			count := 0
			emittedAlready.Range(func(key string, value struct{}) bool {
				count += 1
				return true
			})
			log.Printf("size of emittedAlready: %d", count)
			time.Sleep(5 * time.Minute)
		}
	}()

	return uniqueEvents
}
