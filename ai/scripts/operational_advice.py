import argparse, json, pathlib, sys
import pandas as pd
sys.path.insert(0,str(pathlib.Path(__file__).parents[1]/"src"))
from pawcare_ai.generator import generate_query_telemetry
from pawcare_ai.advisors import train_index_advisor, recommend_index, forecast_growth
p=argparse.ArgumentParser(); p.add_argument("--telemetry",default=None); p.add_argument("--growth",default="data/generated/growth.csv"); p.add_argument("--threshold",type=int,default=1500000); a=p.parse_args()
telemetry=pd.read_csv(a.telemetry) if a.telemetry else generate_query_telemetry()
print(json.dumps({"index_recommendations":recommend_index(train_index_advisor(telemetry),telemetry.head(20)),"growth_forecast":forecast_growth(pd.read_csv(a.growth),a.threshold)},ensure_ascii=False,indent=2))
