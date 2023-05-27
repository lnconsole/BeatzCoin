package ibexhub

import (
	"time"
)

type createBolt11Body struct {
	AccountID    string  `json:"accountId"`
	Memo         string  `json:"memo,omitempty"`
	MemoUnhashed *string `json:"descPrehash"`
	AmountMsat   uint64  `json:"amountMsat"`
	Expiration   int     `json:"expiration"`
}

// type invoice struct {
// 	Bolt11   string `json:"bolt11"`
// 	Preimage string `json:"preImage"`
// }

//	type createBolt11Response struct {
//		Invoice invoice `json:"invoice"`
//	}
type createBolt11Response struct {
	Invoice string `json:"bolt11"`
}

type payBolt11Body struct {
	AccountID string `json:"accountId"`
	Bolt11    string `json:"bolt11"`
}

// type payBolt11Response struct {
// 	Invoice invoice `json:"invoice"`
// }

type InvoiceState int

const (
	OPEN InvoiceState = iota
	SETTLED
	CANCEL
	ACCEPTED
)

type getInvoiceResponse struct {
	StateID     InvoiceState `json:"stateId"`
	ReceiveMsat int          `json:"receiveMsat"`
}

type PaymentStatus int

const (
	UNKNOWN PaymentStatus = iota
	INFLIGHT
	SUCCEEDED
	FAILED
)

type getPaymentResponse struct {
	SettleDateUtc time.Time     `json:"settleDateUtc"`
	Preimage      string        `json:"preImage"`
	StatusID      PaymentStatus `json:"statusId"`
	PaidMsat      int           `json:"paidMsat"`
	FeeMsat       int           `json:"feeMsat"`
}

type loginBody struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type loginResponse struct {
	AccessToken string `json:"accessToken"`
}
