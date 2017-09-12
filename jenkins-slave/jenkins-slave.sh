#!/bin/bash

export JENKINS_HOME=/opt/jenkins-slave
master_username=${JENKINS_USERNAME:-"admin"}
master_password=${JENKINS_PASSWORD:-"welcome"}
slave_executors=${EXECUTORS:-"1"}

JAR="${JENKINS_HOME}/bin/slave.jar"

# if -url is not provided try env vars
if [[ "$@" != *"-url "* ]]; then
  if [ ! -z "$JENKINS_URL" ]; then
    PARAMS="$PARAMS -url $JENKINS_URL"
  elif [ ! -z "$JENKINS_SERVICE_HOST" ] && [ ! -z "$JENKINS_SERVICE_PORT" ]; then
    PARAMS="$PARAMS -url http://$JENKINS_SERVICE_HOST:$JENKINS_SERVICE_PORT"
    JENKINS_URL="http://$JENKINS_SERVICE_HOST:$JENKINS_SERVICE_PORT"
  fi
fi

mkdir -p "$JENKINS_HOME/bin"
echo "Downloading ${JENKINS_URL}/jnlpJars/remoting.jar ..."
curl -sS ${JENKINS_URL}/jnlpJars/remoting.jar -o ${JAR}

# If JENKINS_SECRET and JENKINS_JNLP_URL are present, run JNLP slave
if [ ! -z $JENKINS_SECRET ] && [ ! -z $JENKINS_JNLP_URL ]; then
	# if -tunnel is not provided try env vars
	if [[ "$@" != *"-tunnel "* ]]; then
		if [[ ! -z "$JENKINS_TUNNEL" ]]; then
			TUNNEL="-tunnel $JENKINS_TUNNEL"
		fi
	fi

	if [[ ! -z "$JENKINS_URL" ]]; then
		URL="-url $JENKINS_URL"
	fi

	exec java $JAVA_OPTS -cp $JAR hudson.remoting.jnlp.Main -headless $TUNNEL $URL -jar-cache $HOME "$@"

elif [[ $# -lt 1 ]] || [[ "$1" == "-"* ]]; then

  echo "Running Jenkins Swarm Plugin...."
  if [[ "$@" != *"-master "* ]] && [ ! -z "$JENKINS_PORT_8080_TCP_ADDR" ]; then
	PARAMS="-master http://${JENKINS_SERVICE_HOST}:${JENKINS_SERVICE_PORT}${JENKINS_CONTEXT_PATH} -tunnel ${JENKINS_SLAVE_SERVICE_HOST}:${JENKINS_SLAVE_SERVICE_PORT}${JENKINS_SLAVE_CONTEXT_PATH} -username ${master_username} -password ${master_password} -executors ${slave_executors}"
  fi
  
  #PARAMS="-master -jnlpUrl http://52.214.246.1:8080/computer/209.132.178.161/slave-agent.jnlp -secret 34f748a54e49678dcaad89711a1f597d1b41ecd94ef8a34f0202813c76a7d8c8"

  echo Running java $JAVA_OPTS -jar $JAR -fsroot $HOME $PARAMS "$@"
  exec java $JAVA_OPTS -jar $JAR -fsroot $HOME $PARAMS "$@"

fi
