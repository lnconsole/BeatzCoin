package shared

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

func DecodeBody(body io.ReadCloser, destination interface{}) error {
	defer body.Close()
	return json.NewDecoder(body).Decode(destination)
}

func EncodeBody(body interface{}) (*bytes.Buffer, error) {
	var requestBody *bytes.Buffer = nil

	if body != nil {
		marshaledBytes, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		requestBody = bytes.NewBuffer(marshaledBytes)
	}

	return requestBody, nil
}

func Get(url string, headers *map[string]string) (*http.Response, error) {
	request, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}

	if headers != nil {
		for headerKey, headerValue := range *headers {
			request.Header.Set(headerKey, headerValue)
		}
	}

	return http.DefaultClient.Do(request)
}

func Post(url string, body interface{}, headers *map[string]string) (*http.Response, error) {
	bodyBuffer, err := EncodeBody(body)
	if err != nil {
		return nil, err
	}

	request, err := http.NewRequest(http.MethodPost, url, bodyBuffer)
	if err != nil {
		return nil, err
	}

	if headers != nil {
		for headerKey, headerValue := range *headers {
			request.Header.Set(headerKey, headerValue)
		}
	}

	return http.DefaultClient.Do(request)
}

func Delete(url string, headers *map[string]string) (*http.Response, error) {
	request, err := http.NewRequest(http.MethodDelete, url, nil)
	if err != nil {
		return nil, err
	}

	if headers != nil {
		for headerKey, headerValue := range *headers {
			request.Header.Set(headerKey, headerValue)
		}
	}

	return http.DefaultClient.Do(request)
}

func FormatUrl(host string) string {
	if strings.Contains(host, "localhost") {
		return fmt.Sprintf("http://%s", host)
	} else {
		return fmt.Sprintf("https://%s", host)
	}
}

func BadLnurlRequest(c *gin.Context, err error) {
	log.Println(err.Error())
	c.AbortWithStatusJSON(http.StatusOK, gin.H{
		"status": "ERROR",
		"reason": err.Error(),
	})
}
