#!/bin/bash

if [ -z $@ ] &> /dev/null #This is a terrible cosmetic solution for the "too many arguments" problem
then
  printf '\e[1;31m%-6s\e[m\n' "$0 requires arguments use -h for help"
  exit
fi

while getopts ":s:d:cph" opt; do
  case ${opt} in
    s )
      SCRATCH_ORG_ALIAS=$OPTARG
      ;;
    d )
      DEVHUB_ALIAS=$OPTARG
      ;;
    c )
      CREATE_SCRATCH=TRUE
      ;;
    p )
      DEPLOY_SOURCE=TRUE
      ;;
    h )
      printf '\e[1;34m%-6s\e[m\n' "Hello! I support the following parameters:"
      printf '\t%s\n' "-s scratch org name" "-d DevHub name" "-c creates scratch (don't specify if you just want to install packages)" "-p push source to you scratch org"
      exit
      ;;
    \? )
      printf '\e[1;34m%-6s\e[m\n' "Invalid option: $OPTARG" 1>&2
      exit
      ;;
    : )
      printf '\e[1;34m%-6s\e[m\n' "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
  esac
done
shift $((OPTIND -1))

printf '\e[1;34m%-6s\e[m\n' "Hello, please wait while I'm fetching the managed package list from ${DEVHUB_ALIAS}..."

## DEFINE THE LIST OF MANAGED PACKAGES TO INSTALL
sfdx force:package:installed:list -u ${DEVHUB_ALIAS} --json > ManPack_List
printf '\e[1;31m%-6s\e[m\n' "##### PICK MANAGED PACKAGES TO INSTALL #####"
jq -r '[.result[].SubscriberPackageName] | sort | unique | .[]' ManPack_List
osascript -e 'display notification "Managed package list ready!" with title "Scratch Org Butler" sound name "Blow"'
read -rp "Please pick the packages you want me to install (separated by comma):" ManPackage_List

printf '\e[1;34m%-6s\e[m\n' "Thanks,now I'm fetching the unlocked package list from ${DEVHUB_ALIAS}..."

## DEFINE THE LIST OF UNLOCKED PACKAGES TO INSTALL
sfdx force:package:version:list --json > UnlPack_List
printf '\e[1;31m%-6s\e[m\n' "##### PICK UNLOCKED PACKAGES TO INSTALL #####"
jq -r '[.result[].Package2Name] | sort | unique | .[]' UnlPack_List
osascript -e 'display notification "Unlocked package list ready!" with title "Scratch Org Butler" sound name "Blow"'
read -rp "Please pick the packages you want me to install:" UnlPackage_List

printf '\e[1;34m%-6s\e[m\n' "Thanks, I'll be right back with you scratch org..."

printf '\e[1;31m%-6s\e[m\n' "##### DEFINE DEVHUB AS DEFAULT #####"
sfdx force:config:set defaultusername=${DEVHUB_ALIAS}

