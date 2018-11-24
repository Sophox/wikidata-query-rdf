FROM maven:3.6.0-jdk-8 AS builder
LABEL maintainer='Yuri Astrakhan <YuriAstrakhan@gmail.com>'

RUN mkdir -p /app \
    && mkdir -p /app-src

COPY . /app-src

# Extract the version number from the line right above the <packaging>pom</packaging>
# Compile (currently tests are skipped, but should be enabled in the future)
# Unzip to /app
# Cleanup

RUN cd /app-src \
    && BLAZE_VERSION=$(grep --before-context=1 '<packaging>pom</packaging>' pom.xml \
            | head -n 1 \
            | sed 's/^[^>]*>\([^<]*\)<.*$/\1/g') \
    && echo "########### Building Blazegraph ${BLAZE_VERSION}" \
    && mvn package -DskipTests=true -DskipITs=true \
    && unzip -d /app /app-src/dist/target/service-${BLAZE_VERSION}-dist.zip \
    && mv /app/service-${BLAZE_VERSION}/* /app \
    && rmdir /app/service-${BLAZE_VERSION} \
    \
    && cd /app \
    && sed 's|%BLAZEGRAPH_JNL_DATA_FILE%|'"${BLAZEGRAPH_JNL_DATA_FILE}"'|g' RWStore.properties > subst.temp \
    && mv subst.temp RWStore.properties \
    && sed 's|%BLAZEGRAPH_ENDPOINTS%|'"${BLAZEGRAPH_ENDPOINTS}"'|g' services.json > subst.temp \
    && mv subst.temp services.json

#
# Create the actual production image
#
FROM openjdk:8-jdk
LABEL maintainer='Yuri Astrakhan <YuriAstrakhan@gmail.com>'
WORKDIR /app
COPY --from=builder /app .
ENTRYPOINT ["/bin/bash"]
