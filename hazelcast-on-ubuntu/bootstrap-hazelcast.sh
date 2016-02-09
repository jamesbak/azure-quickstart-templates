#!/usr/bin/env bash
# Usage: bootstrap-hazelcast.sh {hz-userName} {hz-password} {hz-version} {spi-version} {subscription-id} {tenant-id} {aad-client-id} {aad-client-secret} {cluster-tag} 
# Sample: bootstrap-hazelcast.sh 'test-hz-jb' 'hazelcastpassword' '3.4.1' '1.0-RC1' '24cb2056-d747-4f35-a373-42861a1b37b9' '94a088bf-86f1-41af-91ab-2d7cd011db47' '5ec177d1-9066-476f-8681-9d0e7f8a97fe' 'QgfZiP2HOoqatrKczC4IQrvusPER8gjqApLV9RAGsYM=' 'my-hazelcast-cluster'

execname=$0
scriptstatus=$0

log() {
  echo "[${execname}] $@" 
}

reliableaptget() {
 TIME_MAX=15
 TIME_INCREMENT=5
 wait_time=0
 COMMAND_STATUS=1
 until [ $COMMAND_STATUS -eq 0 ] || [ $wait_time -eq $TIME_MAX ]; do
   echo "try $getcommand with timeincrement $wait_time"
   $getcommand
   COMMAND_STATUS=$?
   echo "command status $COMMAND_STATUS"
   wait_time=$(($wait_time + $TIME_INCREMENT))
   if [ $COMMAND_STATUS -gt 0 ]
    then
     sleep $wait_time
   fi
  done
 if [ $COMMAND_STATUS -ne 0 ]
   then
     scriptstatus=1203
  fi
}

reliablewgetanduntar() {
  TIME_MAX=15
  TIME_INCREMENT=5
  wait_time=0
  COMMAND_STATUS=0
  until [ $wait_time -eq $TIME_MAX ] || [ -s "$wgettarget" ]; do
    echo "try $wgetcommand + $tarcommand with timeincrement $wait_time"
    wait_time=$(($wait_time + $TIME_INCREMENT))
    $wgetcommand
    COMMAND_STATUS=$?
    if [ $COMMAND_STATUS -gt 0 ] || [ ! -s "$wgettarget" ]
     then
      sleep $wait_time
    else
      $tarcommand
      COMMAND_STATUS=$?
      if [ $COMMAND_STATUS -gt 0 ] || [ ! -s "$wgettarget" ]
       then
        sleep $wait_time
      fi
    fi
    if [ $COMMAND_STATUS -eq 0 ]
     then
      break
    fi
  done
 if [ $COMMAND_STATUS -ne 0 ]
   then
     scriptstatus=1204
  fi
}

log "BEGIN: apt-get update"
apt-get -y update
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "Failed at apt-get update, exiting script"
  exit $scriptstatus
fi
log "END: apt-get update successfully"

log "Installing python 3.4 binaries..."
getcommand="apt-get --yes install python3.4"
echo "trying $getcommand"
reliableaptget
if [ $scriptstatus -ne 0 ]
 then
   log "apt-get --yes install python3.4 failed after three attempts, exiting script"
   exit $scriptstatus
fi

log "BEGIN: Running apt-get update again"
apt-get -y update
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "apt-get -y update failed, exiting script"
  exit $scriptstatus
fi
log "END: apt-get update ran successfully"

log "Unzip Hazelcast in var/lib dir..."
wgettarget="hazelcast-$3.tar.gz"
wgetcommand="wget --unlink -O $wgettarget http://download.hazelcast.com/download.jsp?version=hazelcast-$3&type=tar&p="
tarcommand="tar -xzf $wgettarget -C /var/lib/"
reliablewgetanduntar
if [ $scriptstatus -ne 0 ]
 then
  log "wget and/or tar failed after three attempts, exiting script"
  exit $scriptstatus
fi

log "Copy customized Hazelcast artifacts in var/lib dir..."
cp -f hazelcast.xml /var/lib/hazelcast-$3/bin/
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "Failed to run command cp -f hazelcast.xml /var/lib/hazelcast-$3/bin/"
fi

cp -f start.sh /var/lib/hazelcast-$3/bin/
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "Failed to run command cp -f start.sh /var/lib/hazelcast-$3/bin/"
fi
cp -f logging.properties /var/lib/hazelcast-$3/bin/
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "Failed to run command cp -f logging.properties /var/lib/hazelcast-$3/bin/"
fi
python hazelcast_modify_configuration.py --cn "$1" --cp "$2" --si "$5" --ti "$6" --aci "$7" --acs "$8" --ct "$9" --fn "/var/lib/hazelcast-$3/bin/hazelcast.xml"
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "Failed to modify Hazelcast XML configuration file"
fi
nohup sh initialize-hazelcast.sh $3 $4 >/dev/null 2>&1 &