if [ "$CREATE_SCRATCH" = "TRUE" ]
then 
  scratchorgcount=$(sfdx force:org:list --json | jq -r --arg SCRATCH_ORG_ALIAS "$SCRATCH_ORG_ALIAS" '[.result.scratchOrgs[] | select(.alias==$SCRATCH_ORG_ALIAS)]| length')
  
  if [ $scratchorgcount -gt 0 ]
  then
    printf '\e[1;34m%-6s\e[m\n' "There is an already existing scratch org called $SCRATCH_ORG_ALIAS"
    osascript -e 'display notification "WARNING: Alredy existing scratch org" with title "Scratch Org Butler" sound name "Blow"'
    read -rp "Would you like to recreate it?" DeleteAnswer

    if [ "${DeleteAnswer}" = "Y" ] || [ "${DeleteAnswer}" = "y" ]
    then
      printf '\e[1;31m%-6s\e[m\n' "##### DELETING ${SCRATCH_ORG_ALIAS} #####"
      sfdx force:org:delete -u ${SCRATCH_ORG_ALIAS}

      printf '\e[1;31m%-6s\e[m\n' "##### CREATING SCRATCH ORG #####"
      sfdx force:org:create -f config/project-scratch-def.json -a ${SCRATCH_ORG_ALIAS} -s -d 7
      printf '\e[1;31m%-6s\e[m\n' "##### Scratch org created. #####"
      printf '\e[1;31m%-6s\e[m\n' "##### GENERATE PASSWORD #####"
      sfdx force:user:password:generate -u ${SCRATCH_ORG_ALIAS}

  printf '\e[1;31m%-6s\e[m\n' "Please, note down this password"
  sfdx force:org:display -u ${SCRATCH_ORG_ALIAS}
    fi
  else
      printf '\e[1;31m%-6s\e[m\n' "##### CREATING SCRATCH ORG #####"
      sfdx force:org:create -f config/project-scratch-def.json -a ${SCRATCH_ORG_ALIAS} -s -d 7
      printf '\e[1;31m%-6s\e[m\n' "##### Scratch org created. #####"
      printf '\e[1;31m%-6s\e[m\n' "##### GENERATE PASSWORD #####"
      sfdx force:user:password:generate -u ${SCRATCH_ORG_ALIAS}
      printf '\e[1;31m%-6s\e[m\n' "Please, note down this password"
      sfdx force:org:display -u ${SCRATCH_ORG_ALIAS}
  fi 

  if [ "$?" = "1" ] 
  then
    printf '\e[1;34m%-6s\e[m\n' "I'm sorry, I can't create your scratch org."
    printf '\e[1;34m%-6s\e[m\n' "Please authorize your dev hub with this command : #sfdx force:auth:web:login -d -a <DEVHUB_ALIAS>"
    exit
  fi
 

  printf '\e[1;31m%-6s\e[m\n' "##### GENERATE PASSWORD #####"
  sfdx force:user:password:generate -u ${SCRATCH_ORG_ALIAS}

  printf '\e[1;31m%-6s\e[m\n' "Please, note down this password"
  sfdx force:org:display -u ${SCRATCH_ORG_ALIAS}
fi

#INSTALL THE MANAGED PACKAGES
IFS=',' # comma (,) is set as delimiter
for ManPackageName in $ManPackage_List
do
  printf '\e[1;31m%-6s\e[m\n' "##### INSTALLING $ManPackageName #####"
  ManPackageVer=$(cat ManPack_List | jq -r --arg ManPackageName "$ManPackageName" '[.result[] | select(.SubscriberPackageName==$ManPackageName)] | .[-1] | .SubscriberPackageVersionId')
  sfdx force:package:install --wait 10 --publishwait 10 --package $ManPackageVer --noprompt -u ${SCRATCH_ORG_ALIAS} > Log_$ManPackageName.Butlog
done
rm ManPack_List

#INSTALL THE UNLOCKED PACKAGES
for UnlPackageName in $UnlPackage_List
do
  printf '\e[1;31m%-6s\e[m\n' "##### INSTALLING $UnlPackageName #####"
  UnlPackageVer=$(cat UnlPack_List | jq -r --arg UnlPackageName "$UnlPackageName" '[.result[] | select(.Package2Name==$UnlPackageName)] | .[-1] | .SubscriberPackageVersionId')
  sfdx force:package:install --wait 10 --publishwait 10 --package $UnlPackageVer --noprompt -u ${SCRATCH_ORG_ALIAS} > Log_$UnlPackageName.Butlog
done
rm UnlPack_List

# space ( ) is set as delimiter
IFS=' ' 

if [ "$DEPLOY_SOURCE" = "TRUE" ]
then
  printf '\e[1;31m%-6s\e[m\n' '##### PUSHING METADATA #####'
  sfdx force:source:push -u ${SCRATCH_ORG_ALIAS} -f
fi

osascript -e 'display notification "Scratch org creation completed" with title "Scratch Org Butler" sound name "Blow"'
printf '\e[1;34m%-6s\e[m\n' "Scratch org created!!"
read -rp "Do you want to login? (y/n)" login_choice

if [ "${login_choice}" = "Y" ] || [ "${login_choice}" = "y" ]
then
  sfdx force:org:open -u ${SCRATCH_ORG_ALIAS}
fi

sfdx force:config:set defaultusername=${SCRATCH_ORG_ALIAS} > /dev/null


#Authorize org
#sfdx force:auth:web:login --setalias vscodeOrg2 --instanceurl https://customization-power-5417-dev-ed.cs83.my.salesforce.com/ --setdefaultusername

#Restart VSCODE
#nohup osascript -e 'tell application "Visual Studio Code"' -e 'quit' -e 'delay 2' -e 'activate' -e 'end tell' &
