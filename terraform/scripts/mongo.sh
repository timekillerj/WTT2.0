#!/bin/bash
sudo apt-get update
sudo apt-get install -y gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt-get install -y mongodb-org mongodb-database-tools
sudo systemctl start mongod
sudo systemctl enable mongod

# Wait for MongoDB to start
sleep 10

cat <<EOF > /opt/mongo.js
use admin
db.createUser(
  {
    user: "admin",
    pwd: "adminpassword",
    roles: [ 
        { role: "userAdminAnyDatabase", db: "admin" } ,
        { role: "readWriteAnyDatabase", db: "admin" } ,
        { role: "backup", db: "admin" } 
    ]
  }
)
EOF

mongosh < /opt/mongo.js

sh -c 'echo "security:\n  authorization : enabled" >> /etc/mongod.conf'
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

systemctl restart mongod.service

sudo snap install aws-cli --classic

cat <<\EOF > /usr/local/bin/mongo_backup.sh
#!/bin/bash

export HOME=/home/ubuntu/
HOST=localhost
# DB name
DBNAME=db
# S3 bucket name
BUCKET=techtask-public-mongo-backups
# MongoDB admin credentials
MONGO_USER=admin
MONGO_PASSWORD=adminpassword
# Current time
TIMESTAMP=$(date +%F-%H%M)
ISO_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Backup directory
DEST=/opt/tmp
# Tar file of backup directory
TAR=${DEST}/../${TIMESTAMP}.tar

/bin/mkdir -p ${DEST}
echo "Backing up ${HOST}/${DBNAME} to s3://${BUCKET}/ on ${TIMESTAMP}"
# Dump from mongodb host into backup directory
/usr/bin/mongodump -h ${HOST} --username ${MONGO_USER} --password ${MONGO_PASSWORD} -o ${DEST}
# Create tar of backup directory
/bin/tar cvf ${TAR} -C ${DEST} .
# Upload tar to s3
/snap/bin/aws s3 cp ${TAR} s3://${BUCKET}/
# Get Backup size
SIZE=$(du -b ${TAR} | awk '{print $1}')
# Remove tar file locally
/bin/rm -f ${TAR}
# Remove backup directory
/bin/rm -rf ${DEST}
# All done
echo "Backup available at https://s3.amazonaws.com/${BUCKET}/${TIMESTAMP}.tar"

# Insert a record into MongoDB with backup details
mongosh --host ${HOST} --authenticationDatabase admin -u ${MONGO_USER} -p ${MONGO_PASSWORD} <<EOM
use backups
db.backup_records.insertOne({
  backup_name: "${TIMESTAMP}.tar",
  s3_path: "s3://${BUCKET}/${TIMESTAMP}.tar",
  url: "https://${BUCKET}.s3.amazonaws.com/${TIMESTAMP}.tar",
  size: ${SIZE},
  backup_date: new Date("${ISO_TIMESTAMP}")
})
EOM
EOF

# Make backup script executable
sudo chmod +x /usr/local/bin/mongo_backup.sh

# Add cron job to run backup script every day
echo "0 1 * * * /bin/bash /usr/local/bin/mongo_backup.sh >> /var/log/mongo_backup.log 2>&1" >> /var/spool/cron/crontabs/root
EOF