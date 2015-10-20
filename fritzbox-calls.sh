#!/bin/bash

# Version 1.1

## Edit this ##
FRITZBOX="IP_OF_FRITZBOX"
PASSWORD="ROOT_PASSWORD_OF_FRITZBOX"

## script ##

challengeRsp=$(curl --header "Accept: application/xml" \
    --header "Content-Type: text/plain"     \
    "http://$FRITZBOX/login_sid.lua" 2>/dev/null)
    
challenge=$(echo $challengeRsp | sed "s/^.*<Challenge>//" | sed "s/<\/Challenge>.*$//")

if [[ -z $challenge ]]; then
    echo "No challenge found"
    exit 0
fi

challenge_bf="$challenge-$PASSWORD"
challenge_bf=$(echo -n $challenge_bf | iconv -f ISO8859-1 -t UTF-16LE | md5sum -b)
challenge_bf=$(echo $challenge_bf | sed "s/ .*$//")
response_bf="$challenge-$challenge_bf"

url="http://$FRITZBOX/login_sid.lua"

sidRsp=$(curl --header "Accept: text/html,application/xhtml+xml,application/xml" \
    --header "Content-Type: application/x-www-form-urlencoded"      \
    -d "response=$response_bf" \
    $url 2>/dev/null)
    
sid=$(echo $sidRsp | sed "s/^.*<SID>//" | sed "s/<\/SID>.*$//")

regex="^0+$"
if [[ $sid =~ $regex ]]; then
    echo "Invalid password"
    exit 0
fi

IFS=' '
stats=$(curl --header "Accept: application/xml" \
    --header "Content-Type: text/plain"     \
    "http://$FRITZBOX/fon_num/foncalls_list.lua?sid=$sid" 2>/dev/null)

#Minimize Output
stats=$(echo $stats | sed ':a;N;$!ba;s/\n//g')
stats=$(echo $stats | sed "s/.*(hh:mm)//" )
stats=$(echo $stats | sed "s/btn_form.*$//" )

#Remove Button "add to AddressBook" from FritzBox Output
# also remove all buttons, anchors and images to get plain text in table
stats=$(echo $stats | sed -e 's/<\/\?a\s*[^>]*>//g' )
stats=$(echo $stats | sed -e 's/<\/\?button\s*[^>]*>//g' )
stats=$(echo $stats | sed -e 's/<\/\?img\s*[^>]*>//g' )

# And output it
echo $stats