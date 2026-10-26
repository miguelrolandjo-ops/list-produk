// Package storage reads and deletes PO photos in Supabase Storage with the
// service key. Only the worker has that key; it never goes into the app.
package storage

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"listproduk/worker/job"
)

// Client talks to one bucket.
type Client struct {
	BaseURL string // https://<project>.supabase.co
	Key     string // legacy service_role key, or a new sb_secret_... key
	Bucket  string // "po-images"
	HTTP    *http.Client
}

// New returns a client for bucket.
func New(baseURL, key, bucket string) *Client {
	return &Client{
		BaseURL: strings.TrimRight(baseURL, "/"),
		Key:     key,
		Bucket:  bucket,
		HTTP:    &http.Client{Timeout: 60 * time.Second},
	}
}

func (c *Client) objectURL(path string) string {
	parts := strings.Split(path, "/")
	for i, p := range parts {
		parts[i] = url.PathEscape(p)
	}
	return fmt.Sprintf("%s/storage/v1/object/%s/%s",
		c.BaseURL, url.PathEscape(c.Bucket), strings.Join(parts, "/"))
}

func (c *Client) authorize(req *http.Request) {
	req.Header.Set("apikey", c.Key)
	// Legacy service_role keys are JWTs and also go in Authorization. The new
	// sb_secret_ keys are not JWTs; the gateway only wants them in apikey.
	if strings.HasPrefix(c.Key, "eyJ") {
		req.Header.Set("Authorization", "Bearer "+c.Key)
	}
}

// Download returns one object. A missing object wraps job.ErrPermanent:
// retrying will not bring it back.
func (c *Client) Download(ctx context.Context, path string) ([]byte, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.objectURL(path), nil)
	if err != nil {
		return nil, err
	}
	c.authorize(req)
	resp, err := c.HTTP.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 50<<20))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode == http.StatusOK {
		return body, nil
	}
	if notFound(resp.StatusCode, body) {
		return nil, fmt.Errorf("object %s not found: %w", path, job.ErrPermanent)
	}
	return nil, fmt.Errorf("storage download %s: %s: %s", path, resp.Status, snippet(body))
}

// Delete removes objects. Objects that are already gone are not an error.
func (c *Client) Delete(ctx context.Context, paths []string) error {
	if len(paths) == 0 {
		return nil
	}
	payload, err := json.Marshal(map[string][]string{"prefixes": paths})
	if err != nil {
		return err
	}
	u := fmt.Sprintf("%s/storage/v1/object/%s", c.BaseURL, url.PathEscape(c.Bucket))
	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, u, bytes.NewReader(payload))
	if err != nil {
		return err
	}
	c.authorize(req)
	req.Header.Set("Content-Type", "application/json")
	resp, err := c.HTTP.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<16))
	if resp.StatusCode >= 300 {
		return fmt.Errorf("storage delete: %s: %s", resp.Status, snippet(body))
	}
	return nil
}

// Supabase Storage answers a missing object with 404, or with 400 and
// "not_found" in the body, depending on the version.
func notFound(status int, body []byte) bool {
	if status == http.StatusNotFound {
		return true
	}
	b := strings.ToLower(string(body))
	return status == http.StatusBadRequest &&
		(strings.Contains(b, "not_found") || strings.Contains(b, "not found"))
}

func snippet(b []byte) string {
	s := strings.TrimSpace(string(b))
	if len(s) > 200 {
		s = s[:200] + "…"
	}
	return s
}
