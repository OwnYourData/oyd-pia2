#!/bin/bash

# download relevant files
wget -q https://raw.githubusercontent.com/OwnYourData/oyd-pia2/master/local/base_setup_template.yml
wget -q https://raw.githubusercontent.com/OwnYourData/oyd-pia2/master/local/env_template
# ask options
echo Beantworte die folgenden Fragen, um den OwnYourData Datentresor zu installieren!
read -p 'IP-Adresse: ' oyd_ip_address
read -p 'Port: ' oyd_port
read -p 'Gmail Benutzer: ' oyd_gmail_user
read -sp 'Gmail Passwort: ' oyd_gmail_pwd
secret_key=`od  -vN "64" -An -tx1 /dev/urandom | tr -d " \n" ; echo`

export SECRET_KEY=$secret_key
export OYD_IP_ADDRESS=$oyd_ip_address
export OYD_PORT=$oyd_port
export OYD_GMAIL_USER=$oyd_gmail_user
export OYD_GMAIL_PWD=$oyd_gmail_pwd

# write .env file
rm -f .env base_setup.yml 2> /dev/null
envsubst < "env_template" > ".env"
envsubst < "base_setup_template.yml" > "base_setup.yml"

# start containers
printf "\nDanke für die Eingabe, der Datentresor wird nun installiert\n"
docker pull oydeu/srv-worker
docker pull oydeu/oyd-pia2
docker pull rabbitmq:3-management
docker pull postgres:9.6.12
docker pull oydeu/srv-scheduler
docker rm -f oyd_web_1 oyd_worker_1 oyd_mq_1 oyd_db_1 2> /dev/null
docker-compose -f base_setup.yml -p oyd up -d

# post-installation actions
docker exec -it oyd_web_1 rake db:create
docker exec -it oyd_web_1 rake db:migrate
docker exec -it oyd_web_1 bash -c "echo 'Doorkeeper::Application.destroy_all' | rails c"
docker exec -it oyd_web_1 bash -c "echo 'Doorkeeper::Application.create!({name: \"web\", redirect_uri: \"https://localhost:3000/oauth/callback\"})' | rails c"
docker exec -it oyd_web_1 bash -c "echo 'Doorkeeper::Application.create!({name: \"scheduler\", redirect_uri: \"https://localhost:3000/oauth/callback\"})' | rails c"
docker exec -it oyd_mq_1 bash -c "rabbitmqctl change_password guest guest_secret; rabbitmqctl add_user test test; rabbitmqctl set_user_tags test administrator; rabbitmqctl delete_vhost /; rabbitmqctl add_vhost oyd; rabbitmqctl set_permissions -p oyd test '.*' '.*' '.*'"
docker-compose -f base_setup.yml -p oyd restart worker

# write crontab
scheduler_key=$(docker exec -it oyd_web_1 bash -c "echo 'ActiveRecord::Base.logger.level = 1; puts Doorkeeper::Application.find_by_name(\"scheduler\").uid' | rails c" | tail -3 | head -1 | tr -d $'\r')
scheduler_secret=$(docker exec -it oyd_web_1 bash -c "echo 'ActiveRecord::Base.logger.level = 1; puts Doorkeeper::Application.find_by_name(\"scheduler\").secret' | rails c" | tail -3 | head -1 | tr -d $'\r')
( crontab -l | grep -v -F "oyd_web_1"; echo "30 * * * * docker run --rm -e QUEUE_HOST=queue -e QUEUE_VHOST=oyd -e QUEUE_USER=test -e QUEUE_PWD=test -e QUEUE_NAME=tasks --link oyd_mq_1 --link oyd_web_1 oydeu/srv-scheduler /bin/run.sh -u http://${oyd_ip_address}:${oyd_port} -k $scheduler_key -s $scheduler_secret" ) | crontab -
