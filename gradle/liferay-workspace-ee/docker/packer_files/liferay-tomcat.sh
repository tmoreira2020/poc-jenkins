#!/bin/sh

set -e

##
## This is the script to start Liferay Tomcat bundle inside built Docker image.
##

@UTILS_FILE_CONTENT@

##
## Constants
##

# JDK home which was installed for the bundle. Empty means 'java' is in PATH.
JAVA_HOME='@JAVA_HOME@'

# The Liferay bundle home, where bundle was extracted.
LIFERAY_HOME='@LIFERAY_HOME@'

# The name of the directory where Tomcat is located, inside Liferay bundle home.
LIFERAY_HOME_TOMCAT_DIR_NAME='@LIFERAY_HOME_TOMCAT_DIR_NAME@'

# "$JAVA_HOME" can be empty
for const in \
		"$LIFERAY_HOME" \
		"$LIFERAY_HOME_TOMCAT_DIR_NAME"; do
	case "$const" in
		@*@) die "One of the constants was not replaced by Gradle (starts and ends with '@').";;
		'') die "One of the constants has an empty value";;
	esac
done

##
## Computed Constants
##

TOMCAT_HOME="$LIFERAY_HOME/$LIFERAY_HOME_TOMCAT_DIR_NAME"


# We have to export the Java home, otherwise catalina.sh would not be able to read it
export JAVA_HOME=$JAVA_HOME

if [ "x$JAVA_HOME" != "x" ]; then
  ## DXP expects 'java' in $PATH and never checks things like $JAVA_HOME when it needs
  ## to run an external 'java' process
  export PATH="$JAVA_HOME/bin:$PATH"
fi


# GSMS-393: Create a wrapper around bin/catalina.sh to handle the shutdown gracefully.
# Based on: https://customer.liferay.com/documentation/knowledge-base/-/kb/1464875

# ----------------------------------------------------
# INIT
# ----------------------------------------------------
pid=0

# ----------------------------------------------------
# TERMINATION EVENTS
# ----------------------------------------------------
# SIGTERM-handler
shutdown_handler() {
 echo "shutdown_handler() invoked!"
 if [ $pid -ne 0 ]; then
   echo "shutdown_handler() clean up tasks!"

   echo "Shutdown Tomcat"
   $TOMCAT_HOME/bin/shutdown.sh

   local SLEEP_TIME=5
   local PATTERN=java
   local JPID=`ps -ef | grep -i $PATTERN| grep -v grep |grep -v sshd | awk -F' ' '{print $2}'`

   while [ ! -z $JPID ] && [ $JPID -gt 0 ]
   do
       echo "The process is still running... waiting" $SLEEP_TIME "seconds."
       sleep $SLEEP_TIME
       JPID=`ps -ef | grep -i $PATTERN| grep -v grep |grep -v sshd | awk -F ' ' '{print $2}'`
   done
   echo "Attention! The process has been finally stopped OK"
 fi

 exit 143; # 128 + 15 -- SIGTERM
}
# ----------------------------------------------------------------------------------------------------
# FINALIZE
# ----------------------------------------------------------------------------------------------------


# Trap to intercept SIGTERM and to shutdown tomcat

trap 'kill ${!}; shutdown_handler' TERM
trap 'kill ${!}; shutdown_handler' KILL
trap 'kill ${!}; shutdown_handler' INT


# ----------------------------------------------------------------------------------------------------
# Liferay Startup
# ----------------------------------------------------------------------------------------------------
# Start Tomcat in the background
$TOMCAT_HOME/bin/catalina.sh run &


pid="$!"
# wait forever
while true
do
 tail -f /dev/null & wait ${!}
done