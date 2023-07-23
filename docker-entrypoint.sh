#!/bin/bash

# wait for MySQL readiness
/usr/local/bin/wait-for-it.sh -h ftsdb -p 3306 -t 3600

# initialise / upgrade the database
mysql -h ftsdb -u fts --password=fts fts < $(ls /usr/share/fts-mysql/fts-schema* | sort -t '-' -k '4n' | tail -n 1)
# TODO: go back to using this script once the fixed it and bundled with the new fts version:
# /usr/share/fts/fts-database-upgrade.py -y

# startup the FTS services
/usr/sbin/fts_server               # main FTS server daemonizes
/usr/sbin/fts_msg_bulk             # daemon to send messages to activemq
/usr/sbin/fts_bringonline          # daemon to handle staging requests
/usr/sbin/httpd -DFOREGROUND       # FTS REST frontend & FTSMON
