import joblib
import numpy as np
from sklearn.tree import DecisionTreeClassifier


# Features: [moisture, temperature]
X = np.array([
    [10, 22], [15, 28], [20, 35], [25, 32], [29, 26],
    [30, 25], [35, 29], [40, 31], [45, 27], [50, 30], [55, 34], [59, 33],
    [60, 24], [65, 27], [70, 29], [75, 31], [80, 33], [90, 35],
], dtype=float)

# Label: 1 = need water (motor ON), 0 = no water needed (motor OFF)
y = np.array([
    1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
], dtype=int)

model = DecisionTreeClassifier(max_depth=3, random_state=42)
model.fit(X, y)

joblib.dump(model, 'model.pkl')
print('model.pkl generated successfully')
