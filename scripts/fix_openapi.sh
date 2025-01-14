#!/bin/bash
# Copyright 2022-2023 Tigris Data, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -e

IN_FILE=$1
OUT_FILE=$2

main() {
	fix_bytes

	# Fix the types of filter and document fields to be object on HTTP wire.
	# The original format in proto file is "bytes", which allows to skip
	# unmarshalling in GRPC, we also implement custom unmarshalling for HTTP
	for i in DeleteRequest UpdateRequest ReadRequest SearchRequest \
			SubscribeRequest CountRequest; do
		yq_fix_json $i filter
	done

	yq_fix_json InsertRequest documents.items
	yq_fix_json ReplaceRequest documents.items
	yq_fix_json UpdateRequest fields
	yq_fix_json ReadRequest fields
	yq_fix_json ReadRequest sort
	yq_fix_json ReadResponse data
	yq_fix_json StreamEvent data
	yq_fix_json SearchHit data
	yq_fix_json CreateOrUpdateCollectionRequest schema
	yq_fix_json CollectionDescription schema
	yq_fix_json DescribeCollectionResponse schema
	yq_fix_json PublishRequest messages.items
	yq_fix_json SubscribeResponse message

	yq_fix_json CreateByIdRequest document
	yq_fix_json DeleteByQueryRequest filter

	yq_fix_json CreateOrUpdateIndexRequest schema
	yq_fix_json IndexInfo schema

	yq_fix_json UpdateDocumentRequest documents.items
	yq_fix_json CreateOrReplaceDocumentRequest documents.items
	yq_fix_json CreateDocumentRequest documents.items

	yq_fix_json SearchIndexRequest filter
	yq_fix_json SearchIndexRequest facet
	yq_fix_json SearchIndexRequest sort.items
	yq_fix_json SearchIndexRequest vector

  # old search request
	yq_fix_json SearchRequest fields
	yq_fix_json SearchRequest facet
	yq_fix_json SearchRequest sort.items
	yq_fix_json SearchRequest vector
}

fix_bytes() {
	# According to the OpenAPI spec format should be "byte",
	# but protoc-gen-openapi generates it as "bytes".
	# We fix it here
	# This is done last to also copy input file to output
	sed -e 's/format: bytes/format: byte/g' "$IN_FILE" >"$OUT_FILE"
}

yq_cmd() {
	yq -I 4 -i "$1" "$OUT_FILE"
}

yq_fix_json() {
	yq_cmd ".components.schemas.$1.properties.$2.format=\"json\""
	yq_cmd ".components.schemas.$1.properties.$2.type=\"string\""
}

main

