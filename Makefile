VERSION=$(shell git describe --tags --always)
GO_SRC=$(shell find . -name "*.go" -not -name "*_test.go")
API_DIR=api
V=v1
GEN_DIR=${API_DIR}/server/${V}
PROTO_DIR=${API_DIR}/proto/server/${V}

BUILD_PARAM=-tags=release -ldflags "-X 'main.Version=$(VERSION)'" $(shell printenv BUILD_PARAM)
TEST_PARAM=-cover -race -tags=test $(shell printenv TEST_PARAM)

all: generate ${GO_SRC}
	#go build ${BUILD_PARAM} .

${GEN_DIR}/%.proto ${GEN_DIR}/%_openapi.yaml:
	git submodule update --init --recursive --rebase

upgrade_api:
	git submodule update --remote --recursive --rebase

# generate GRPC client/server, openapi spec, http server
${GEN_DIR}/%.pb.go: ${PROTO_DIR}/%.proto
	protoc -Iapi/proto --go_out=${API_DIR} --go_opt=paths=source_relative \
		--go-grpc_out=${API_DIR} --go-grpc_opt=require_unimplemented_servers=false,paths=source_relative \
		--grpc-gateway_out=${API_DIR} --grpc-gateway_opt=paths=source_relative,allow_delete_body=true \
		$<

# generate Go HTTP client from openapi spec
${API_DIR}/client/${V}/%/http.go: ${PROTO_DIR}/%_openapi.yaml
	/bin/bash scripts/fix_openapi.sh ${PROTO_DIR}/$(*F)_openapi.yaml /tmp/$(*F)_openapi.yaml
	mkdir -p ${API_DIR}/client/${V}/$(*F)
	oapi-codegen -package api -generate "client, types, spec" \
		-o ${API_DIR}/client/${V}/$(*F)/http.go \
		/tmp/$(*F)_openapi.yaml

generate: ${GEN_DIR}/api.pb.go ${GEN_DIR}/health.pb.go ${API_DIR}/client/${V}/api/http.go

mock/api_grpc.go: generate
	mkdir -p mock
	mockgen -package mock -destination mock/api_grpc.go github.com/tigrisdata/tigrisdb-client-go/api/server/v1 TigrisDBServer

mock: mock/api_grpc.go

lint:
	yq --exit-status 'tag == "!!map" or tag== "!!seq"' .github/workflows/*.yaml
	shellcheck scripts/*
	golangci-lint run

go.sum: go.mod mock generate
	go mod download

test: go.sum generate mock lint
	go test $(TEST_PARAM) ./...

clean:
	rm -f mock/api_grpc.go