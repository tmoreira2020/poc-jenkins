#!/bin/bash
#
# @LIFERAY_SERVICE_NAME@	 This shell script takes care of starting and stopping Liferay Tomcat
#
# chkconfig: - 80 20
#
### BEGIN INIT INFO
# Provides:          @LIFERAY_SERVICE_NAME@
# Required-Start:    $network $syslog
# Required-Stop:     $network $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Liferay on Tomcat
# Description:       The service for managing Liferay deployed on Tomcat.
### END INIT INFO

# Hardening done based on Olaf's blogs:
#   https://web.liferay.com/web/olaf.kock/blog/-/blogs/securing-liferay-chapter-1-introduction-basics-and-operating-system-level

##
## This script is based on Brett Swaim's example:
##  * https://www.liferay.com/web/brett.swaim/blog/-/blogs/sample-tomcat-startup-scripts
##  * https://wiki.debian.org/LSBInitScripts

@UTILS_FILE_CONTENT@

##
## Constants
##

# The name of this servce for usage info.
LIFERAY_SERVICE_NAME='@LIFERAY_SERVICE_NAME@'

# The OS user to start the Liferay Tomcat server.
LIFERAY_USER='@LIFERAY_USER@'

# The OS group to use when creating home directory of $LIFERAY_USER, if missing
LIFERAY_GROUP='@LIFERAY_GROUP@'

# The Liferay bundle home, with Tomcat expected to be located inside.
LIFERAY_HOME='@LIFERAY_HOME@'

# The name of the directory inside Liferay bundle home with the app server.
# For Tomcat server, this will most likely be like 'tomcat-8.0.32'. This is used
# to locate Tomcat script to start / stop the bundle's Tomcat.
LIFERAY_HOME_TOMCAT_DIR_NAME='@LIFERAY_HOME_APP_SERVER_DIR_NAME@'

# JDK home to be set before starting Tomcat. Needs to be set explicitly, if 'java'
# is not in present PATH.
# Make sure this points to valid JDK, for example as installed by 'install-oracle-jdk-8-linux-x64.sh',
# or is empty, meaning 'java' is in PATH.
JAVA_HOME='@JAVA_HOME@'

# If set to 'true', then the bundle will be hardened by imposing stricter file and
# directory permissions. As a results, some development features might be impaired,
# like:
#   * hot-deploy into deploy/ not possible
#   * auto-deploy into osgi/* not possible
#
HARDEN_BUNDLE_ON_START='@HARDEN_BUNDLE_ON_START@'

##
## Computed Constants
##

# The full path of the Tomcat server (also known as Catalina home). The Tomcat
# directory name can be a symlink (e.g. tomcat -> tomcat-7.0.42), which is fine.
TOMCAT_HOME="${LIFERAY_HOME}/${LIFERAY_HOME_TOMCAT_DIR_NAME}"

# How long to wait (seconds) on clean shutdown using Tomcat API before killing the process in OS?
SHUTDOWN_WAIT=45

# Make sure to set necessary shell environment variables needed by Tomcat / DXP.
# (1) set Java's home as JAVA_HOME, if not empty
#       - used by bin/catalina.sh in Tomcat
#
# (2) place our Java's bin/ into PATH (as first entry), if JAVA_HOME not empty
#       - 'java' (without ay path) is used by DXP to run external 'java' processes (no path used by DXP)
#       - prevents following errors:
#           Caused by: com.liferay.portal.kernel.process.ProcessException: java.io.IOException: Cannot run
#                   program "java": error=2, No such file or directory
#           at com.liferay.portal.kernel.process.local.LocalProcessExecutor.execute(LocalProcessExecutor.java:230)
#           at com.liferay.portal.lpkg.deployer.internal.LPKGIndexValidator._getTargetPlatformIndexURIs(LPKGIndexValidator.java:300)
#           at com.liferay.portal.lpkg.deployer.internal.LPKGIndexValidator.validate(LPKGIndexValidator.java:222)
#           at com.liferay.portal.lpkg.deployer.internal.DefaultLPKGDeployer._doActivate(DefaultLPKGDeployer.java:266)
#           at com.liferay.portal.lpkg.deployer.internal.DefaultLPKGDeployer.activate(DefaultLPKGDeployer.java:84)
# (3) echo the final content of PATH
#       - indent the same way as when Tomcat is listing CATALINA_BASE, JRE_HOME, CLASSPATH etc.
#
if [ "x$JAVA_HOME" != "x" ]; then
  SET_ENVIRONMENT_VARS_COMMAND="\
    export JAVA_HOME='$JAVA_HOME' && \
    export PATH=\"$JAVA_HOME/bin:\$PATH\" && \
    echo \"Using PATH:            \$PATH\""
