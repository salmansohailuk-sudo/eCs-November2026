#!/bin/bash
#
# initialize-database.sh
# Creates the tables in the RDS MySQL database, using createdatabase.sql.
#
# Before running it, set two variables (replace the values with your own):
#   export RDS_ENDPOINT="your-rds-address.us-east-1.rds.amazonaws.com"
#   export DB_PASSWORD="Cloud123"
#
# Then run it from the ecs folder:   ./initialize-database.sh

# createdatabase.sql must be in this folder. If not, we are in the wrong place.
if [ ! -f createdatabase.sql ]; then
  echo "ERROR: createdatabase.sql not found."
  echo "Please run this script from the ecs folder."
  exit 1
fi

# The database user name. This matches the Stage 1 Terraform setting.
DB_USER=admin

# Check that both variables were set. -z means "is empty".
if [ -z "$RDS_ENDPOINT" ]; then
  echo "ERROR: RDS_ENDPOINT is not set."
  echo "Run:  export RDS_ENDPOINT=\"your-rds-address\""
  exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
  echo "ERROR: DB_PASSWORD is not set."
  echo "Run:  export DB_PASSWORD=\"your-password\""
  exit 1
fi

# Feed the SQL file into mysql. This creates the tables.
# Terraform already waited for the database to be ready in Stage 1,
# so we can connect straight away.
echo "Creating tables in $RDS_ENDPOINT ..."

if mysql -h $RDS_ENDPOINT -u $DB_USER -p$DB_PASSWORD < createdatabase.sql; then
  echo "Database setup complete."
else
  echo "ERROR: database setup failed. Read the message above."
  exit 1
fi
