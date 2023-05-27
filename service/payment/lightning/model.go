package lightning

type Provider interface {
	CreateInvoice(InvoiceParams, chan InvoiceStatus) (*InvoiceData, error)
	GetInvoiceStatus(string) (*InvoiceStatus, error)

	MakePayment(PaymentParams, chan PaymentStatus) (*PaymentData, error)
	GetPaymentStatus(string) (*PaymentStatus, error)

	CancelInvoice(string) error
}

type InvoiceParams struct {
	Memo string
	// description hash. Priority over memo
	MemoUnhashed  *string
	AmountMsat    uint64
	ExpirySeconds int
}

type InvoiceData struct {
	Invoice    string
	CheckingID string
}

type InvoiceState string

const (
	Open     InvoiceState = "OPEN"
	Settled  InvoiceState = "SETTLED"
	Cancel   InvoiceState = "CANCEL"
	Accepted InvoiceState = "ACCEPTED"
)

type InvoiceStatus struct {
	Status           InvoiceState `json:"status"`
	CheckingID       string       `json:"checkingID"`
	MSatoshiReceived int64        `json:"msatoshiReceived"`
	Exists           bool         `json:"exists"`
}

type PaymentParams struct {
	Bolt11     string
	AmountMsat uint64
}

type PaymentData struct {
	CheckingID string
}

type PaymentState string

const (
	Unknown  PaymentState = "UNKNOWN"
	Pending  PaymentState = "PENDING"
	Failed   PaymentState = "FAILED"
	Complete PaymentState = "COMPLETE"
)

type PaymentStatus struct {
	Status       PaymentState `json:"status"`
	CheckingID   string       `json:"checkingID"`
	Preimage     string       `json:"preimage"`
	FeePaid      int64        `json:"feePaid"`
	MSatoshiPaid int64        `json:"msatoshiPaid"`
}
