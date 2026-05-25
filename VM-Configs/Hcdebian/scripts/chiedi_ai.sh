#!/bin/bash
curl -s -X POST http://localhost:11434/api/generate -d '{
  "model": "gemma:2b",
  "prompt": "Ciao Gemma, dammi una ricetta veloce per un sistemista affamato",
  "stream": false
}' | jq -r '.response'