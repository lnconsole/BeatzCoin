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
[ ] Nostr Replaceable Event Kind XX [parameterized replaceable event](https://github.com/nostr-protocol/nips/blob/master/33.md) that server will post if sats were disbursed
```
// client can listen to this to see global leaderboard, or get notified when they have earned sats
{
  "id": 
  "pubkey": <server's pubkey>
  "created_at": 
  "kind": 33333
  "tags": [
    ["d", "history"],
    ["p", <user pubkey>, <"wss://nostr-pub.wellorder.net">],
  ],
  "content": <json string. Check format below>,
  "sig": <64-bytes hex of the signature of the sha256 hash of the serialized event data, which is the same as the "id" field>
}

Content json to be stringify:
{
  "workout": [
    {
      "2023/06/12": {
        "sats_earned": int
        ????
      }
    },
    {
      "2023/06/11": {
        "sats_earned": int
        ????
      }
    },
    ...
  ]
}
```
[ ] Refactor code away from main.go

[ ] Multiple relays support

[ ] Daily disbursable limit for each participants

[ ] Proper payment tracking

[ ] DB Persistence

[ ] Authentication?

