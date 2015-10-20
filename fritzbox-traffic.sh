#!/bin/bash

# Version 1.0 

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
    "http://$FRITZBOX/internet/inetstat_counter.lua?sid=$sid" 2>/dev/null)

stats=$(echo $stats | grep "inetstat:" | sed "s/inetstat:status\///" | sed 's/[["\]//g' | sed 's/\]//' | sed 's/ = / /' | sed 's/,//' | sed 's/\// /' | sed 's/^ //')

IFS=$'\n'
regex="([a-zA-Z]+) ([a-zA-Z]+) ([0-9]+)"
for line in $stats; do
    if [[ $line =~ $regex ]]; then
        date=${BASH_REMATCH[1]}
        type=${BASH_REMATCH[2]}
        value=${BASH_REMATCH[3]}
		bytessenthigh=0
        if [[ "$date" == "ThisMonth" ]]; then
            case "$type" in
                "BytesReceivedLow")
                    bytesreclow=$value
                    ;;
                "BytesReceivedHigh")
                    bytesrechigh=$value
                    ;;
                "BytesSentLow")
                    bytessentlow=$value
                    ;;
                "BytesSentHigh")
                    bytessenthigh=$value
                    ;;
            esac    
        fi
    fi
done

# We need to convert the output to 64bit - to have the actual traffic
bytesIn=$(($bytesrechigh*4294967296 + $bytesreclow))
bytesOut=$(($bytessenthigh*4294967296 + $bytessentlow))
# Get totals..
bytes=$((bytesIn + $bytesOut))
# Calculate to Gigabytes
bytes=$((bytes / 1000000000))
# And output it
echo "$bytes"
