import argparse, pathlib, sys
sys.path.insert(0,str(pathlib.Path(__file__).parents[1]/"src"))
from pawcare_ai.generator import generate_transactions, generate_growth
p=argparse.ArgumentParser(); p.add_argument("--rows",type=int,default=85000); p.add_argument("--seed",type=int,default=20261127); p.add_argument("--anomaly-rate",type=float,default=.02); p.add_argument("--output",default="data/generated/transactions.csv"); a=p.parse_args()
pathlib.Path(a.output).parent.mkdir(parents=True,exist_ok=True); d=generate_transactions(a.rows,a.seed,a.anomaly_rate); d.to_csv(a.output,index=False)
growth=generate_growth(seed=a.seed); growth.to_csv(str(pathlib.Path(a.output).with_name("growth.csv")),index=False)
print(f"generated={len(d)} anomaly_rate={(d.scenario != 'NORMAL').mean():.4f} output={a.output}")
