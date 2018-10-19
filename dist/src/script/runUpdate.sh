#!/usr/bin/env bash

if [ -r /etc/default/wdqs-updater ]; then
  . /etc/default/wdqs-updater
fi

HOST=http://localhost:9999
CONTEXT=bigdata
MEMORY="-Xmx2g"
LOG_DIR=${LOG_DIR:-"/var/log/wdqs"}
GC_LOGS=${GC_LOGS:-"-Xloggc:${LOG_DIR}/wdqs-updater_jvm_gc.%p.log \
         -XX:+PrintGCDetails \
         -XX:+PrintGCDateStamps \
         -XX:+PrintGCTimeStamps \
         -XX:+PrintAdaptiveSizePolicy \
         -XX:+PrintReferenceGC \
         -XX:+PrintGCCause \
         -XX:+PrintGCApplicationStoppedTime \
         -XX:+PrintTenuringDistribution \
         -XX:+UseGCLogFileRotation \
         -XX:NumberOfGCLogFiles=10 \
         -XX:GCLogFileSize=20M"}
EXTRA_JVM_OPTS=${EXTRA_JVM_OPTS:-""}
LOG_CONFIG=${LOG_CONFIG:-""}
NAMESPACE=wdq
UPDATER_OPTS=${UPDATER_OPTS:-""}

while getopts h:c:n:l:t:sS:Nv option
do
  case "${option}"
  in
    h) HOST=${OPTARG};;
    c) CONTEXT=${OPTARG};;
    n) NAMESPACE=${OPTARG};;
    l) LANGS=${OPTARG};;
    t) TMO=${OPTARG};;
    s) SKIPSITE=1;;
    S) PROGRAM_NAME_SUFFIX=${OPTARG};;
	N) NOEXTRA=1;;
	v) VERBOSE_LOGGING="true";;
  esac
done

# allow extra args
shift $((OPTIND-1))

if [ -z "$NAMESPACE" ]
then
  echo "Usage: $0 -n <namespace> [-h <host>] [-c <context>] [-v]"
  exit 1
fi

if [ -z "$TMO" ]; then
    TIMEOUT_ARG=
else
    TIMEOUT_ARG="-Dorg.wikidata.query.rdf.tool.rdf.RdfRepository.timeout=$TMO"
fi

if [ -z "$LANGS" ]; then
    ARGS=
else
    ARGS="--labelLanguage $LANGS --singleLabel $LANGS"
fi

if [ ! -z "$SKIPSITE" ]; then
    ARGS="$ARGS --skipSiteLinks"
fi
LOG_OPTIONS=""
if [ ! -z "$LOG_CONFIG" ]; then
    LOG_OPTIONS="-Dlogback.configurationFile=${LOG_CONFIG}"
fi
# No extra options - for running secondary updaters, etc.
if [ ! -z "$NOEXTRA" ]; then
	EXTRA_JVM_OPTS=""
	GC_LOGS=""
fi

CP=lib/wikidata-query-tools-*-jar-with-dependencies.jar
MAIN=org.wikidata.query.rdf.tool.Update
SPARQL_URL=$HOST/$CONTEXT/namespace/$NAMESPACE/sparql
echo "Updating via $SPARQL_URL"
exec java -cp ${CP} ${MEMORY} ${GC_LOGS} ${LOG_OPTIONS} ${EXTRA_JVM_OPTS} \
     ${TIMEOUT_ARG} ${UPDATER_OPTS} \
     ${MAIN} ${ARGS} --sparqlUrl ${SPARQL_URL} "$@"
