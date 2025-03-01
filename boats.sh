#!/usr/bin/env bash

usage() {
    echo "usage: $0 [-o|-s]"
    echo "  -o  Open browser window"
    echo "  -s  Perform new search"
    exit 1
}

outfile=boats.json
distance=1500mi
length=38-50
price=100000-400000
year=1990-2015

# Flags
open=0
search=0

while test $# != 0
do
    case "$1" in
    -o) open=1 ;;
    -s) search=1 ;;
    *)  usage ;;
    esac
    shift
done

if [ $search -eq 1 ]; then
  echo "Refreshing search results..."
  curl -s "https://www.yachtworld.com/yachtworld/search/boat?pageSize=200&page=1&facets=countrySubdivision,make,condition,makeModel,type,class,country,countryRegion,countryCity,fuelType,hullMaterial,hullShape,minYear,maxYear,minMaxPercentilPrices,enginesConfiguration,enginesDriveType,numberOfEngines&fields=id,make,model,year,featureType,specifications.dimensions.lengths.nominal,location.address,aliases,owner.logos,owner.name,owner.rootName,owner.location.address.city,owner.location.address.country,price.hidden,price.type.amount,portalLink,class,media,isOemModel,isCurrentModel,attributes,previousPrice,mediaCount,cpybLogo&useMultiFacetedFacets=true&enableSponsoredSearch=true&enablePremiumPlacement=false&enableOEM=true&locale=en-US&distance=$distance&radius=true&length=$length&uom=ft&sort=recommended&year=$year&fuelType=diesel&multiFacetedBoatTypeClass=\[%22power%22\]&price=$price&currency=USD&advantageSort=1&enableSponsoredSearchExactMatch=true&randomizedSponsoredBoatsSearch=true&randomSponsoredBoatsSize=0" -o $outfile
fi

# Create boats.js
ignore='"Bayliner","Carver","North Pacific","Sea Ray","Mainship","Meridian","Navigator","Formula","Fountain","DeFever","Silverton"'
query="[[.search.records[] | select(.make | IN($ignore) | not)][] | { id: .id, type: ((.year|tostring) + \" \" + .make + \" \" + .model), price: .price.type.amount.USD, length: .specifications.dimensions.lengths.nominal.ft, location: (.location.address.city + \" \" + .location.address.subdivision), url: .portalLink, image: .media[0].url }]"
echo "const boats = $(jq -r "$query" $outfile)" > boats.js

if [ $open -eq 1 ]; then
  open boats.html
fi
