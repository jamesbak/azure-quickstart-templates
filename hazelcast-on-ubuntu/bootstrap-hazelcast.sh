#!/usr/bin/env bash
# Usage: bootstrap-hazelcast.sh {hz-userName} {hz-password} {hz-version} {spi-version} 
# Sample: bootstrap-hazelcast.sh 'test-hz-jb' 'hazelcastpassword' '3.4.1' '1.0-RC1'

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
wget -O hazelcast-$3.tar.gz http://download.hazelcast.com/download.jsp?version=hazelcast-$3&type=tar&p=
tar -xzf hazelcast-$3.tar.gz -C /var/lib/
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "Failed to run command tar -xzf hazelcast-$3.tar.gz -C /var/lib/"
fi

log "Copy customized Hazelcast artifacts in var/lib dir..."
cp -f hazelcast.xml /var/lib/hazelcast-$3/bin/
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "Failed to run command cp -f hazelcast.xml /var/lib/hazelcast-$3/bin/"
fi

cp -f server.sh /var/lib/hazelcast-$3/bin/
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "Failed to run command cp -f server.sh /var/lib/hazelcast-$3/bin/"
fi
cp -f logging.properties /var/lib/hazelcast-$3/bin/
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "Failed to run command cp -f logging.properties /var/lib/hazelcast-$3/bin/"
fi
#python3.4 hazelcast_modify_configuration.py --cn "$1" --cp "$2" --ip "$4" --pg "$5" --fn "/var/lib/hazelcast-$3/bin/hazelcast.xml"
#scriptstatus=$?
#if [ $scriptstatus -ne 0 ]
# then
#  log "Failed to modify Hazelcast XML configuration file"
#fi
nohup sh initialize-hazelcast.sh $3 $4 >/dev/null 2>&1 &