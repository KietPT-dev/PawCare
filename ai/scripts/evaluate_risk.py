import argparse, pathlib, sys
import pandas as pd
from sklearn.metrics import precision_score, recall_score
sys.path.insert(0,str(pathlib.Path(__file__).parents[1]/"src"))
from pawcare_ai.risk import restore, score
p=argparse.ArgumentParser(); p.add_argument("--input",default="data/generated/transactions.csv"); p.add_argument("--model",default="models/isolation_forest.joblib"); a=p.parse_args()
d=pd.read_csv(a.input); s=score(restore(a.model)["model"],d); truth=d.scenario.ne("NORMAL"); high=s.risk_level.eq("HIGH")
print({"precision":round(precision_score(truth,high,zero_division=0),4),"recall":round(recall_score(truth,high,zero_division=0),4),"recall_at_high_risk":round((truth&high).sum()/truth.sum(),4),"high_risk_count":int(high.sum())})
