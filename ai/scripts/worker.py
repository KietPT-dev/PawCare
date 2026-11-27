"""Optional HTTP worker. Dry run by default; never logs secrets or raw financial payloads."""
import hashlib, os, pathlib, sys, time
import requests
sys.path.insert(0,str(pathlib.Path(__file__).parents[1]/"src"))
from pawcare_ai.risk import restore, score
ENABLED=os.getenv("PAWCARE_AI_ENABLED","false").lower()=="true"; BASE=os.getenv("PAWCARE_API_BASE_URL","").rstrip("/"); TOKEN=os.getenv("PAWCARE_AI_WORKER_TOKEN","")
def request(method,path,body=None):
    if not ENABLED: print(f"dry-run {method} {path}"); return None
    if not BASE or not TOKEN: raise RuntimeError("PAWCARE_API_BASE_URL and PAWCARE_AI_WORKER_TOKEN are required when enabled")
    for attempt in range(3):
        try:
            r=requests.request(method,BASE+path,json=body,headers={"Authorization":f"Bearer {TOKEN}"},timeout=10); r.raise_for_status(); return r
        except requests.RequestException:
            if attempt==2: raise
            time.sleep(2**attempt)
def valid_result(x): return set(x)=={"risk_score","risk_level","explanation","model_version"} and 0<=x["risk_score"]<=1 and x["risk_level"] in {"LOW","MEDIUM","HIGH"}
def main():
    response=request("GET","/api/v1/internal/ai/scoring-events")
    if response is None: return
    seen=set()
    for event in response.json():
        eid=str(event.get("id","")); key=hashlib.sha256(eid.encode()).hexdigest()
        if not eid or key in seen: continue
        # Backend supplies a validated non-PII feature payload; no database access occurs here.
        import pandas as pd
        row=score(restore(os.getenv("PAWCARE_AI_MODEL","models/isolation_forest.joblib"))["model"],pd.DataFrame([event["features"]])).iloc[0]
        result={k:row[k] for k in ["risk_score","risk_level","explanation","model_version"]}
        if valid_result(result): request("POST",f"/api/v1/internal/ai/scoring-events/{eid}/result",result); seen.add(key)
if __name__=="__main__": main()
