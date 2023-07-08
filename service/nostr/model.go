package bstr

import (
	"context"
	"fmt"
	"log"

	sm "github.com/SaveTheRbtz/generic-sync-map-go"
	"github.com/nbd-wtf/go-nostr"
	"github.com/nbd-wtf/go-nostr/nip04"
)

func Publish(ctx context.Context, evt nostr.Event, sk string, relayUrl string) (*nostr.Event, error) {
	if evt.PubKey == "" {
		pk, err := nostr.GetPublicKey(sk)
		if err != nil {
			return nil, fmt.Errorf("secretKey is invalid: %w", err)
		}
		evt.PubKey = pk
	}

	if evt.Sig == "" {
		err := evt.Sign(sk)
		if err != nil {
			return nil, fmt.Errorf("error signing event: %w", err)
		}
	}

	relay, err := nostr.RelayConnect(ctx, relayUrl)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to %s: %s", relayUrl, err)
	}
	log.Printf("posting to: %s, %s", relayUrl, relay.Publish(ctx, evt))
	relay.Close()

	return &evt, nil
}

func Unique(all chan *nostr.Event) chan nostr.Event {
	uniqueEvents := make(chan nostr.Event)
	emittedAlready := sm.MapOf[string, struct{}]{}

	go func() {
		for event := range all {
			if _, ok := emittedAlready.LoadOrStore(event.ID, struct{}{}); !ok {
				uniqueEvents <- *event
			}
		}
	}()

	return uniqueEvents
}

func Decrypt(destPubkey string, sk string, encrypted string) (*string, error) {
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
