FROM rockylinux:8 AS build

ARG LICENSE=WTFPL \
  IMAGE_NAME=rhel8 \
  TIMEZONE=America/New_York \
  PORT=

ENV SHELL=/bin/bash \
  TERM=xterm-256color \
  HOSTNAME=${HOSTNAME:-casjaysdev-$IMAGE_NAME} \
  TZ=$TIMEZONE \
  RPM_SOURCE_DIR="/data/rpmbuild" \
  RPM_RELEASE_DIR="/data/release"

RUN mkdir -p /bin/ /config/ /data/ && \
  yum update -y && \
  yum install wget curl git -y && \
  yum clean all && \
  rm -Rf "/etc/yum.repos.d"/* && \
  wget -q "https://github.com/rpm-devel/casjay-release/raw/main/casjay.rh8.repo" -O "/etc/yum.repos.d/casjay.repo" && \
  yum update -y --allowerasing && \
  yum groupinstall "Development Tools" "RPM Development Tools" -y && \
  yum clean all

COPY ./config/rpmmacros /root/.rpmmacros
COPY ./bin/. /usr/local/bin/
COPY ./config/. /config/
COPY ./data/. /data/

RUN rm -Rf /bin/.gitkeep /config/.gitkeep /data/.gitkeep

FROM scratch
ARG BUILD_DATE="$(date +'%Y-%m-%d %H:%M')"

LABEL org.label-schema.name="rhel8" \
  org.label-schema.description="Containerized version of rhel8" \
  org.label-schema.url="https://hub.docker.com/r/casjaysdevdocker/rhel8" \
  org.label-schema.vcs-url="https://github.com/casjaysdevdocker/rhel8" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$BUILD_DATE \
  org.label-schema.vcs-ref=$BUILD_DATE \
  org.label-schema.license="$LICENSE" \
  org.label-schema.vcs-type="Git" \
  org.label-schema.schema-version="latest" \
  org.label-schema.vendor="CasjaysDev" \
  maintainer="CasjaysDev <docker-admin@casjaysdev.com>"

ENV SHELL="/bin/bash" \
  TERM="xterm-256color" \
  HOSTNAME="casjaysdev-rhel8" \
  TZ="${TZ:-America/New_York}"

WORKDIR /root

VOLUME ["/config","/data/rpmbuild","/data/release"]

EXPOSE $PORT

COPY --from=build /. /

#ENTRYPOINT [ "tini", "--" ]
HEALTHCHECK --interval=15s --timeout=3s CMD [ "/usr/local/bin/entrypoint-rhel8.sh", "healthcheck" ]
CMD [ "/usr/local/bin/entrypoint-rhel8.sh" ]

