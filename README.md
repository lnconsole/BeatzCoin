# Beatzcoin

💦 Sweat for Sats 🤑

Beatzcoin captures user's heart rate and transmit it to the server via the nostr protocol. For every 12 seconds of >= 160 BPM, a sat is sent to the lightning address associated with the user's nostr profile

<img width="558" alt="Screenshot 2023-07-25 at 11 39 26 AM" src="https://github.com/lnconsole/BeatzCoin/assets/43709958/9efe0e13-a983-429b-8fc5-4bf3d9e70ab7">

There are 3 components to this project
1. **Mobile app (Flutter OSS)**
- Allows user to enter nostr profile & associate a lightning address
- Allows pairing of Polar heart rate sensor
- Transmits heart rate data to server via nostr Kind 4 events

2. **"Server" (go nostr client OSS)**
- Track & Process heart rate data, send sats to user's lightning address and publish user's workout history(nostr Kind 33333 event)
- Kind 33333 is a parameterized replaceable event that stores a user's workout history
```
// tags: ["d": <user pubkey>]
// content field of Kind 33333 is a serialized json of the following format
{
  "workout": [
    {
      "date": string, // 2023/07/10
      "sats_earned": int,
    }
  ]
}
```
  
3. **Web app (https://beatzcoin.conxole.io)**
- Demo and instructions website
- Listens to Kind 33333 from the server and displays the global leaderboard


# Future Improvements
1. More heart rate sensors support
2. NIP 58 achievement badges
3. Challenges for higher rewards (Double sats for BPM > 180)
4. Challenges among friend groups (Deposit funds in the beginning of a season and most active athlete takes all when the season ends)
... more coming
