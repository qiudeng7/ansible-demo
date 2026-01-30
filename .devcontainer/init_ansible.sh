ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa

cp /root/.ssh/id_rsa.pub /ansible-demo/pub_key

sleep 365d