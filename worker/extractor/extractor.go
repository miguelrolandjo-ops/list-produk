// Package extractor turns PO photos into the extraction JSON described in
// docs/build-guide.md section 9. The model behind it is hidden by Extractor,
// so it can be swapped without touching the queue or the app.
package extractor

import (
	"context"
	"fmt"
	"time"
)

// Result is the extraction contract. The owner's phone parses this JSON, so
// field names and nullability must not change without updating the app.
type Result struct {
	Supplier Supplier `json:"supplier"`
	PODate   *string  `json:"po_date"` // "2006-01-02", nil if unreadable
	Lines    []Line   `json:"lines"`
}

type Supplier struct {
	Name       *string `json:"name"`
	Phone      *string `json:"phone"`
	Address    *string `json:"address"`
	Confidence float64 `json:"confidence"`
}

// Line is one printed line of the PO. Anything the model could not read is nil
// rather than a guess; the app highlights low-confidence and missing fields.
type Line struct {
	Name       string         `json:"name"`
	Qty        *float64       `json:"qty"`
	Unit       *string        `json:"unit"`
	UnitPrice  *int64         `json:"unit_price"` // whole Rupiah
	Confidence LineConfidence `json:"confidence"`
}

type LineConfidence struct {
	Name      float64 `json:"name"`
	Qty       float64 `json:"qty"`
	UnitPrice float64 `json:"unit_price"`
}

// Extractor reads the pages of one PO (JPEG bytes, in page order).
type Extractor interface {
	Extract(ctx context.Context, pages [][]byte) (Result, error)
}

// New picks an implementation by name (the EXTRACTOR environment variable).
func New(kind string) (Extractor, error) {
	switch kind {
	case "", "fake":
		return NewFake(), nil
	case "ollama", "cloud":
		return nil, fmt.Errorf("extractor %q is not implemented yet (milestone 5)", kind)
	default:
		return nil, fmt.Errorf("unknown extractor %q (use fake, ollama or cloud)", kind)
	}
}

// Validate rejects results the app should never have to cope with. Model
// output is untrusted: check it before it is stored for the owner's phone.
func (r Result) Validate() error {
	if r.PODate != nil {
		if _, err := time.Parse("2006-01-02", *r.PODate); err != nil {
			return fmt.Errorf("po_date %q is not YYYY-MM-DD", *r.PODate)
		}
	}
	if err := checkConfidence("supplier.confidence", r.Supplier.Confidence); err != nil {
		return err
	}
	for i, l := range r.Lines {
		at := fmt.Sprintf("lines[%d]", i)
		if l.Name == "" {
			return fmt.Errorf("%s: name is empty", at)
		}
		if l.Qty != nil && *l.Qty <= 0 {
			return fmt.Errorf("%s: qty must be positive", at)
		}
		if l.UnitPrice != nil && *l.UnitPrice <= 0 {
			return fmt.Errorf("%s: unit_price must be positive", at)
		}
		for name, c := range map[string]float64{
			"name": l.Confidence.Name, "qty": l.Confidence.Qty, "unit_price": l.Confidence.UnitPrice,
		} {
			if err := checkConfidence(at+".confidence."+name, c); err != nil {
				return err
			}
		}
	}
	return nil
}

func checkConfidence(field string, c float64) error {
	if c < 0 || c > 1 {
		return fmt.Errorf("%s = %v is outside 0..1", field, c)
	}
	return nil
}
