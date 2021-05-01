~~~
sudo yum install gcc openssl-devel bzip2-devel zlib-devel libffi libffi-devel -y
sudo yum install libsqlite3x-devel -y
sudo yum groupinstall "Development Tools" -y
sudo yum install python3-devel gmp-devel  boost-devel libsodium-devel -y

sudo wget https://www.python.org/ftp/python/3.7.7/Python-3.7.7.tgz
sudo tar -zxvf Python-3.7.7.tgz ; cd Python-3.7.7
./configure --enable-optimizations; sudo make -j$(nproc) altinstall; cd ..

git clone https://github.com/Chia-Network/chia-blockchain.git -b latest

cd chia-blockchain

sh install.sh
. ./activate

chia init
chia keys generate

git submodule update
cd chia-blockchain-gui
git fetch
npm install

npm run build
npm run electron


chia plots create -k 32 -n 1 -t /home/otheos/Farm/tmp -d /home/otheos/Farm/plot -e &
~~~
