#!/bin/sh

PRG="$0"
PRGDIR=`dirname "$PRG"`
HAZELCAST_HOME=../$PRGDIR
HAZELCAST_LOG_DIR=/var/log/hazelcast

#creating log directory
mkdir $HAZELCAST_LOG_DIR

if [ $JAVA_HOME ]
then
	echo "JAVA_HOME found at $JAVA_HOME"
	RUN_JAVA=$JAVA_HOME/bin/java
else
	echo "JAVA_HOME environment variable not available."
    RUN_JAVA=`which java 2>/dev/null`
fi

if [ -z $RUN_JAVA ]
then
    echo "JAVA could not be found in your system."
    echo "please install Java 1.6 or higher!!!"
    exit 1
fi

echo "Path to Java : $RUN_JAVA"

# Need to download the Azure Discovery API using Maven
mvn dependency:copy -Dartifact=com.hazelcast.azure:hazelcast-azure:$2 -DoutputDirectory=$HAZELCAST_HOME/lib

#### minimum heap size
if [ "x$MIN_HEAP_SIZE" = "x" ]
 then
   MIN_HEAP_SIZE=4G
fi
if [ "x$MAX_HEAP_SIZE" = "x" ]
 then
  MAX_HEAP_SIZE=4G
fi

if [ "x$MIN_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi
if [ "x$MAX_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MAX_HEAP_SIZE}"
fi

export CLASSPATH=$HAZELCAST_HOME/lib/hazelcast-$1.jar

echo "########################################"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# starting now...."
echo "########################################"

$RUN_JAVA -server -Djava.util.logging.config.file=$HAZELCAST_HOME/bin/logging.properties $JAVA_OPTS com.hazelcast.core.server.StartServer


