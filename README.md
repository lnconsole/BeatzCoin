# BeatCoin
Turn heart rate into sats mtfk

# Backend
- Create endpoint to receive heart rate and ln-address. When heart rate is above a threshold for x amount of time, send payment to lnaddr
POST /api/pump
{
	lud16: string
	heartRate: int (float)?
}

- Create endpoint that returns tx history of payments made to ln-addr
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
