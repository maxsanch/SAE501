#!/usr/bin/env python3
import sys
import json
import pickle
import pandas as pd

# Charger le modèle exporté (RandomForest, XGBoost, etc.)
model = pickle.load(open('/var/www/IA/model/random_forest_model.pkl', 'rb'))# loads ML model

# Vérifier qu'on a un argument JSON
if len(sys.argv) < 2:
    print(json.dumps({"probability": 0}))
    sys.exit(0)

    
try:
    data = json.loads(sys.argv[1])
except json.JSONDecodeError:
    print(json.dumps({"probability": 0}))
    sys.exit(0)


client = data.get('client', {})
products = data.get('products', [])
# Gestion catégories et historique (one-hot)
cat_columns = ['cat_Amour', 'cat_Apaisant', 'cat_Fantaisie', 'cat_Historique', 'cat_Horreur', 'cat_SF']  # exemple, adapter à tes colonnes
hist_columns = ['hist_Amour','hist_Apaisant','hist_Fantaisie','hist_Historique','hist_Horreur','hist_None','hist_SF']  # exemple
results = []

# Construire le dictionnaire des features
for p in products:
    features = {
        'sexe': client.get('sexe', 1),
        'age': float(client.get('age', 25)),
        'intensite': float(p.get('intensite', 0)),
        'prix': float(p.get('prix', 0)),
    }

    categorie = data.get('categorie', 'None')
    historique = data.get('historique', 'None')

    for col in cat_columns:
        features[col] = 1 if col == f'cat_{categorie}' else 0
    for col in hist_columns:
        features[col] = 1 if col == f'hist_{historique}' else 0

    # Transformer en DataFrame
    final_features = pd.DataFrame([features])

    # Prédiction
    proba = model.predict_proba(final_features)[0][1]
    pred = model.predict(final_features)
    results.append({
        "id": p.get('id'),
        "probability": float(proba),
        "guess": int(pred)
    })

# Retourner au PHP
print(json.dumps(results))