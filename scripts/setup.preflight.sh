#!/bin/bash -x

EXTERNAL_IP=$(curl -s -m 10 http://whatismyip.akamai.com/)

bash -x /root/setup.sh 2>&1 | tee -a /root/setup.log
bash -x /root/deploy.sh 2>&1 | tee -a /root/deploy.log
echo "Finished preflight"