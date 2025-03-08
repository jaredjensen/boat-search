#!/usr/bin/env bash

usage() {
    echo "usage: $0 [-o|-s]"
    echo "  -o  Open browser window"
    echo "  -s  Perform new search"
    exit 1
}

jsfile=boats.js
outfile=boats.json
distance=1500mi
length=38-50
price=100000-400000
year=1990-2015
pagesize=400

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

echo "const boats = [" > $jsfile

if [ $search -eq 1 ]; then
  echo "Refreshing search results..."
  page=1
  while true; do
    printf "$page"
    curl -s "https://www.yachtworld.com/yachtworld/search/boat?pageSize=$pagesize&page=$page&facets=countrySubdivision,make,condition,makeModel,type,class,country,countryRegion,countryCity,fuelType,hullMaterial,hullShape,minYear,maxYear,minMaxPercentilPrices,enginesConfiguration,enginesDriveType,numberOfEngines&fields=id,make,model,year,featureType,specifications.dimensions.lengths.nominal,location.address,aliases,owner.logos,owner.name,owner.rootName,owner.location.address.city,owner.location.address.country,price.hidden,price.type.amount,portalLink,class,media,isOemModel,isCurrentModel,attributes,previousPrice,mediaCount,cpybLogo&useMultiFacetedFacets=true&enableSponsoredSearch=false&enablePremiumPlacement=false&enableOEM=true&locale=en-US&distance=$distance&radius=true&length=$length&uom=ft&sort=recommended&year=$year&fuelType=diesel&multiFacetedBoatTypeClass=\[%22power%22\]&price=$price&currency=USD&advantageSort=1&enableSponsoredSearchExactMatch=true&randomizedSponsoredBoatsSearch=false&randomSponsoredBoatsSize=0" -o $outfile

    records=$(jq -r '.search.records | length' $outfile)
    if [ $? -ne 0 ]; then
      echo "Failed to parse JSON"
      break
    elif [ "$records" -eq "0" ]; then
      break
    fi

    ignore='"Azimut","Bayliner","Beneteau","Bertram","Carver","Cruisers Yachts","DeFever","Formula","Fountain","Jersey","Mainship","Maxum","Meridian","Navigator","North Pacific","Post","Pursuit","Regal","Riviera","Sea Ray","Silverton","Tiara Yachts","Tiara","Viking"'
    query="[.search.records[] | select(.make | IN($ignore) | not)][] | { id: .id, type: ((.year|tostring) + \" \" + .make + \" \" + .model), price: .price.type.amount.USD, length: .specifications.dimensions.lengths.nominal.ft, location: (.location.address.city + \" \" + .location.address.subdivision), url: .portalLink, image: .media[0].url }"
    jq -r "$query" $outfile >> $jsfile

    ((page++))
    printf "."
  done
fi

echo "];" >> $jsfile
sed -i '' -e 's/}/},/g' $jsfile

if [ $open -eq 1 ]; then
  open boats.html
fi
