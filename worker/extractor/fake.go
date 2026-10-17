package extractor

import "context"

// FakeExtractor returns fixed sample data so the queue, the app's Inbox and the
// Review screen can be built without a model. The lines are chosen to exercise
// matching: abbreviated names, a cm/m length, a missing price, a low-confidence
// price, and a non-product line.
type FakeExtractor struct{}

func NewFake() *FakeExtractor { return &FakeExtractor{} }

func (*FakeExtractor) Extract(ctx context.Context, pages [][]byte) (Result, error) {
	if err := ctx.Err(); err != nil {
		return Result{}, err
	}
	return Result{
		Supplier: Supplier{
			Name:       ptr("CV Maju Elektrik"),
			Phone:      ptr("0812xxxx"),
			Address:    ptr("Jl. Mangga Dua No. 8, Jakarta"),
			Confidence: 0.96,
		},
		PODate: ptr("2026-10-04"),
		Lines: []Line{
			{Name: "Kbl Type C 100cm", Qty: ptr(20.0), Unit: ptr("pcs"), UnitPrice: ptr(int64(9500)),
				Confidence: LineConfidence{Name: 0.97, Qty: 0.99, UnitPrice: 0.95}},
			{Name: "Kabel Micro USB 1M", Qty: ptr(12.0), Unit: ptr("pcs"), UnitPrice: ptr(int64(7000)),
				Confidence: LineConfidence{Name: 0.98, Qty: 0.97, UnitPrice: 0.96}},
			{Name: "Chrgr Fast 20W", Qty: ptr(6.0), Unit: ptr("pcs"), UnitPrice: ptr(int64(38500)),
				Confidence: LineConfidence{Name: 0.90, Qty: 0.95, UnitPrice: 0.62}},
			{Name: "Sarung HP Silikon", Qty: ptr(2.0), Unit: ptr("dus"), UnitPrice: nil,
				Confidence: LineConfidence{Name: 0.93, Qty: 0.9, UnitPrice: 0}},
			{Name: "Ongkos kirim", Qty: nil, Unit: nil, UnitPrice: ptr(int64(25000)),
				Confidence: LineConfidence{Name: 0.99, Qty: 0, UnitPrice: 0.9}},
		},
	}, nil
}

func ptr[T any](v T) *T { return &v }
