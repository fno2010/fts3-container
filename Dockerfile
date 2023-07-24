FROM centos:7
LABEL org.opencontainers.image.authors="Jensen Zhang <hack@jensen-zhang.site>"

ENV FTS_REPO https://github.com/cern-fts/fts3
ENV FTS_BRANCH develop

# Add FTS repo
ARG ftsrepo=https://fts-repo.web.cern.ch/fts-repo/fts3-prod-el7.repo
ADD $ftsrepo /etc/yum.repos.d/fts3-prod-el7.repo

# Add FTS third-party dependencies repo
ARG ftsdeprepo=https://fts-repo.web.cern.ch/fts-repo/fts3-depend-el7.repo
ADD $ftsdeprepo /etc/yum.repos.d/fts3-depend-el7.repo

# Add DMC repo
ARG dmcrepo=https://dmc-repo.web.cern.ch/dmc-repo/dmc-el7.repo
ADD $dmcrepo /etc/yum.repos.d/dmc.repo

RUN \
    yum install -y epel-release \
    && yum upgrade -y \
    && yum --enablerepo=*-testing clean all \
    && yum groupinstall -y 'Development Tools' \
    && yum install -y centos-release-scl \
                      yum-plugin-priorities yum-utils createrepo \
                      mysql multitail gfal2-all gfal2-plugin* \
                      python2-pip \
                      voms-config-wlcg voms-config-vo-dteam \
                      supervisor

# Build FTS packages
RUN \
    git clone ${FTS_REPO} -b ${FTS_BRANCH} /tmp/fts3 \
    && cd /tmp/fts3/packaging \
    && yum-builddep -y rpm/fts.spec \
    && make rpm \
    && echo -e "[fts-ci]\nname=FTS CI\nbaseurl=file:///tmp/fts3/packaging/out\ngpgcheck=0\nenabled=1\npriority=1" > /etc/yum.repos.d/fts.repo \
    && createrepo /tmp/fts3/packaging/out \
    && echo "priority=2" >> /etc/yum.repos.d/dmc.repo \
    && echo "priority=10" >> /etc/yum.repos.d/fts3-prod-el7.repo \
    && echo "priority=20" >> /etc/yum.repos.d/fts3-depend-el7.repo \

# Install FTS packages
    && yum install -y fts-server fts-rest-client fts-rest-server fts-monitoring fts-mysql fts-msg \

# Cleanup package cache
    && yum clean all \
    && rm -rf /var/cache/yum /tmp/fts3

# Setup FTS security
COPY certs/hostcert_fts.pem /etc/grid-security/hostcert.pem
COPY certs/hostcert_fts.key.pem /etc/grid-security/hostkey.pem
COPY certs/rucio_ca.pem /etc/grid-security/certificates/5fca1cb1.0

# Database configuration for FTS server
COPY fts3config /etc/fts3/fts3config

RUN \
    chmod 400 /etc/grid-security/hostkey.pem \

# Upgrade to high-enough version of sqlalchemy for python2
    && pip install --upgrade pip==20.3.4 \
    && pip install --upgrade sqlalchemy==1.2.19 \

    && chmod +x /usr/share/fts/fts-database-upgrade.py

# Configuration for FTSREST and FTSMON
COPY fts3rest.conf /etc/httpd/conf.d/fts3rest.conf
COPY fts3restconfig /etc/fts3/fts3restconfig
RUN echo "" > /etc/httpd/conf.d/ssl.conf &&\
    echo "" > /etc/httpd/conf.d/autoindex.conf &&\
    echo "" > /etc/httpd/conf.d/userdir.conf &&\
    echo "" > /etc/httpd/conf.d/welcome.conf &&\
    echo "" > /etc/httpd/conf.d/zgridsite.conf \

# fix Apache configuration
    && /usr/bin/sed -i 's/Listen 80/#Listen 80/g' /etc/httpd/conf/httpd.conf \
    && cp /opt/rh/httpd24/root/usr/lib64/httpd/modules/mod_rh-python36-wsgi.so /lib64/httpd/modules \
    && cp /opt/rh/httpd24/root/etc/httpd/conf.modules.d/10-rh-python36-wsgi.conf /etc/httpd/conf.modules.d

# FTS monitoring ActiveMQ configuration
COPY fts-msg-monitoring.conf /etc/fts3/fts-msg-monitoring.conf

# Entrypoint waiting script for MySQL
COPY wait-for-it.sh /usr/local/bin/wait-for-it.sh
RUN chmod +x /usr/local/bin/wait-for-it.sh

# Shortcut for logfiles
COPY logshow /usr/local/bin/logshow
RUN chmod +x /usr/local/bin/logshow \
    && mkdir -p /var/log/fts3 \
    && touch /var/log/fts3/fts3server.log \
    && chown -R fts3:fts3 /var/log/fts3/fts3server.log \
    && mkdir -p /var/log/fts3rest \
    && touch /var/log/fts3rest/fts3rest.log \
    && chown -R fts3:fts3 /var/log/fts3rest

# Startup
EXPOSE 8446 8449
COPY --chmod=0755 docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
