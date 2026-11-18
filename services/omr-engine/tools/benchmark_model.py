"""
Model Inference Benchmark & Verification Harness.
Benchmarks inference latency on CPU for single bubbles and full 200-question sheets.
"""
import os
import time
import cv2
import numpy as np
import torch
from app.processors.detect_bubbles import get_global_threshold

def benchmark_inference(pt_model_path: str, test_dir: str):
    from tools.train_micro_cnn import BubbleMicroCNN
    
    model = BubbleMicroCNN(num_classes=4)
    model.load_state_dict(torch.load(pt_model_path, map_location="cpu"))
    model.eval()
    
    print(f"[+] Loaded model from {pt_model_path}")
    
    # 1. Benchmark single bubble latency
    dummy_bubble = torch.randn(1, 1, 32, 32, dtype=torch.float32)
    
    # Warmup
    for _ in range(50):
        _ = model(dummy_bubble)
        
    iterations = 500
    start = time.perf_counter()
    for _ in range(iterations):
        _ = model(dummy_bubble)
    single_bubble_ms = ((time.perf_counter() - start) / iterations) * 1000.0
    
    # 2. Benchmark batch inference for 200 questions (800 bubbles + 60 code bubbles = 860 bubbles)
    full_sheet_batch = torch.randn(860, 1, 32, 32, dtype=torch.float32)
    
    for _ in range(10):
        _ = model(full_sheet_batch)
        
    start = time.perf_counter()
    for _ in range(50):
        _ = model(full_sheet_batch)
    full_sheet_ms = ((time.perf_counter() - start) / 50) * 1000.0
    
    print(f"\n=======================================================")
    print(f"MICRO-CNN BENCHMARK METRICS (CPU):")
    print(f"  -> Single Bubble Latency: {single_bubble_ms:.3f} ms")
    print(f"  -> Full Sheet (860 Bubbles Batched): {full_sheet_ms:.2f} ms")
    print(f"  -> Throughput: {860.0 / (full_sheet_ms / 1000.0):,.0f} bubbles/sec")
    print(f"=======================================================\n")
    return single_bubble_ms, full_sheet_ms

if __name__ == "__main__":
    benchmark_inference(
        "services/omr-engine/assets/models/bubble_classifier.pt",
        "services/omr-engine/dataset/test"
    )
