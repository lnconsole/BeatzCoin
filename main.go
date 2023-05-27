package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/lnconsole/BeatCoin/api"
	pmnt "github.com/lnconsole/BeatCoin/service/payment"
	"github.com/lnconsole/BeatCoin/service/payment/lightning/client/ibexhub"
	"github.com/subosito/gotenv"
)

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
		log.Printf("Error initiating nostr service: %s", err)
		return
	}

	ginEngine := gin.Default()
	ginEngine.POST("/api/pump", api.HandleHeartRate)
	ginEngine.GET("/api/earnings", api.GetTxs)
	ginEngine.Run()
}
