#!/bin/bash
# config_prfile_upgrade.sh

if [ -z "$1" ]
then
     echo "Please provide your OpsCenter IP"
     echo "I.E. ./config_profile_upgrade.sh localhost" 
     exit
fi 

#pull and pick versions
echo "Avaliable versions (if your version isn't here upgrade your opscenter definition files):"
curl http://"$1":8888/api/v1/lcm/definitions/ 2>/dev/null | jq '.dse[].version'
echo "Please pick a version from the list"
read -r version

#check existing profiles
echo "The existing config profiles on $1 are:"
curl "$1":8888/api/v1/lcm/config_profiles/ 2>/dev/null | jq '{ "id":.results[].id , "name": .results[].name}'

#pick and tweak profile
echo "Please enter the id of the profile you want to clone"
read -r id
echo "Please enter the name of your new profile"
read -r name
NEWPROFILE=$(curl "$1":8888/api/v1/lcm/config_profiles/$id 2>/dev/null | jq --arg version "$version" '."datastax-version"|= $version| del(.id)| del(.href)| del(."modified-by")| del(."related-resources")| del(."modified-on") | del(."created-by")|del(."created-on")'|jq --arg name "$name" '.name|= $name')

#write config profile
request_body=$(< <(cat <<EOF
$NEWPROFILE
EOF
)) &>/dev/null

curl -X POST --data "$request_body" "$1":8888/api/v1/lcm/config_profiles/ &> /dev/null

echo "http://$1:8888/opscenter/lcm.html#/config_profiles"

