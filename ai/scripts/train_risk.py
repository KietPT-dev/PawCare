import argparse, pathlib, sys
import pandas as pd
sys.path.insert(0,str(pathlib.Path(__file__).parents[1]/"src"))
from pawcare_ai.risk import train, save
p=argparse.ArgumentParser(); p.add_argument("--input",default="data/generated/transactions.csv"); p.add_argument("--model",default="models/isolation_forest.joblib"); p.add_argument("--seed",type=int,default=20261127); a=p.parse_args()
pathlib.Path(a.model).parent.mkdir(parents=True,exist_ok=True); save(train(pd.read_csv(a.input),a.seed),a.model,a.seed); print(f"model_saved={a.model}")
