package ibexhub

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"github.com/lnconsole/BeatCoin/service/payment/lightning"
	"github.com/lnconsole/BeatCoin/shared"
)

type IBEXHub struct {
	endpoints          map[string]string
	defaultHttpHeaders map[string]string
}

type Credentials struct {
	Email     string
	Password  string
	AccountID string
}

var creds Credentials

func New(c Credentials) *IBEXHub {
	creds = c
	x := IBEXHub{
		endpoints: map[string]string{
			"GET_INVOICE_DETAILS": "https://ibexhub.ibexmercado.com/invoice/from-bolt11/%s",
			"GET_PAYMENT_DETAILS": "https://ibexhub.ibexmercado.com/payment/from-bolt11/%s",
			"CREATE_INVOICE":      "https://ibexhub.ibexmercado.com/invoice/add",
			"PAY_INVOICE":         "https://ibexhub.ibexmercado.com/v2/invoice/pay",
			"CANCEL_INVOICE":      "https://ibexhub.ibexmercado.com/invoice/bolt11/%s",
			"LOGIN":               "https://ibexhub.ibexmercado.com/auth/signin",
		},
		defaultHttpHeaders: map[string]string{
			"Authorization": "",
			"content-type":  "application/json",
		},
	}

	loginResp, err := x.login()
	if err != nil {
		log.Print(err)
		return nil
	}
	log.Print("setting token")
	x.defaultHttpHeaders["Authorization"] = loginResp.AccessToken

	return &x
}

func (x IBEXHub) CreateInvoice(config lightning.InvoiceParams, status chan lightning.InvoiceStatus) (*lightning.InvoiceData, error) {
	var (
		shouldRetry bool
		retryCount  int
		err         error
		createResp  *http.Response
		createBody  = createBolt11Body{
			AccountID:  creds.AccountID,
			AmountMsat: config.AmountMsat,
			Memo:       config.Memo,
			Expiration: config.ExpirySeconds,
		}
	)

	if config.MemoUnhashed != nil {
		createBody.MemoUnhashed = config.MemoUnhashed
	}

	for {
		createResp, err = shared.Post(x.endpoints["CREATE_INVOICE"], createBody, &x.defaultHttpHeaders)
		if err != nil {
			return nil, err
		}
		defer createResp.Body.Close()

		if createResp.StatusCode == http.StatusUnauthorized {
			loginResp, err := x.login()
			if err != nil {
				return nil, err
			}
			x.defaultHttpHeaders["Authorization"] = loginResp.AccessToken
			shouldRetry = true
		} else if createResp.StatusCode != http.StatusCreated {
			b, err := io.ReadAll(createResp.Body)
			if err != nil {
				return nil, err
			}
			return nil, fmt.Errorf("error(%d): %s", createResp.StatusCode, b)
		}

		if !shouldRetry || retryCount > 0 {
			break
		}

		retryCount += 1
	}

	res := &createBolt11Response{}
	if err := shared.DecodeBody(createResp.Body, res); err != nil {
		return nil, err
	}

	log.Printf("trackInvoiceStatus: %s", res.Invoice)
	go x.trackInvoiceStatus(res.Invoice, status)

	return &lightning.InvoiceData{
		Invoice:    res.Invoice,
		CheckingID: res.Invoice,
	}, err
}

func (x IBEXHub) GetInvoiceStatus(checkingID string) (*lightning.InvoiceStatus, error) {
	var (
		shouldRetry bool
		retryCount  int
		err         error
		getResp     *http.Response
	)

	for {
		getResp, err = shared.Get(fmt.Sprintf(x.endpoints["GET_INVOICE_DETAILS"], checkingID), &x.defaultHttpHeaders)
		if err != nil {
			return nil, err
		}
		defer getResp.Body.Close()

		if getResp.StatusCode == http.StatusUnauthorized {
			loginResp, err := x.login()
			if err != nil {
				return nil, err
			}
			x.defaultHttpHeaders["Authorization"] = loginResp.AccessToken
			shouldRetry = true
		} else if getResp.StatusCode != http.StatusOK {
			b, err := io.ReadAll(getResp.Body)
			if err != nil {
				return nil, err
			}
			return nil, fmt.Errorf("error(%d): %s", getResp.StatusCode, b)
		}

		if !shouldRetry || retryCount > 0 {
			break
		}

		retryCount += 1
	}

	res := &getInvoiceResponse{}
	if err := shared.DecodeBody(getResp.Body, res); err != nil {
		return nil, err
	}

	var state lightning.InvoiceState
	switch res.StateID {
	case OPEN:
		state = lightning.Open
	case SETTLED:
		state = lightning.Settled
	case CANCEL:
		state = lightning.Cancel
	case ACCEPTED:
		state = lightning.Accepted
	}

	return &lightning.InvoiceStatus{
		CheckingID:       checkingID,
		Exists:           true,
		Status:           state,
		MSatoshiReceived: int64(res.ReceiveMsat),
	}, err
}

func (x IBEXHub) trackInvoiceStatus(checkingID string, statuschan chan lightning.InvoiceStatus) {
	for {
		status, err := x.GetInvoiceStatus(checkingID)
		if err != nil || !status.Exists {
			log.Printf("can't find hash: %s", status.CheckingID)
			break
		}

		if status.Status == lightning.Settled ||
			status.Status == lightning.Cancel ||
			status.Status == lightning.Accepted {
			statuschan <- lightning.InvoiceStatus{
				CheckingID:       status.CheckingID,
				Exists:           true,
				Status:           status.Status,
				MSatoshiReceived: status.MSatoshiReceived,
			}
			break
		}

		time.Sleep(time.Second)
	}
}

