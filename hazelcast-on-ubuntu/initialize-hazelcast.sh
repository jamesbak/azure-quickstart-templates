#!/usr/bin/env bash
# Usage: bootstrap-hazelcast.sh {hz-userName} {hz-password} {hz-version} {[cluster-nodes-static-ip[,]]} {[partition-group:[node-static-ips[,]][;]]}
# Sample: bootstrap-hazelcast.sh 'test-hz-jb' 'hazelcastpassword' '3.4.1' '10.0.0.4,10.0.0.5' '0:10.0.0.4,10.0.0.9;1:10.0.0.5,10.0.0.10'

# hzlogfile="/var/log/hazelcast-bootstrap.log"
# touch $hzlogfile 
# chmod a+rw $hzlogfile
execname=$0
scriptstatus=$0
LOG_DIR=/var/log/initialize-hazelcast
LOG_DIR_FILE=/var/log/initialize-hazelcast/initialize-hazelcast.log
LOG_DIR_SERVER=/var/log/initialize-hazelcast/initialize-hazelcast-server-sh.log
mkdir $LOG_DIR
log() {
  echo "[${execname}] $@" >> $LOG_DIR_FILE
}

reliableaptget() {
 TIME_MAX=15
 TIME_INCREMENT=5
 wait_time=0
 COMMAND_STATUS=1
 until [ $COMMAND_STATUS -eq 0 ] || [ $wait_time -eq $TIME_MAX ]; do
   echo "try $getcommand with timeincrement $wait_time"
   $getcommand >> $LOG_DIR_FILE
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
  
log "BEGIN: apt-get upgrade"
apt-get -y upgrade >> $LOG_DIR_FILE
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then 
  log "Failed at apt-get upgrade, exiting script"
  exit $scriptstatus
fi
log "END: apt-get upgrade succeeded"
log "Installing JRE..."
getcommand="apt-get --yes install openjdk-8-jre"
echo "trying $getcommand"
reliableaptget
if [ $scriptstatus -ne 0 ]
 then
	log "apt-get --yes install openjdk-8-jre failed after three attempts, exiting script"
	exit $scriptstatus
fi
log "Installing Maven..."
getcommand="apt-get --yes install maven"
echo "trying $getcommand"
reliableaptget
if [ $scriptstatus -ne 0 ]
 then
	log "apt-get --yes install maven failed after three attempts, exiting script"
	exit $scriptstatus
fi
log "BEGIN: Running apt-get update again"
apt-get -y update >> $LOG_DIR_FILE
scriptstatus=$?
if [ $scriptstatus -ne 0 ]
 then
  log "apt-get -y update failed, exiting script"
  exit $scriptstatus
fi

# Need to download the Azure Discovery API using Maven & manually load the dependencies
mvn dependency:copy -Dartifact=com.hazelcast.azure:hazelcast-azure:$2 -DoutputDirectory=/var/lib/hazelcast-$1/lib
mvn dependency:copy -Dartifact=com.microsoft.azure:azure-mgmt-compute:0.9.1 -DoutputDirectory=/var/lib/hazelcast-$1/lib
mvn dependency:copy -Dartifact=com.microsoft.azure:azure-mgmt-resources:0.9.1 -DoutputDirectory=/var/lib/hazelcast-$1/lib
mvn dependency:copy -Dartifact=com.microsoft.azure:azure-mgmt-network:0.9.1 -DoutputDirectory=/var/lib/hazelcast-$1/lib
mvn dependency:copy -Dartifact=com.microsoft.azure:azure-mgmt-utility:0.9.1 -DoutputDirectory=/var/lib/hazelcast-$1/lib
mvn dependency:copy -Dartifact=com.microsoft.azure:azure-core:0.9.1 -DoutputDirectory=/var/lib/hazelcast-$1/lib
mvn dependency:copy -Dartifact=org.apache.httpcomponents:httpclient:4.5.1 -DoutputDirectory=/var/lib/hazelcast-$1/lib
mvn dependency:copy -Dartifact=com.microsoft.azure:adal4j:1.1.2 -DoutputDirectory=/var/lib/hazelcast-$1/lib
mvn dependency:copy -Dartifact=com.nimbusds:oauth2-oidc-sdk:4.5 -DoutputDirectory=/var/lib/hazelcast-$1/lib
mvn dependency:copy -Dartifact=com.google.code.gson:gson:2.2.4 -DoutputDirectory=/var/lib/hazelcast-$1/lib

log "Changing directory to bin to run the start.sh"
cd /var/lib/hazelcast-$1/bin/
log "Executing start.sh logging into $LOG_DIR_SERVER"
sh start.sh $1 $2 > $LOG_DIR_SERVER