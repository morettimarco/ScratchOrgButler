#!/bin/bash
source logger.sh 

if [ -z $@ ] &> /dev/null #This is a terrible cosmetic solution for the "too many arguments" problem
then
  chatter WARN "$0 requires arguments use -h for help"
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
      chatter LOG "Hello! I support the following parameters:"
      printf '\t%s\n' "-s scratch org name" "-d DevHub name" "-c creates scratch (don't specify if you just want to install packages)" "-p push source to you scratch org"
      exit
      ;;
    \? )
      chatter WARN "Invalid option: -$OPTARG" 1>&2
      exit
      ;;
    : )
      chatter WARN "Invalid option: -$OPTARG requires an argument" 1>&2
      exit
      ;;
  esac
done
shift $((OPTIND -1))

chatter LOG "Hello, please wait while I'm fetching the managed package list from ${DEVHUB_ALIAS}..."

## DEFINE THE LIST OF MANAGED PACKAGES TO INSTALL
sfdx force:package:installed:list -u ${DEVHUB_ALIAS} --json > ManPack_List
chatter LOG "##### PICK MANAGED PACKAGES TO INSTALL #####"
jq -r '[.result[].SubscriberPackageName] | sort | unique | .[]' ManPack_List
notifier "Managed package list ready!"

read -rp "Please pick the packages you want me to install (separated by comma):" ManPackage_List
chatter LOG "Thanks,now I'm fetching the unlocked package list from ${DEVHUB_ALIAS}..."

## DEFINE THE LIST OF UNLOCKED PACKAGES TO INSTALL
sfdx force:package:version:list --json > UnlPack_List
chatter LOG "##### PICK UNLOCKED PACKAGES TO INSTALL #####"
jq -r '[.result[].Package2Name] | sort | unique | .[]' UnlPack_List
notifier "Unlocked package list ready!"
read -rp "Please pick the packages you want me to install:" UnlPackage_List

chatter LOG "Thanks, I'll be right back with you scratch org..."

chatter LOG "##### DEFINE DEVHUB AS DEFAULT #####"
sfdx force:config:set defaultusername=${DEVHUB_ALIAS}

if [ "$CREATE_SCRATCH" = "TRUE" ]
then 
  scratchorgcount=$(sfdx force:org:list --json | jq -r --arg SCRATCH_ORG_ALIAS "$SCRATCH_ORG_ALIAS" '[.result.scratchOrgs[] | select(.alias==$SCRATCH_ORG_ALIAS)]| length')
  
  if [ $scratchorgcount -gt 0 ]
  then
    chatter LOG "There is an already existing scratch org called $SCRATCH_ORG_ALIAS"
    notifier "WARNING: Already existing scratch org"
    read -rp "Would you like to recreate it?" DeleteAnswer

    if [ "${DeleteAnswer}" = "Y" ] || [ "${DeleteAnswer}" = "y" ]
    then
      chatter LOG "##### DELETING ${SCRATCH_ORG_ALIAS} #####"
      sfdx force:org:delete -u ${SCRATCH_ORG_ALIAS}

      chatter LOG "##### CREATING SCRATCH ORG #####"
      sfdx force:org:create -f config/project-scratch-def.json -a ${SCRATCH_ORG_ALIAS} -s -d 7
      chatter LOG "##### Scratch org created. #####"

      chatter LOG "##### GENERATE PASSWORD #####"
      sfdx force:user:password:generate -u ${SCRATCH_ORG_ALIAS}
      chatter LOG "Please, note down this password"
      sfdx force:org:display -u ${SCRATCH_ORG_ALIAS}
    else 
      chatter ERR "I'm sorry, I can't create your scratch org, rerun the script without the -c option"
      exit
    fi
    
  else #NO Scratch org has been found
      chatter LOG "##### CREATING SCRATCH ORG #####"
      sfdx force:org:create -f config/project-scratch-def.json -a ${SCRATCH_ORG_ALIAS} -s -d 7
      chatter LOG "##### Scratch org created. #####"

      chatter LOG "##### GENERATE PASSWORD #####"
      sfdx force:user:password:generate -u ${SCRATCH_ORG_ALIAS}
      chatter LOG "Please, note down this password"
      sfdx force:org:display -u ${SCRATCH_ORG_ALIAS}
  fi 

  if [ "$?" = "1" ] 
  then
    chatter ERR "I'm sorry, I can't create your scratch org."
    chatter WARN "Please authorize your dev hub with this command : #sfdx force:auth:web:login -d -a <DEVHUB_ALIAS>"
    exit
  fi
fi

#INSTALL THE MANAGED PACKAGES
IFS=',' # comma (,) is set as delimiter
for ManPackageName in $ManPackage_List
do
  chatter LOG "##### INSTALLING $ManPackageName #####"
  ManPackageVer=$(cat ManPack_List | jq -r --arg ManPackageName "$ManPackageName" '[.result[] | select(.SubscriberPackageName==$ManPackageName)] | .[-1] | .SubscriberPackageVersionId')
  sfdx force:package:install --wait 10 --publishwait 10 --package $ManPackageVer --noprompt -u ${SCRATCH_ORG_ALIAS} > Log_$ManPackageName.Butlog
done
rm ManPack_List

#INSTALL THE UNLOCKED PACKAGES
for UnlPackageName in $UnlPackage_List
do
  chatter LOG "##### INSTALLING $UnlPackageName #####"
  UnlPackageVer=$(cat UnlPack_List | jq -r --arg UnlPackageName "$UnlPackageName" '[.result[] | select(.Package2Name==$UnlPackageName)] | .[-1] | .SubscriberPackageVersionId')
  sfdx force:package:install --wait 10 --publishwait 10 --package $UnlPackageVer --noprompt -u ${SCRATCH_ORG_ALIAS} > Log_$UnlPackageName.Butlog
done
rm UnlPack_List

# space ( ) is set as delimiter
IFS=' ' 

if [ "$DEPLOY_SOURCE" = "TRUE" ]
then
  chatter LOG '##### PUSHING METADATA #####'
  sfdx force:source:push -u ${SCRATCH_ORG_ALIAS} -f
fi

notifier "Scratch org creation completed"
chatter LOG "Scratch org created!!"
read -rp "Do you want to login? (y/n)" login_choice

if [ "${login_choice}" = "Y" ] || [ "${login_choice}" = "y" ]
then
  sfdx force:org:open -u ${SCRATCH_ORG_ALIAS}
fi

sfdx force:config:set defaultusername=${SCRATCH_ORG_ALIAS} > /dev/null


#Authorize org
#   read -r URL USER PASSWORD <<< $(sfdx force:org:display --json | jq -r '[.result.instanceUrl, .result.username, .result.password] | @tsv ')
#   sfdx force:auth:web:login --setalias ${SCRATCH_ORG_ALIAS} --instanceurl ${URL} --setdefaultusername
#Restart VSCODE
# if [ "$TERM_PROGRAM" == "vscode"  ]
# then
#   nohup osascript -e 'tell application "Visual Studio Code"' -e 'quit' -e 'delay 2' -e 'activate' -e 'end tell' &
# fi
