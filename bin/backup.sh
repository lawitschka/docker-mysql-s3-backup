#!/usr/bin/env bash

function log() {
  echo "[$(date -Iseconds)] $1"
}

function timestamp() {
  date +%s
}

# Set proper variable names for options
s3_path=$1
db_name=$2

# Set up default options
MYSQL_HOST="${MYSQL_HOST:-db}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"

# Set up ~/.my.cnf
cat > ~/.my.cnf <<EOL
[client]
password="${MYSQL_PASS}"
EOL
chmod 0600 ~/.my.cnf

# Informational output
log "Connecting to MySQL server ${MYSQL_HOST}:${MYSQL_PORT} as user ${MYSQL_USER}"

# Dump databases
filename="${db_name}-$(timestamp).sql"
log "Dumping database \"${db_name}\""
mysqldump --result-file /tmp/$filename \
          --host $MYSQL_HOST \
          --port $MYSQL_PORT \
          --user $MYSQL_USER \
          $db_name
log "Done dumping database"

# Create archive
archive=${filename}.tar.gz
archive_path=/tmp/${archive}
tar -czf $archive_path -C /tmp $filename
log "Created archive ${archive}"

# Configure AWS CLI
cat > ~/.aws/config <<EOL
[default]
output = text
region = $AWS_REGION
EOL

cat > ~/.aws/credentials <<EOL
[default]
aws_access_key_id = $AWS_ACCESS_KEY
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOL

# Upload to AWS
s3_path="s3://${s3_path}/${archive}"
log "Uploading archive to ${s3_path}"
aws s3 cp $archive_path $s3_path --quiet
log "Archive succesfully uploaded"
