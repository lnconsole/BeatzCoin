# BeatCoin
Turn heart rate into sats mtfk

# Backend
### To run, simply execute
`go run .`

[x] Create endpoint to receive heart rate and ln-address. When heart rate is above a threshold (180), send 1 sat to lnaddr
```
POST /api/pump
{
	lud16: string
	heartRate: int // heart rate above 180 will trigger sats payment
}
```
[x] Create endpoint that returns tx history of payments made to ln-addr
```
GET /api/earnings
{
	txs: [
	     {
		lud16: string
		amountMsat: int
		settledUTC: string
	     }
	]
}
```
[ ] Proper payment tracking

[ ] DB Persistence

[ ] Authentication?

