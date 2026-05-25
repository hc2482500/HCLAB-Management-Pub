from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
import xml.etree.ElementTree as ET
import requests
import time
import random

app = FastAPI(title="Homelab Green Pro", version="4.2.1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="static"), name="static")

PROMETHEUS_URL = "http://prometheus:9090/api/v1/query"

API_CACHE = {
    "last_update_country": 0, 
    "last_update_news": 0,    
    "last_update_tech": 0,    
    "country": None,
    "news": [],
    "tech_news": []
}

TUTTE_LE_NAZIONI = [
    "af","ax","al","dz","as","ad","ao","ai","aq","ag","ar","am","aw","au","at","az","bs","bh","bd",
    "bb","by","be","bz","bj","bm","bt","bo","bq","ba","bw","bv","br","io","bn","bg","bf","bi","cv",
    "kh","cm","ca","ky","cf","td","cl","cn","cx","cc","co","km","cd","cg","ck","cr","ci","hr","cu",
    "cw","cy","cz","dk","dj","dm","do","ec","eg","sv","gq","er","ee","sz","et","fk","fo","fj","fi",
    "fr","gf","pf","tf","ga","gm","ge","de","gh","gi","gr","gl","gd","gp","gu","gt","gg","gn","gw",
    "gy","ht","hm","va","hn","hk","hu","is","in","id","ir","iq","ie","im","il","it","jm","jp","je",
    "jo","kz","ke","ki","kp","kr","kw","kg","la","lv","lb","ls","lr","ly","li","lt","lu","mo","mg",
    "mw","my","mv","ml","mt","mh","mq","mr","mu","yt","mx","fm","md","mc","mn","me","ms","ma","mz",
    "mm","na","nr","np","nl","nc","nz","ni","ne","ng","nu","nf","mp","no","om","pk","pw","ps","pa",
    "pg","py","pe","ph","pn","pl","pt","pr","qa","re","ro","ru","rw","bl","sh","kn","lc","mf","pm",
    "vc","ws","sm","st","sa","sn","rs","sc","sl","sg","sx","sk","si","sb","so","za","gs","ss","es",
    "lk","sd","sr","sj","se","ch","sy","tw","tj","tz","th","tl","tg","tk","to","tt","tn","tr","tm",
    "tc","tv","ug","ua","ae","gb","um","us","uy","uz","vu","ve","vn","vg","vi","wf","eh","ye","zm","zw"
]

CAPITALI_IT = {
    "London": "Londra", "Paris": "Parigi", "Berlin": "Berlino", "Moscow": "Mosca", 
    "Beijing": "Pechino", "Athens": "Atene", "Warsaw": "Varsavia", "Prague": "Praga", 
    "Lisbon": "Lisbona", "Dublin": "Dublino", "Copenhagen": "Copenaghen", "Stockholm": "Stoccolma", 
    "Bucharest": "Bucarest", "Belgrade": "Belgrado", "Vienna": "Vienna", "Tokyo": "Tokyo",
    "Brussels": "Bruxelles", "Geneva": "Ginevra", "Bern": "Berna", "Jerusalem": "Gerusalemme", 
    "Riyadh": "Riad", "Tehran": "Teheran", "Baghdad": "Baghdad", "Damascus": "Damasco", 
    "Cairo": "Il Cairo", "Algiers": "Algeri", "Havana": "L'Avana", "New Delhi": "Nuova Delhi", 
    "Seoul": "Seul", "Pyongyang": "Pyongyang", "Mexico City": "Città del Messico", 
    "Santiago": "Santiago del Cile", "Cape Town": "Città del Capo", "Addis Ababa": "Addis Abeba", 
    "Mogadishu": "Mogadiscio", "Ljubljana": "Lubiana", "Zagreb": "Zagabria", "Kyiv": "Kiev", 
    "Kiev": "Kiev", "Luxembourg": "Lussemburgo", "Vatican City": "Città del Vaticano", 
    "Washington, D.C.": "Washington"
}

HEADERS = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}

def get_metric(query):
    try:
        response = requests.get(PROMETHEUS_URL, params={'query': query}, timeout=2)
        response.raise_for_status()
        results = response.json().get('data', {}).get('result', [])
        if results: return float(results[0]['value'][1])
        return 0
    except: return 0

def get_random_country_info():
    try:
        code = random.choice(TUTTE_LE_NAZIONI)
        url = f"https://restcountries.com/v3.1/alpha/{code}"
        res = requests.get(url, timeout=2).json()
        country = res[0]
        cap_en = country.get('capital', ["N/D"])[0]
        return {
            "name": country['translations'].get('ita', {}).get('common', country['name']['common']),
            "flag_url": country['flags']['svg'],
            "pop": f"{country.get('population', 0):,}".replace(",", "."),
            "capital": CAPITALI_IT.get(cap_en, cap_en)
        }
    except: return None

def fetch_news_data():
    global API_CACHE
    try:
        news_list = []
        feeds = [
            ("BBC", "http://feeds.bbci.co.uk/news/world/rss.xml"),
            ("NYT", "https://rss.nytimes.com/services/xml/rss/nyt/World.xml"),
            ("WaPo", "https://feeds.washingtonpost.com/rss/world")
        ]
        for source_name, url in feeds:
            try:
                res_news = requests.get(url, headers=HEADERS, timeout=4)
                root = ET.fromstring(res_news.content)
                for item in root.findall('./channel/item')[:3]:
                    news_list.append({"source": source_name, "title": item.find('title').text, "link": item.find('link').text})
            except: continue
        random.shuffle(news_list)
        API_CACHE["news"] = news_list[:5]
        API_CACHE["last_update_news"] = time.time()
    except Exception as e: print(f"Errore world news: {e}")

