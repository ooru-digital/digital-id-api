#!/bin/bash
set -e

# ------------------- CONFIGURATION -------------------
DB_HOST="postgres.digital.credissuer.com"
DB_PORT="5432"
DB_SUPERUSER="postgres"
DB_SUPERUSER_PASSWORD="FgQZ7z3Ci5"  # Superuser password

HELM_RELEASE_NAME="digitalid-backend"
HELM_CHART_DIR="."  # path to your chart
HELM_NAMESPACE="digitalid"
VALUES_FILE="$HELM_CHART_DIR/values.yaml"

# ------------------- USER INPUT -------------------
DB_NAME="${DB_NAME:-$(read -p 'Enter DB name: ' name; echo $name)}"
DB_USER="${DB_USER:-$(read -p 'Enter DB user: ' user; echo $user)}"
DB_PASSWORD="${DB_PASSWORD:-$(read -sp 'Enter DB password: ' pass; echo $pass)}"
echo

export PGPASSWORD="$DB_SUPERUSER_PASSWORD"

# ------------------- CREATE DB IF NOT EXISTS -------------------
echo "Checking if database '$DB_NAME' exists..."
DB_EXISTS=$(psql -h $DB_HOST -p $DB_PORT -U $DB_SUPERUSER -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")
if [ "$DB_EXISTS" != "1" ]; then
    echo "Database '$DB_NAME' does not exist. Creating..."
    psql -h $DB_HOST -p $DB_PORT -U $DB_SUPERUSER -c "CREATE DATABASE $DB_NAME;"
else
    echo "Database '$DB_NAME' already exists. Skipping creation."
fi

# ------------------- CREATE USER IF NOT EXISTS -------------------
echo "Checking if user '$DB_USER' exists..."
USER_EXISTS=$(psql -h $DB_HOST -p $DB_PORT -U $DB_SUPERUSER -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'")
if [ "$USER_EXISTS" != "1" ]; then
    echo "User '$DB_USER' does not exist. Creating..."
    psql -h $DB_HOST -p $DB_PORT -U $DB_SUPERUSER -c "CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';"
else
    echo "User '$DB_USER' already exists. Skipping creation."
fi

# ------------------- GRANT PRIVILEGES -------------------
echo "Granting privileges to user '$DB_USER' on database '$DB_NAME'..."
psql -h $DB_HOST -p $DB_PORT -U $DB_SUPERUSER -d $DB_NAME <<EOF
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;
GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
EOF

echo "✅ Database and user setup completed."

# ------------------- UPDATE values.yaml -------------------
echo "Updating $VALUES_FILE with DB credentials..."
yq eval ".env.DB_NAME = \"$DB_NAME\" |
         .env.DB_USER = \"$DB_USER\" |
         .env.DB_PASSWORD = \"$DB_PASSWORD\"" -i $VALUES_FILE

# ------------------- DEPLOY HELM -------------------
echo "Deploying Helm chart..."
kubectl get ns $HELM_NAMESPACE >/dev/null 2>&1 || kubectl create ns $HELM_NAMESPACE

helm upgrade --install $HELM_RELEASE_NAME $HELM_CHART_DIR -n $HELM_NAMESPACE

echo "✅ Helm deployment completed!"

