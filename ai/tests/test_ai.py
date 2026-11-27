import pathlib, sys
import pandas as pd
sys.path.insert(0,str(pathlib.Path(__file__).parents[1]/"src"))
from pawcare_ai.generator import generate_transactions, generate_growth
from pawcare_ai.risk import train, score
from pawcare_ai.advisors import train_index_advisor, recommend_index, forecast_growth

def test_generator_is_deterministic_and_has_schema():
    a=generate_transactions(1000,42,.02); b=generate_transactions(1000,42,.02)
    assert a.equals(b) and len(a)==1000 and a.is_synthetic.all()
    assert .01 <= a.scenario.ne("NORMAL").mean() <= .03
def test_scenario_not_feature_and_scores_are_bounded():
    data=generate_transactions(500,42,.02); out=score(train(data,42),data)
    assert out.risk_score.between(0,1).all() and "scenario" not in train(data,42).feature_names_in_
    assert set(out.risk_level) <= {"LOW","MEDIUM","HIGH"}
def test_single_event_uses_training_calibration_not_its_own_batch_range():
    data=generate_transactions(600,24,.02); model=train(data,24)
    raw=-model.decision_function(data[[*model.feature_names_in_]])
    index=int(raw.argmax())
    batch=score(model,data).iloc[index]
    single=score(model,data.iloc[[index]]).iloc[0]
    assert single.risk_score == batch.risk_score and single.risk_score > 0
def test_index_payload_and_growth_warning_contract():
    tel=pd.DataFrame([{"table":"synthetic_events","candidate_columns":"profile_id,occurred_at","query_frequency":100,"scan_ratio":.8,"table_size":100000,"selectivity":.01,"cardinality":50000,"skew":.1,"candidate_column_count":2,"label":"COMPOSITE_BTREE_CANDIDATE"},{"table":"synthetic_events","candidate_columns":"status","query_frequency":1,"scan_ratio":.01,"table_size":100,"selectivity":.9,"cardinality":2,"skew":.8,"candidate_column_count":1,"label":"NO_INDEX"}])
    payload=recommend_index(train_index_advisor(tel),tel)[0]
    assert payload["expected_review_required"] is True and payload["recommendation"] in {"NO_INDEX","BTREE_CANDIDATE","COMPOSITE_BTREE_CANDIDATE"}
    assert len(forecast_growth(generate_growth(60),1500000))==3
