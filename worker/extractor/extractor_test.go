package extractor

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"strings"
	"testing"
)

// The example from docs/build-guide.md section 9, verbatim.
const contractExample = `{
  "supplier": { "name": "CV Maju Elektrik", "phone": "0812xxxx", "address": "…", "confidence": 0.96 },
  "po_date": "2026-10-04",
  "lines": [
    { "name": "Kbl Type C 100cm", "qty": 20, "unit": "pcs", "unit_price": 9500,
      "confidence": { "name": 0.97, "qty": 0.99, "unit_price": 0.95 } }
  ]
}`

func TestContractExampleParses(t *testing.T) {
	var r Result
	if err := json.Unmarshal([]byte(contractExample), &r); err != nil {
		t.Fatal(err)
	}
	if err := r.Validate(); err != nil {
		t.Fatal(err)
	}
	l := r.Lines[0]
	if l.Name != "Kbl Type C 100cm" || *l.Qty != 20 || *l.Unit != "pcs" || *l.UnitPrice != 9500 {
		t.Fatalf("unexpected line: %+v", l)
	}
	if *r.PODate != "2026-10-04" || *r.Supplier.Name != "CV Maju Elektrik" {
		t.Fatalf("unexpected header: %+v", r)
	}
}

func TestNullsStayNullInJSON(t *testing.T) {
	r := Result{Lines: []Line{{Name: "Sarung"}}}
	b, err := json.Marshal(r)
	if err != nil {
		t.Fatal(err)
	}
	var m map[string]any
	if err := json.Unmarshal(b, &m); err != nil {
		t.Fatal(err)
	}
	if v, ok := m["po_date"]; !ok || v != nil {
		t.Fatalf("po_date should be present and null, got %v", v)
	}
	line := m["lines"].([]any)[0].(map[string]any)
	for _, k := range []string{"qty", "unit", "unit_price"} {
		if v, ok := line[k]; !ok || v != nil {
			t.Fatalf("%s should be present and null, got %v", k, v)
		}
	}
}

func TestUnitPriceIsAnIntegerInJSON(t *testing.T) {
	p := int64(9500)
	b, _ := json.Marshal(Line{Name: "x", UnitPrice: &p})
	if !strings.Contains(string(b), `"unit_price":9500`) {
		t.Fatalf("price must serialize as a whole number: %s", b)
	}
	// A model returning 9500.5 must not be accepted silently.
	if err := json.Unmarshal([]byte(`{"name":"x","unit_price":9500.5}`), &Line{}); err == nil {
		t.Fatal("fractional price should be rejected")
	}
}

func TestValidate(t *testing.T) {
	neg := int64(-1)
	zero := 0.0
	cases := map[string]Result{
		"bad date":         {PODate: ptr("04-10-2026")},
		"empty name":       {Lines: []Line{{Name: ""}}},
		"negative price":   {Lines: []Line{{Name: "x", UnitPrice: &neg}}},
		"zero qty":         {Lines: []Line{{Name: "x", Qty: &zero}}},
		"confidence > 1":   {Lines: []Line{{Name: "x", Confidence: LineConfidence{Name: 1.2}}}},
		"supplier conf <0": {Supplier: Supplier{Confidence: -0.1}},
	}
	for name, r := range cases {
		if err := r.Validate(); err == nil {
			t.Errorf("%s: expected an error", name)
		}
	}
	if err := (Result{}).Validate(); err != nil {
		t.Errorf("empty result should be valid: %v", err)
	}
}

func TestFakeExtractorIsValidAndExercisesEdgeCases(t *testing.T) {
	var e Extractor = NewFake()
	r, err := e.Extract(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	if err := r.Validate(); err != nil {
		t.Fatalf("fake output must satisfy the contract: %v", err)
	}
	var missingPrice, lowConfidence bool
	for _, l := range r.Lines {
		if l.UnitPrice == nil {
			missingPrice = true
		} else if l.Confidence.UnitPrice > 0 && l.Confidence.UnitPrice < 0.7 {
			lowConfidence = true
		}
	}
	if !missingPrice || !lowConfidence {
		t.Fatal("fake data should include a missing price and a low-confidence price")
	}
}

func TestFakeExtractorHonoursCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := NewFake().Extract(ctx, nil); err == nil {
		t.Fatal("expected context error")
	}
}

func TestNew(t *testing.T) {
	for _, kind := range []string{"", "fake"} {
		if e, err := New(kind); err != nil || e == nil {
			t.Errorf("New(%q) = %v, %v", kind, e, err)
		}
	}
	for _, kind := range []string{"ollama", "cloud", "nope"} {
		if _, err := New(kind); err == nil {
			t.Errorf("New(%q) should fail for now", kind)
		}
	}
}

// shared/extraction_sample.json is also parsed by the app's tests, so the two
// sides cannot drift apart without a test failing.
func TestFakeMatchesSharedSample(t *testing.T) {
	raw, err := os.ReadFile("../../shared/extraction_sample.json")
	if err != nil {
		t.Fatal(err)
	}
	var want any
	if err := json.Unmarshal(raw, &want); err != nil {
		t.Fatal(err)
	}
	r, _ := NewFake().Extract(context.Background(), nil)
	b, _ := json.Marshal(r)
	var got any
	if err := json.Unmarshal(b, &got); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("fake output differs from shared/extraction_sample.json:\n got: %s", b)
	}
}
