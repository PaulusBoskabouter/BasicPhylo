import pandas as pd
import json
# example of loading in created json result
f = open("Colorado-21_MB.json")
a= json.load(f)
c= pd.DataFrame.from_dict(a.get('distance'))
print(c)