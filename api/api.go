package api

import (
	"net/http"
	"time"

	"github.com/fiatjaf/go-lnurl"
	"github.com/gin-gonic/gin"
	pmnt "github.com/lnconsole/BeatCoin/service/payment"
	"github.com/lnconsole/BeatCoin/service/payment/lightning"
)

const (
	thresholdRate = 180
	rewardMsat    = 1000
)

var (
	heartRates = []Tx{}
)

type Pump struct {
	Lud16     string `json:"lud16"`
	HeartRate int    `json:"heartRate"`
}

func HandleHeartRate(c *gin.Context) {
	var (
		pump Pump
	)
	if err := c.ShouldBindJSON(&pump); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"Error": "Invalid Payload"})
		return
	}
	_, params, err := lnurl.HandleLNURL(pump.Lud16)
	if err != nil || params.LNURLKind() != "lnurl-pay" {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"Error": "Invalid Lightning Address"})
		return
	}
	if pump.HeartRate > thresholdRate {
		// send sats
		payParams, ok := params.(lnurl.LNURLPayParams)
		if !ok {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"Error": "Invalid Lightning Address params"})
			return
		}
		values, err := payParams.Call(int64(rewardMsat), "", nil)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"Error": "Failed to get Lightning Address values"})
			return
		}

		if _, err := pmnt.MakePayment(lightning.PaymentParams{
			Bolt11: values.PR,
		}); err != nil {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"Error": "Failed to pay Lightning Address"})
			return
		}

		heartRates = append(heartRates, Tx{
			Lud16:      pump.Lud16,
			AmountMsat: rewardMsat,
			SettledUTC: time.Now(),
		})
	}
}

type Tx struct {
	Lud16      string    `json:"lud16"`
	AmountMsat int       `json:"amountMsat"`
	SettledUTC time.Time `json:"settledUTC"`
}

type Txs struct {
	Txs []Tx `json:"txs"`
}

func GetTxs(c *gin.Context) {
	c.JSON(http.StatusOK, Txs{Txs: heartRates})
}
