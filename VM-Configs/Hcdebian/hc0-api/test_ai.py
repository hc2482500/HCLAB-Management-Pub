import requests
import json

def chiedi_a_gemma(domanda):
    # L'URL punta al tuo container Ollama sulla porta 11434
    url = "http://localhost:11434/api/generate"
    
    # Il payload con il tag esatto :2b che abbiamo scoperto prima
    payload = {
        "model": "gemma:2b",
        "prompt": domanda,
        "stream": False # False serve per ricevere la risposta tutta insieme
    }
    
    try:
        # Invio della richiesta POST
        response = requests.post(url, json=payload, timeout=30)
        response.raise_for_status()
        
        # Estrazione della risposta testuale dal JSON
        risultato = response.json()
        return risultato.get('response', 'Nessuna risposta ricevuta.')
        
    except requests.exceptions.RequestException as e:
        return f"Errore di connessione: {e}"

# --- TEST DELLO SCRIPT ---
if __name__ == "__main__":
    testo_domanda = "Ciao Gemma, dammi un consiglio veloce per proteggere un server Linux."
    print(f"Interrogazione in corso...")
    
    risposta = chiedi_a_gemma(testo_domanda)
    
    print("\n--- RISPOSTA DALL'IA LOCALE ---")
    print(risposta)
    print("-------------------------------\n")