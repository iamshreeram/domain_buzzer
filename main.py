import requests
import json
from multiprocessing import Process, Lock

names = ["ayana" , "shakti", "astra", "yantra", "vidyut", "jagat", "mantra", "jnana", "nirmaan", "sankhya", "drishti", "prakruti", "netra", "mrida", "chakra"] 
tld_list = '''["tech","ai","xyz","io","dev","host","app","org","net","com"]'''

base_url = "https://name.qlaffont.com/api/domains"

mutex = Lock()
max_concurrency = 5

def check_availability(domainname):
    url = f"{base_url}?name={domainname}&domains={tld_list}"
    response = requests.get(url=url,
                            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0',
                                     'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
                                     'Accept-Language': 'en-US,en;q=0.5', 
                                     'Connection': 'keep-alive', 
                                     'Upgrade-Insecure-Requests': '1', 
                                     'Sec-Fetch-Dest': 'document', 
                                     'Sec-Fetch-Mode': 'navigate', 
                                     'Sec-Fetch-Site': 'cross-site',
                                     'If-None-Match': 'W/"hcnxyqy19a101"',
                                     'TE': 'trailers'})
    
    data = response.json()
    csv = ""
    for info in data['data']:
        try:
            csv += f"{info['domainName']},{info['isTaken']},{info['registrar']}\n"
        except:
            csv += f"{info['domainName']},{info['isTaken']},\n"
    with mutex:
        with open("output.csv", "a") as f:
            f.write(csv)

if __name__ == "__main__":
    with open("output.csv", "w") as f:
        f.write("domainname,isTaken,registrar")

    processes = []
    for name in names:
        while len(processes) >= max_concurrency:
            for p in processes:
                if not p.is_alive():
                    processes.remove(p)
            continue

        p = Process(target=check_availability, args=(name,))
        p.start()
        processes.append(p)

    for p in processes:
        p.join()
