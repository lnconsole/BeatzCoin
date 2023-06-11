# BeatCoin
Turn heart rate into sats mtfk

# Backend
### Getting Started
```
cp .env-example .env
# then provide your ibexhub credentials

go run .
```

[x] Nostr Kind 4 that client should publish in order to receive sats
```
// if bpm is above 180 and user has not reached daily sats earned limit, sats will be sent to the lightning address in their kind 0
{
  "id": 
  "pubkey": 
  "created_at": 
  "kind": 4
  "tags": [
    ["p", <server's pubkey>, <"wss://nostr-pub.wellorder.net">],
  ],
  "content": <json string. Check format below>,
  "sig": <64-bytes hex of the signature of the sha256 hash of the serialized event data, which is the same as the "id" field>
}

Content json to be stringify:
{
  "beatzcoin_secret": "JEFFREY_EPSTEIN_DID_NOT_KILL_HIMSELF"
  "bpm": <int>
}
```
[ ] Nostr Replaceable Event Kind XX that server will post if sats were disbursed
```
// client can listen to this to see global leaderboard, or get notified when they have earned sats

TODO
```
[ ] Refactor code away from main.go

[ ] Multiple relays support

[ ] Daily disbursable limit for each participants

[ ] Proper payment tracking

[ ] DB Persistence

[ ] Authentication?