else
  SET_ENVIRONMENT_VARS_COMMAND="\
    echo \"JAVA_HOME empty, 'java' expected in PATH, not setting JAVA_HOME\" && \
    echo \"Using PATH:            \$PATH\""
fi

# Make sure our custom 'die' command can be used safely
if ! command -v die >/dev/null 2>&1; then
    echo "==> ERROR: util command 'die' not found, was utils.sh included by Gradle?" && exit 127
fi

# "$JAVA_HOME" can be empty
for const in \
		"$LIFERAY_SERVICE_NAME" \
		"$LIFERAY_USER" \
		"$LIFERAY_GROUP" \
		"$LIFERAY_HOME" \
		"$LIFERAY_HOME_TOMCAT_DIR_NAME" \
		"$HARDEN_BUNDLE_ON_START"; do
	case "$const" in
		@*@) die "One of the constants was not replaced by Gradle (starts and ends with '@').";;
		'') die "One of the constants has an empty value";;
	esac
done

tomcat_pid() {
	echo `ps aux | grep org.apache.catalina.startup.Bootstrap | grep -v grep | awk '{ print $2 }'`
}

ensure_sh_files_executable() {
	chmod u+x $TOMCAT_HOME/bin/*.sh
}

enforce_root_user() {
	current_user=$(whoami)

 	if [ "$current_user" != "root" ]
	then
		echo "Only 'root' (or sudo) is allowed to run this command, sorry. You are '$current_user'."

		exit 1
	fi
}

check_user_and_home_dir() {

	if ! id -u $LIFERAY_USER > /dev/null 2>&1; then

		# User should be added by 'add-liferay-user-and-group.sh' added into Liferay's DEB / RPM.

		die "Configured user '$LIFERAY_USER' used to start Tomcat with Liferay Portal does not exist, please create it."
	fi

	# make sure the home directory of 'liferay' exists
	#   (1) determine the home dir
	#   (2) create the home dir if missing

	# http://unix.stackexchange.com/a/247580
	home_dir=$(getent passwd $LIFERAY_USER | cut -d: -f6)

	if [ "x$home_dir" = "x" ]; then
		home_dir="/home/$LIFERAY_USER"

		echo "No home directory for user '$LIFERAY_USER' found in /etc/passwd, defaulting to '$home_dir'"
	fi

	if [ ! -d $home_dir ]; then
		if ! getent group $LIFERAY_GROUP > /dev/null 2>&1; then
			# Group should be added by 'add-liferay-user-and-group.sh' added into Liferay's DEB / RPM.

			die "Configured group '$LIFERAY_GROUP' does not exist, please create it. It needs to be used to create missing home directory for configured user '$LIFERAY_USER'."
		fi

		install --owner=$LIFERAY_USER --group=$LIFERAY_GROUP -d $home_dir

		echo "Missing home directory '$home_dir' for user '$LIFERAY_USER' created."
	fi
}

start() {
	pid=$(tomcat_pid)

	if [ -n "$pid" ]; then
		echo "Liferay Tomcat '$TOMCAT_HOME' is already running (pid: $pid)"
	else
		# Start tomcat
		echo "Starting Liferay Tomcat '$TOMCAT_HOME' as user '$LIFERAY_USER'..."

		if [ "$HARDEN_BUNDLE_ON_START" = "true" ]; then
            harden_bundle
        fi

		# Use substitute user command ('su') with following switches to start Tomcat:
		#   * use login shell (--login)
		#   * set shell explicitly for su, in case the chosen user does not have
		#       a valid login shell, which is often the case for system users (--shell)
		#   * execute specific command (--command)
		#   * specify as the configured user for Tomcat (most likely 'liferay')
		#
		# Then run following commands:
		#   (1) set the necessary environment variables
		#   (2) set the working directory to [tomcat]/bin
		#   (3) start the Tomcat
		/bin/su \
			--login \
			--shell=/bin/sh \
			--command "$SET_ENVIRONMENT_VARS_COMMAND && cd $TOMCAT_HOME/bin && $TOMCAT_HOME/bin/startup.sh" \
			$LIFERAY_USER
	fi

	return 0
}

stop() {
	pid=$(tomcat_pid)

	if [ -n "$pid" ]; then
		echo "Stopping Liferay Tomcat '$TOMCAT_HOME'..."

		# Ask Tomcat nicely to stop itself
		#
		# For details of 'su' switches and command's contents, see start() above
		/bin/su \
			--login \
			--shell=/bin/sh \
			--command "$SET_ENVIRONMENT_VARS_COMMAND && cd $TOMCAT_HOME/bin && $TOMCAT_HOME/bin/shutdown.sh" \
			$LIFERAY_USER

		# Wait and check every few seconds, if Tomcat has stopped
		let kwait=$SHUTDOWN_WAIT
		count=0
		count_by=5
		until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $count -gt $kwait ]
		do
			echo "Waiting for processes to exit. Timeout before we kill the pid: ${count}/${kwait}"
			sleep $count_by
			let count=$count+$count_by;
		done

		# If Tomcat did not stop itself after given wait period (45 seconds), kill the process by force
		if [ $count -gt $kwait ]
		then
			echo "Killing processes which didn't stop after $SHUTDOWN_WAIT seconds"
			kill -9 $pid
		fi
	else
		echo "Liferay Tomcat '$TOMCAT_HOME' is not running"
	fi

	return 0
}

status() {
	pid=$(tomcat_pid)

	if [ -n "$pid" ]; then
		echo "Liferay Tomcat '$TOMCAT_HOME' is running with pid: $pid"
	else
		echo "Liferay Tomcat '$TOMCAT_HOME' is not running"
	fi

	return 0
}

harden_bundle() {
    echo "Hardening Liferay bundle in path '$LIFERAY_HOME'"

    # repeat all following commands
    set -x

    # Make sure all dirs we'll touch exist
    mkdir -p \
        $LIFERAY_HOME/deploy \
        $LIFERAY_HOME/osgi/configs \
        $LIFERAY_HOME/osgi/marketplace \
        $LIFERAY_HOME/osgi/marketplace/override \
        $LIFERAY_HOME/osgi/modules \
        $LIFERAY_HOME/osgi/war \
        $LIFERAY_HOME/osgi/state \
        $TOMCAT_HOME/conf \
        $TOMCAT_HOME/webapps

    # All bundle files are owned by liferay
    chown -R $LIFERAY_USER:$LIFERAY_GROUP $LIFERAY_HOME


    # Only liferay can read configs (possibly sensitive data inside),
    # No writing allowed (even for liferay) to make the bundle immutable (best effort)
    #
    chmod -R 600 \
        $LIFERAY_HOME/*.properties \
        $LIFERAY_HOME/*.xml \
        $LIFERAY_HOME/*.conf \
        $LIFERAY_HOME/osgi/configs/* \
        $TOMCAT_HOME/conf/* \
        || true

    # Hot-deploy not allowed
    # https://github.com/liferay/liferay-portal/blob/master/portal-impl/src/portal.properties#L241
    #   -> auto.deploy.deploy.dir
    #
    chown root:root \
        $LIFERAY_HOME/deploy \
        $TOMCAT_HOME/webapps

    chmod o-w \
        $LIFERAY_HOME/deploy \
        $TOMCAT_HOME/webapps


    # OSGi auto-deploy not allowed
    # https://github.com/liferay/liferay-portal/blob/master/portal-impl/src/portal.properties#L6304
    #       -> module.framework.auto.deploy.dirs
    #
    chown root:root \
        $LIFERAY_HOME/osgi/configs \
        $LIFERAY_HOME/osgi/marketplace \
        $LIFERAY_HOME/osgi/marketplace/override \
        $LIFERAY_HOME/osgi/modules \
        $LIFERAY_HOME/osgi/war

    chmod o-w \
        $LIFERAY_HOME/osgi/configs \
        $LIFERAY_HOME/osgi/marketplace \
        $LIFERAY_HOME/osgi/marketplace/override \
        $LIFERAY_HOME/osgi/modules \
        $LIFERAY_HOME/osgi/war
        
    # stop repeating the commands
    set +x
}

usage() {
	echo "$LIFERAY_SERVICE_NAME start | stop | restart | status | usage"
	echo "  Basic OS script for Liferay Tomcat bundle in '$LIFERAY_HOME_TOMCAT_DIR_NAME'. Has to be run as root / sudo."
	echo ""
}

case $1 in
	start)
		enforce_root_user
		ensure_sh_files_executable
		check_user_and_home_dir
		start
		;;
	stop)
		enforce_root_user
		ensure_sh_files_executable
		check_user_and_home_dir
		stop
		;;
	restart)
		enforce_root_user
		ensure_sh_files_executable
		check_user_and_home_dir
		stop
		start
		;;
	status)
		status
		;;
	*)
		usage
esac

exit 0