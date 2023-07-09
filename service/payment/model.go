package pmnt

import (
	"fmt"

	"github.com/btcsuite/btcd/chaincfg"
	"github.com/lightningnetwork/lnd/zpay32"
	ln "github.com/lnconsole/BeatCoin/service/payment/lightning"
	"github.com/lnconsole/BeatCoin/service/payment/lightning/client/ibexhub"
)

var provider ln.Provider

func InitIBEXHub(creds ibexhub.Credentials) error {
	provider = ibexhub.New(creds)
	if provider == nil {
		return fmt.Errorf("failed to initialize IBEXHub")
	}
	return nil
}

func CreateInvoice(params ln.InvoiceParams) (*ln.InvoiceData, error) {
	if provider == nil {
		return nil, fmt.Errorf("err provider not set")
	}

	istatus := make(chan ln.InvoiceStatus)

	iData, err := provider.CreateInvoice(params, istatus)
	if err != nil {
		return nil, err
	}

	return iData, nil
}

func MakePayment(params ln.PaymentParams) (*ln.PaymentData, error) {
	// payment service will notify on this channel
	pstatus := make(chan ln.PaymentStatus)
	// attempt to pay
	pData, err := func() (*ln.PaymentData, error) {
		if provider == nil {
			return nil, fmt.Errorf("err provider not set")
		}
		_, err := zpay32.Decode(params.Bolt11, &chaincfg.MainNetParams)
		if err != nil {
			return nil, err
		}
		pData, err := provider.MakePayment(params, pstatus)
		if err != nil {
			return nil, err
		}
		return pData, nil
	}()
	// if payment failed right away, let consumer know
	if err != nil {
		return nil, err
	}

	return pData, nil
}

func CancelInvoice(bolt11 string) error {
	if provider == nil {
		return fmt.Errorf("err provider not set")
	}

	return provider.CancelInvoice(bolt11)
}
