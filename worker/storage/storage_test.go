package storage

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"listproduk/worker/job"
)

func TestDownloadSendsKeyAndEscapesPath(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.EscapedPath() != "/storage/v1/object/po-images/store/po%201/1.jpg" {
			t.Errorf("path %q", r.URL.EscapedPath())
		}
		if r.Header.Get("apikey") != "sb_secret_x" || r.Header.Get("Authorization") != "" {
			t.Errorf("headers %v", r.Header)
		}
		_, _ = w.Write([]byte("JPEG"))
	}))
	defer srv.Close()

	b, err := New(srv.URL+"/", "sb_secret_x", "po-images").Download(context.Background(), "store/po 1/1.jpg")
	if err != nil || string(b) != "JPEG" {
		t.Fatalf("got %q, %v", b, err)
	}
}

func TestLegacyJWTKeyAlsoGoesInAuthorization(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") != "Bearer eyJabc" {
			t.Errorf("authorization %q", r.Header.Get("Authorization"))
		}
	}))
	defer srv.Close()
	_, _ = New(srv.URL, "eyJabc", "po-images").Download(context.Background(), "a.jpg")
}

func TestMissingObjectIsPermanent(t *testing.T) {
	for _, tc := range []struct {
		status int
		body   string
	}{
		{404, `{"error":"not found"}`},
		{400, `{"statusCode":"404","error":"not_found","message":"Object not found"}`},
	} {
		srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(tc.status)
			_, _ = w.Write([]byte(tc.body))
		}))
		_, err := New(srv.URL, "k", "po-images").Download(context.Background(), "a.jpg")
		srv.Close()
		if !errors.Is(err, job.ErrPermanent) {
			t.Fatalf("%d: want ErrPermanent, got %v", tc.status, err)
		}
	}
}

func TestServerErrorIsRetryable(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(503)
	}))
	defer srv.Close()
	_, err := New(srv.URL, "k", "po-images").Download(context.Background(), "a.jpg")
	if err == nil || errors.Is(err, job.ErrPermanent) {
		t.Fatalf("want a retryable error, got %v", err)
	}
}

func TestDeleteSendsPrefixes(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodDelete || r.URL.Path != "/storage/v1/object/po-images" {
			t.Errorf("%s %s", r.Method, r.URL.Path)
		}
		body, _ := io.ReadAll(r.Body)
		var got map[string][]string
		_ = json.Unmarshal(body, &got)
		if len(got["prefixes"]) != 2 || got["prefixes"][1] != "s/p/2.jpg" {
			t.Errorf("body %s", body)
		}
		_, _ = w.Write([]byte("[]"))
	}))
	defer srv.Close()
	if err := New(srv.URL, "k", "po-images").Delete(context.Background(), []string{"s/p/1.jpg", "s/p/2.jpg"}); err != nil {
		t.Fatal(err)
	}
}
