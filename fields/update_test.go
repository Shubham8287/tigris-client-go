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

package fields

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestUpdateBasic(t *testing.T) {
	cases := []struct {
		name   string
		fields *Update
		exp    string
		err    error
	}{
		{"set", Set("a", 123), `{"$set":{"a":123}}`, nil},
		{"unset", Unset("a"), `{"$unset":{"a":null}}`, nil},
		{"set.unset", Set("a", 123).Unset("b"), `{"$set":{"a":123},"$unset":{"b":null}}`, nil},
		{"unset.set", Unset("a").Set("b", "aaa"), `{"$set":{"b":"aaa"},"$unset":{"a":null}}`, nil},
		{"set.set.unset.unset", Set("a", 123).Set("b", "uuu").Unset("c").Unset("d"), `{"$set":{"a":123,"b":"uuu"},"$unset":{"c":null,"d":null}}`, nil},
		{"unset.set.unset.set", Unset("a1").Set("b1", "aaa").Unset("a2").Set("b2", "aaa"), `{"$set":{"b1":"aaa","b2":"aaa"},"$unset":{"a1":null,"a2":null}}`, nil},
		{"set.unset.set.unset", Set("a1", 123).Unset("b1").Set("a2", 123).Unset("b2"), `{"$set":{"a1":123,"a2":123},"$unset":{"b1":null,"b2":null}}`, nil},
		{"set_nested", Set("a.b.c", 123), `{"$set":{"a.b.c":123}}`, nil},
		{"unset_nested", Unset("a.b.c"), `{"$unset":{"a.b.c":null}}`, nil},
		{"set.unset_duplicate", Set("a1", 123).Unset("b1").Set("a1", 123).Unset("b1"), `{"$set":{"a1":123},"$unset":{"b1":null}}`, nil},
	}

	for _, v := range cases {
		t.Run(v.name, func(t *testing.T) {
			b, err := v.fields.Build()
			assert.Equal(t, v.err, err)
			assert.Equal(t, v.exp, string(b.Built()))
		})
	}

	_, err := UpdateBuilder().Build()
	require.Equal(t, fmt.Errorf("empty update"), err)
}
