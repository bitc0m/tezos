#!/bin/sh
PREFIX=/usr/local/bin
WORK=$HOME/$(whoami)

#download copy of linux opam 2.0.0-rc3 build and save as /usr/local/bin/opam
sudo curl -o $PREFIX/opam -L https://github.com/ocaml/opam/releases/download/2.0.0-rc3/opam-2.0.0-rc3-x86_64-linux 

#make opam executable
sudo chmod a+x $PREFIX/opam

#install build essentials
sudo apt-get install -y patch unzip make gcc m4 git g++ aspcud bubblewrap pkg-config libhidapi-dev

#initiate Opam
$PREFIX/opam init -y --compiler=4.06.1

#evalute configuration environment
eval $(opam env)

#clone the tezos gitlab repo
git clone -b betanet https://gitlab.com/tezos/tezos.git & wait
{ sleep 5; } & wait

cd tezos

#build project dependencies
make build-deps

#update opam environment
eval $(opam env)

#build tayzos
make

#generate identity
./tezos-node identity generate

#add aliases to profile
echo "alias betanet='./tezos-client --addr 127.0.0.1 --port 8732'" >> ~/.profile
echo "alias run_node='./tezos-node run --rpc-addr 127.0.0.1:8732 --connections 10'" >> ./.profile
echo "alias run_baker='./tezos-alpha-baker run with local node /home/tezos/.tezos-node <implicit_acct>'" >> ./.profile
echo "alias run_endorser='./tezos-alpha-endorser run <implicit_acct>'" >> ./.profile
echo "alias run_accuser='./tezos-alpha accuser run'" >> ./.profile

#reload profile
source ~/.profile

#pull list of betanet peers
PEERS=$(curl -s 'http://api5.tzscan.io/v1/network?state=running&p=0&number=50' | grep -Po '::ffff:([0-9.:]+)' | sed ':a;N;$!ba;s/\n/ /g' | sed 's/::ffff:/--peer=/g')

#sync the node
nohup ./tezos-node run --rpc-addr 127.0.0.1:8732 --connections 10 $PEERS &

