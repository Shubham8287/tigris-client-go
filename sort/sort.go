// Copyright 2022-2023 Tigris Data, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package sort

import (
	"encoding/json"

	"github.com/tigrisdata/tigris-client-go/driver"
)

const (
	asc  = "$asc"
	desc = "$desc"
)

type Sort interface {
	ToSortOrder() map[string]string
	FieldName() string
}

// Ascending builds an increasing order for given field name.
func Ascending(fieldName string) Order {
	return Order{&fieldSort{fieldName: fieldName, operator: asc}}
}

// Descending builds a decreasing order for given field name.
func Descending(fieldName string) Order {
	return Order{&fieldSort{fieldName: fieldName, operator: desc}}
}

// Ascending builds an increasing order for given field name.
func (o Order) Ascending(fieldName string) Order {
	return append(o, &fieldSort{fieldName: fieldName, operator: asc})
}

// Descending builds a decreasing order for given field name.
func (o Order) Descending(fieldName string) Order {
	return append(o, &fieldSort{fieldName: fieldName, operator: desc})
}

// NewSortOrder creates an array of multiple fields that will be used to sort results.
func NewSortOrder(sort ...Order) Order {
	o := make(Order, 0, len(sort))
	for _, v := range sort {
		o = append(o, v...)
	}

	return o
}

type (
	Expr  []Sort
	Order = Expr
)

// Built serializes the sort order.
func (o Expr) Built() (driver.SortOrder, error) {
	if len(o) == 0 {
		return nil, nil
	}

	sortOrders := make([]json.RawMessage, len(o))
	for i, s := range o {
		b, err := json.Marshal(s.ToSortOrder())
		if err != nil {
			return nil, err
		}
		sortOrders[i] = b
	}

	return sortOrders, nil
}

type fieldSort struct {
	fieldName string
	operator  string
}

func (f *fieldSort) FieldName() string {
	return f.fieldName
}

func (f *fieldSort) ToSortOrder() map[string]string {
	return map[string]string{f.fieldName: f.operator}
}
