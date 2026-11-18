import json

with open("services/omr-engine/assets/exact_vector_blueprint.json") as f:
    data = json.load(f)

qs = data['questions']

# Summary of each column
print("=== EXACT VECTOR QUESTION BLUEPRINTS ===")
for col_num, (q_start, q_end) in enumerate([(1, 26), (27, 52), (53, 89), (90, 126), (127, 163), (164, 200)]):
    q_first = qs[str(q_start)]
    q_last = qs[str(q_end)]
    opts_x = [f"{x:.5f}" for x in q_first['opt_cx_norm']]
    rx = q_first['rx_norm']
    ry = q_first['ry_norm']
    print(f"\nColumn {col_num+1} (Q{q_start:3d}..Q{q_end:3d}):")
    print(f"  Option Bubble Centers X: {opts_x}")
    print(f"  Start Y: {q_first['opt_cy_norm']:.5f} | End Y: {q_last['opt_cy_norm']:.5f}")
    print(f"  Bubble Radius Norm: rx={rx:.5f} (w={rx*2*594.72:.2f} pt), ry={ry:.5f} (h={ry*2*841.68:.2f} pt)")
