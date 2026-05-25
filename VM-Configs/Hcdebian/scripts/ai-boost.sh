#!/bin/bash

# Elenco dei container pesanti da fermare (separati da spazio)
HEAVY_SERVICES="odoo odoo_db stirling-pdf"
BOOST_ACTIVE=0

echo "🤖 AI Boost Daemon avviato. In attesa di OpenWebUI..."

while true; do
    # Legge l'API di Ollama per vedere se ci sono modelli in RAM
    RESPONSE=$(curl -s http://localhost:11434/api/ps)

    # Se la risposta contiene la parola "name", un modello sta lavorando
    if echo "$RESPONSE" | grep -q '"name"'; then
        if [ $BOOST_ACTIVE -eq 0 ]; then
            echo "🚀 [$(date +'%H:%M:%S')] IA ATTIVATA! Libero la RAM fermando i servizi..."
            docker stop $HEAVY_SERVICES
            BOOST_ACTIVE=1
        fi
    else
        # Nessun modello in RAM
        if [ $BOOST_ACTIVE -eq 1 ]; then
            echo "💤 [$(date +'%H:%M:%S')] IA INATTIVA. Riaccendo i servizi in background..."
            docker start $HEAVY_SERVICES
            BOOST_ACTIVE=0
        fi
    fi

    # Attende 10 secondi prima di ricontrollare
    sleep 10
done