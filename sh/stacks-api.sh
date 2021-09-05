sudo apt-get install postgresql-client-common jq -y

docker pull blockstack/stacks-blockchain-api && docker pull blockstack/stacks-blockchain && docker pull postgres:alpine
docker network create stacks-blockchain > /dev/null 2>&1

mkdir -p ./stacks-node/{persistent-data/postgres,persistent-data/stacks-blockchain,bns,config} && cd stacks-node

curl -L https://storage.googleapis.com/blockstack-v1-migration-data/export-data.tar.gz -o ./bns/export-data.tar.gz

tar -xzvf ./bns/export-data.tar.gz -C ./bns/

for file in `ls ./bns/* | grep -v sha256 | grep -v .tar.gz`; do
    if [ $(sha256sum $file | awk {'print $1'}) == $(cat ${file}.sha256 ) ]; then
        echo "sha256 Matched $file"
    else
        echo "sha256 Mismatch $file"
    fi
done

docker run -d --name postgres --net=stacks-blockchain -e POSTGRES_PASSWORD=postgres -v $(pwd)/persistent-data/postgres:/var/lib/postgresql/data -p 5432:5432 postgres:alpine

docker ps --filter name=postgres

echo '
NODE_ENV=production
GIT_TAG=master
PG_HOST=postgres
PG_PORT=5432
PG_USER=postgres
PG_PASSWORD=postgres
PG_DATABASE=postgres
STACKS_CHAIN_ID=0x00000001
V2_POX_MIN_AMOUNT_USTX=90000000260
STACKS_CORE_EVENT_PORT=3700
STACKS_CORE_EVENT_HOST=0.0.0.0
STACKS_BLOCKCHAIN_API_PORT=3999
STACKS_BLOCKCHAIN_API_HOST=0.0.0.0
STACKS_BLOCKCHAIN_API_DB=pg
STACKS_CORE_RPC_HOST=stacks-blockchain
STACKS_CORE_RPC_PORT=20443
BNS_IMPORT_DIR=/bns-data
' > .env

docker run -d --name stacks-blockchain-api --net=stacks-blockchain --env-file $(pwd)/.env -v $(pwd)/bns:/bns-data -p 3700:3700 -p 3999:3999 blockstack/stacks-blockchain-api

docker ps --filter name=stacks-blockchain-api

echo '
[node]
working_dir = "/root/stacks-node/data"
rpc_bind = "0.0.0.0:20443"
p2p_bind = "0.0.0.0:20444"
bootstrap_node = "02da7a464ac770ae8337a343670778b93410f2f3fef6bea98dd1c3e9224459d36b@seed-0.mainnet.stacks.co:20444,02afeae522aab5f8c99a00ddf75fbcb4a641e052dd48836408d9cf437344b63516@seed-1.mainnet.stacks.co:20444,03652212ea76be0ed4cd83a25c06e57819993029a7b9999f7d63c36340b34a4e62@seed-2.mainnet.stacks.co:20444"
wait_time_for_microblocks = 10000

[[events_observer]]
endpoint = "stacks-blockchain-api:3700"
retry_count = 255
events_keys = ["*"]

[burnchain]
chain = "bitcoin"
mode = "mainnet"
peer_host = "163.172.61.48"
username = ""
password = ""
rpc_port = 8332
peer_port = 8333

[connection_options]
read_only_call_limit_write_length = 0
read_only_call_limit_read_length = 100000
read_only_call_limit_write_count = 0
read_only_call_limit_read_count = 30
read_only_call_limit_runtime = 1000000000
' > ./config/Config.toml

docker run -d --name stacks-blockchain --net=stacks-blockchain -v $(pwd)/persistent-data/stacks-blockchain:/root/stacks-node/data -v $(pwd)/config:/src/stacks-node -p 20443:20443 -p 20444:20444 blockstack/stacks-blockchain /bin/stacks-node start --config /src/stacks-node/Config.toml

docker ps --filter name=stacks-blockchain