def fetch_tech_news():
    global API_CACHE
    try:
        tech_list = []
        feeds = [
            ("SciAm", "http://rss.sciam.com/ScientificAmerican-Global"), 
            ("Phys.org", "https://phys.org/rss-feed/"),
            ("ArsTech", "https://feeds.arstechnica.com/arstechnica/index")
        ]
        for source_name, url in feeds:
            try:
                res_news = requests.get(url, headers=HEADERS, timeout=4)
                root = ET.fromstring(res_news.content)
                for item in root.findall('./channel/item')[:3]:
                    tech_list.append({"source": source_name, "title": item.find('title').text, "link": item.find('link').text})
            except: continue
        random.shuffle(tech_list)
        API_CACHE["tech_news"] = tech_list[:5]
        API_CACHE["last_update_tech"] = time.time()
    except Exception as e: print(f"Errore tech news: {e}")

def format_uptime(seconds):
    days, rem = divmod(int(seconds), 86400)
    hours, rem = divmod(rem, 3600)
    minutes, _ = divmod(rem, 60)
    return f"{days}g {hours}h {minutes}m" if days > 0 else f"{hours}h {minutes}m"

@app.get("/", response_class=HTMLResponse)
async def home_page():
    return """
    <!DOCTYPE html>
    <html lang="it">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>API Backend Status</title>
        <link rel="icon" type="image/png" href="http://homelab.local/homelab-gears-favicon.png?v=3">
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap" rel="stylesheet">
        <style>
            :root {
                --bg-gradient-top: #16a34a; 
                --bg-gradient-bottom: #14532d; 
                --card-bg: rgba(21, 128, 61, 0.35); 
                --card-border: rgba(220, 252, 231, 0.3); 
            }
            body { margin: 0; font-family: 'Inter', sans-serif; background: linear-gradient(135deg, var(--bg-gradient-top) 0%, var(--bg-gradient-bottom) 100%); color: #ffffff; min-height: 100vh; display: flex; justify-content: center; align-items: center; }
            .status-card { background: var(--card-bg); border: 1px solid var(--card-border); border-radius: 20px; padding: 50px; text-align: center; backdrop-filter: blur(10px); box-shadow: 0 20px 40px rgba(0,0,0,0.3); width: 100%; max-width: 500px; }
            h1 { font-size: 2.8rem; margin: 0 0 30px 0; font-weight: 800; background: linear-gradient(to right, #ffffff, #dcfce7); -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent; }
            .status-indicator { display: inline-flex; align-items: center; justify-content: center; gap: 12px; background: rgba(0,0,0,0.2); padding: 15px 30px; border-radius: 30px; font-size: 1.3rem; font-weight: 600; border: 1px solid rgba(255,255,255,0.1); }
            .dot { width: 16px; height: 16px; background-color: #4ade80; border-radius: 50%; box-shadow: 0 0 10px #4ade80, 0 0 20px #4ade80; animation: pulse 1.5s infinite alternate; }
            @keyframes pulse { from { transform: scale(1); opacity: 0.6; box-shadow: 0 0 5px #4ade80; } to { transform: scale(1.1); opacity: 1; box-shadow: 0 0 15px #4ade80, 0 0 25px #4ade80; } }
            .version { margin-top: 30px; color: #dcfce7; font-size: 1rem; letter-spacing: 1px; }
        </style>
    </head>
    <body>
        <div class="status-card">
            <h1>⚙️ API Backend</h1>
            <div class="status-indicator"><div class="dot"></div>Status: Online (Attivo)</div>
            <div class="version">Homelab Green Pro v4.2.1</div>
        </div>
    </body>
    </html>
    """

@app.get("/status")
def get_full_status():
    now = time.time()
    
    if now - API_CACHE["last_update_country"] > 3:
        try: API_CACHE["country"] = get_random_country_info()
        except: pass
        API_CACHE["last_update_country"] = now
        
    if now - API_CACHE["last_update_news"] > 60: fetch_news_data()
    if now - API_CACHE["last_update_tech"] > 120: fetch_tech_news()

    free_ram = round(get_metric('node_memory_MemAvailable_bytes') / (1024**3), 2)
    total_ram = round(get_metric('node_memory_MemTotal_bytes') / (1024**3), 2)
    free_disk = round(get_metric('node_filesystem_avail_bytes{mountpoint="/"}') / (1024**3), 2)
    total_disk = round(get_metric('node_filesystem_size_bytes{mountpoint="/"}') / (1024**3), 2)
    temp_cpu = round(get_metric('windows_thermalzone_temperature_celsius{name=~".*CPUZ.*"}'), 1)
    
    cpu_usage = round(get_metric('100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)'), 1)
    
    net_down_query = 'max(irate(node_network_receive_bytes_total{device!="lo"}[2m]))'
    net_up_query = 'max(irate(node_network_transmit_bytes_total{device!="lo"}[2m]))'
    
    net_down_bytes = get_metric(net_down_query)
    net_up_bytes = get_metric(net_up_query)
    
    boot_time = get_metric('node_boot_time_seconds')
    uptime_seconds = time.time() - boot_time if boot_time > 0 else 0
    
    return {
        "resources": {
            "free_ram_gb": free_ram, "total_ram_gb": total_ram,
            "free_disk_gb": free_disk, "total_disk_gb": total_disk,
            "cpu_usage_pct": cpu_usage,
            "net_down_bytes": net_down_bytes,  
            "net_up_bytes": net_up_bytes,      
            "temp_cpu": temp_cpu,
            "uptime": format_uptime(uptime_seconds),
            "country": API_CACHE["country"],
            "news": API_CACHE["news"],
            "tech_news": API_CACHE["tech_news"]
        }
    }