func (x IBEXHub) MakePayment(config lightning.PaymentParams, status chan lightning.PaymentStatus) (*lightning.PaymentData, error) {
	var (
		shouldRetry bool
		retryCount  int
		err         error
		payResp     *http.Response
		payBody     = payBolt11Body{
			AccountID: creds.AccountID,
			Bolt11:    config.Bolt11,
		}
	)

	go func() {
		for {
			payResp, err = shared.Post(x.endpoints["PAY_INVOICE"], payBody, &x.defaultHttpHeaders)
			if err != nil {
				log.Printf("shared.Post err: %s", err.Error())
				return
			}
			defer payResp.Body.Close()

			if payResp.StatusCode == http.StatusUnauthorized {
				loginResp, err := x.login()
				if err != nil {
					log.Printf("login err: %s", err.Error())
					return
				}
				x.defaultHttpHeaders["Authorization"] = loginResp.AccessToken
				shouldRetry = true
			}

			if !shouldRetry || retryCount > 0 {
				break
			}

			retryCount += 1
		}

		go x.trackPaymentStatus(config.Bolt11, status)
	}()

	return &lightning.PaymentData{
		CheckingID: config.Bolt11,
	}, err
}

func (x IBEXHub) GetPaymentStatus(checkingID string) (*lightning.PaymentStatus, error) {
	var (
		shouldRetry bool
		retryCount  int
		err         error
		getResp     *http.Response
	)

	for {
		getResp, err = shared.Get(fmt.Sprintf(x.endpoints["GET_PAYMENT_DETAILS"], checkingID), &x.defaultHttpHeaders)
		if err != nil {
			return nil, err
		}
		defer getResp.Body.Close()

		if getResp.StatusCode == http.StatusUnauthorized {
			loginResp, err := x.login()
			if err != nil {
				return nil, err
			}
			log.Print("setting token")
			x.defaultHttpHeaders["Authorization"] = loginResp.AccessToken
			shouldRetry = true
		} else if getResp.StatusCode == http.StatusNotFound {
			// status not found when payment is in flight
			return &lightning.PaymentStatus{
				Status: lightning.Pending,
			}, err
		} else if getResp.StatusCode != http.StatusOK {
			b, err := io.ReadAll(getResp.Body)
			if err != nil {
				return nil, err
			}

			return nil, fmt.Errorf("error(%d): %s", getResp.StatusCode, b)
		}

		if !shouldRetry || retryCount > 0 {
			break
		}

		retryCount += 1
	}

	res := &getPaymentResponse{}
	if err := shared.DecodeBody(getResp.Body, res); err != nil {
		return nil, err
	}

	status := lightning.Failed
	if res.StatusID == SUCCEEDED {
		status = lightning.Complete
	} else if res.StatusID == INFLIGHT {
		status = lightning.Pending
	} else if res.StatusID == UNKNOWN {
		status = lightning.Unknown
	}

	return &lightning.PaymentStatus{
		CheckingID:   checkingID,
		Status:       status,
		FeePaid:      int64(res.FeeMsat),
		Preimage:     res.Preimage,
		MSatoshiPaid: int64(res.PaidMsat),
	}, err
}

func (x IBEXHub) trackPaymentStatus(checkingID string, statuschan chan lightning.PaymentStatus) {
	for {
		log.Printf("trackPaymentStatus")
		status, err := x.GetPaymentStatus(checkingID)
		if err != nil {
			log.Printf("err getPaymentStatus: %s", err.Error())
			break
		}

		if status.Status == lightning.Complete ||
			status.Status == lightning.Failed ||
			status.Status == lightning.Unknown {
			statuschan <- lightning.PaymentStatus{
				CheckingID:   status.CheckingID,
				Status:       status.Status,
				FeePaid:      status.FeePaid,
				Preimage:     status.Preimage,
				MSatoshiPaid: status.MSatoshiPaid,
			}
			break
		}

		time.Sleep(time.Second)
	}
}

func (x IBEXHub) CancelInvoice(bolt11 string) error {
	var (
		shouldRetry bool
		retryCount  int
		err         error
		getResp     *http.Response
	)

	for {
		getResp, err = shared.Delete(fmt.Sprintf(x.endpoints["CANCEL_INVOICE"], bolt11), &x.defaultHttpHeaders)
		if err != nil {
			return err
		}
		defer getResp.Body.Close()

		if getResp.StatusCode == http.StatusUnauthorized {
			loginResp, err := x.login()
			if err != nil {
				return err
			}
			x.defaultHttpHeaders["Authorization"] = loginResp.AccessToken
			shouldRetry = true
		} else if getResp.StatusCode != http.StatusOK {
			b, err := io.ReadAll(getResp.Body)
			if err != nil {
				return err
			}
			return fmt.Errorf("error(%d): %s", getResp.StatusCode, b)
		}

		if !shouldRetry || retryCount > 0 {
			break
		}

		retryCount += 1
	}

	return nil
}

func (x IBEXHub) login() (*loginResponse, error) {
	requestBody := loginBody{
		Email:    creds.Email,
		Password: creds.Password,
	}

	response, err := shared.Post(x.endpoints["LOGIN"], requestBody, &x.defaultHttpHeaders)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()

	if response.StatusCode != http.StatusOK {
		b, err := io.ReadAll(response.Body)
		if err != nil {
			return nil, err
		}
		return nil, fmt.Errorf("error(%d): %s", response.StatusCode, b)
	}

	loginResp := &loginResponse{}
	if err := shared.DecodeBody(response.Body, loginResp); err != nil {
		return nil, err
	}

	if err != nil {
		return nil, err
	}

	return loginResp, nil
}
