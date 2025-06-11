#!/bin/sh
# scripts/setup-connector.sh
# Setup script for Debezium PostgreSQL connector using environment variables

set -e  # Exit on any error

# Default values if not provided
KAFKA_CONNECT_URL=${KAFKA_CONNECT_URL:-"http://debezium:8083"}
CONNECTOR_NAME=${CONNECTOR_NAME:-"iqgeo-connector"}
POSTGRES_HOST=${POSTGRES_HOST:-"postgres"}
POSTGRES_PORT=${POSTGRES_PORT:-"5432"}
POSTGRES_DB=${POSTGRES_DB:-"inventory"}
POSTGRES_USER=${POSTGRES_USER:-"postgres"}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"postgres"}
# DATABASE_SERVER_NAME=${DATABASE_SERVER_NAME:-"inventory-db"}
TOPIC_PREFIX=${TOPIC_PREFIX:-"inventory"}
TABLE_INCLUDE_LIST=${TABLE_INCLUDE_LIST:-"data.note"}
MAX_RETRIES=${MAX_RETRIES:-30}
RETRY_INTERVAL=${RETRY_INTERVAL:-10}

echo "================================================"
echo "Debezium Connector Setup"
echo "================================================"
echo "Kafka Connect URL: $KAFKA_CONNECT_URL"
echo "Connector Name: $CONNECTOR_NAME"
echo "PostgreSQL Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "Database: $POSTGRES_DB"
echo "Tables: $TABLE_INCLUDE_LIST"
echo "================================================"

# Function to wait for Kafka Connect to be ready
wait_for_kafka_connect() {
    echo "Waiting for Kafka Connect to be ready..."
    retries=0
    while [ $retries -lt $MAX_RETRIES ]; do
        if curl -s -f "$KAFKA_CONNECT_URL/connectors" > /dev/null 2>&1; then
            echo "✓ Kafka Connect is ready!"
            return 0
        fi
        retries=$((retries + 1))
        echo "⏳ Attempt $retries/$MAX_RETRIES - Kafka Connect not ready, waiting ${RETRY_INTERVAL}s..."
        sleep $RETRY_INTERVAL
    done
    echo "❌ Failed to connect to Kafka Connect after $MAX_RETRIES attempts"
    exit 1
}

# Function to check if connector exists
connector_exists() {
    curl -s "$KAFKA_CONNECT_URL/connectors" | grep -q "\"$CONNECTOR_NAME\""
}

# Function to get connector status
get_connector_status() {
    curl -s "$KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME/status" | \
        grep -o '"state":"[^"]*"' | \
        cut -d':' -f2 | \
        tr -d '"'
}

# Function to create connector JSON dynamically
create_connector_config() {
    cat > /tmp/connector-config.json << EOF
{
  "name": "$CONNECTOR_NAME",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "tasks.max": "1",
    "database.hostname": "$POSTGRES_HOST",
    "database.port": "$POSTGRES_PORT",
    "database.user": "$POSTGRES_USER",
    "database.password": "$POSTGRES_PASSWORD",
    "database.dbname": "$POSTGRES_DB",
    "database.server.name": "iqgeo-db",
    "table.include.list": "$TABLE_INCLUDE_LIST",
    "topic.prefix": "$TOPIC_PREFIX",
    "plugin.name": "pgoutput",
    "slot.name": "debezium_slot",
    "publication.name": "debezium_publication",
    "publication.autocreate.mode": "filtered",
    "key.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable": "false",
    "value.converter.schemas.enable": "false",
    "transforms": "unwrap",
    "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
    "transforms.unwrap.drop.tombstones": "false",
    "transforms.unwrap.delete.handling.mode": "rewrite"
  }
}
EOF
}

# Function to create connector
create_connector() {
    echo "📝 Creating connector configuration..."
    create_connector_config
    
    echo "🚀 Creating connector: $CONNECTOR_NAME"
    response=$(curl -s -w "%{http_code}" -X POST "$KAFKA_CONNECT_URL/connectors" \
        -H "Content-Type: application/json" \
        -d @/tmp/connector-config.json)
    
    http_code=$(echo "$response" | tail -c 4)
    
    if [ "$http_code" = "201" ] || [ "$http_code" = "409" ]; then
        echo "✅ Connector created successfully!"
        return 0
    else
        echo "❌ Failed to create connector (HTTP: $http_code)"
        echo "Response: $response"
        return 1
    fi
}

# Function to restart connector
restart_connector() {
    echo "🔄 Restarting connector: $CONNECTOR_NAME"
    response=$(curl -s -w "%{http_code}" -X POST "$KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME/restart")
    http_code=$(echo "$response" | tail -c 4)
    
    if [ "$http_code" = "204" ]; then
        echo "✅ Connector restarted successfully!"
    else
        echo "⚠️  Restart request sent (HTTP: $http_code)"
    fi
}

# Function to delete connector (for cleanup/reset scenarios)
delete_connector() {
    if [ "$DELETE_EXISTING" = "true" ]; then
        echo "🗑️  Deleting existing connector: $CONNECTOR_NAME"
        curl -s -X DELETE "$KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME"
        echo "✅ Connector deleted"
        sleep 5  # Wait a bit before recreating
    fi
}

# Main execution flow
main() {
    wait_for_kafka_connect
    
    # Optional: Delete existing connector if requested
    if [ "$DELETE_EXISTING" = "true" ] && connector_exists; then
        delete_connector
    fi
    
    if connector_exists; then
        status=$(get_connector_status)
        echo "📊 Connector '$CONNECTOR_NAME' exists with status: $status"
        
        case "$status" in
            "RUNNING")
                echo "✅ Connector is already running!"
                ;;
            "FAILED"|"PAUSED")
                echo "⚠️  Connector is in $status state, attempting restart..."
                restart_connector
                ;;
            *)
                echo "ℹ️  Connector status: $status"
                ;;
        esac
    else
        echo "➕ Connector '$CONNECTOR_NAME' does not exist, creating..."
        if create_connector; then
            echo "🎉 Setup completed successfully!"
        else
            echo "💥 Setup failed!"
            exit 1
        fi
    fi
    
    # Display final status
    echo ""
    echo "🔍 Final connector status:"
    curl -s "$KAFKA_CONNECT_URL/connectors/$CONNECTOR_NAME/status" | \
        grep -o '"state":"[^"]*"' | \
        head -1
}

# Run main function
main