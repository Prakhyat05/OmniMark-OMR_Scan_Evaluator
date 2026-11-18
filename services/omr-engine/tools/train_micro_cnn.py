"""
Lightweight Micro-CNN Training & Model Exporter for Offline Mobile OMR.
Trains an ultra-compact (< 100 KB) 4-class bubble classifier:
  Class 0: BLANK
  Class 1: FULLY_FILLED
  Class 2: ERASED_SMUDGED
  Class 3: INVALID_PARTIAL
Exports:
- PyTorch state_dict: bubble_classifier.pt
- TorchScript mobile model: bubble_classifier_mobile.pt
- Portable parameter weights JSON: bubble_classifier_weights.json (for direct pure-Dart/C++ inference)
"""
import os
import time
import glob
import json
import cv2
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader

class BubbleDataset(Dataset):
    def __init__(self, root_dir, split="train"):
        self.samples = []
        self.labels = []
        
        classes = ["0_blank", "1_filled", "2_erased_smudged", "3_invalid_partial"]
        for class_idx, class_name in enumerate(classes):
            pattern = os.path.join(root_dir, split, class_name, "*.png")
            files = glob.glob(pattern)
            for f in files:
                self.samples.append(f)
                self.labels.append(class_idx)
                
        print(f"[+] Loaded {len(self.samples)} samples for {split} set.")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        path = self.samples[idx]
        img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
        if img is None:
            img = np.ones((32, 32), dtype=np.uint8) * 255
        
        # Normalize to [0.0, 1.0] and add channel dimension (1, 32, 32)
        tensor = torch.tensor(img, dtype=torch.float32).unsqueeze(0) / 255.0
        label = torch.tensor(self.labels[idx], dtype=torch.long)
        return tensor, label


class BubbleMicroCNN(nn.Module):
    def __init__(self, num_classes=4):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(1, 16, kernel_size=3, padding=1),
            nn.BatchNorm2d(16),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2, 2),  # 16x16
            
            nn.Conv2d(16, 32, kernel_size=3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2, 2),  # 8x8
            
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.AdaptiveAvgPool2d((1, 1))  # 1x1
        )
        self.classifier = nn.Sequential(
            nn.Flatten(),
            nn.Linear(64, 32),
            nn.ReLU(inplace=True),
            nn.Dropout(0.2),
            nn.Linear(32, num_classes)
        )

    def forward(self, x):
        feat = self.features(x)
        out = self.classifier(feat)
        return out


def train_and_export(dataset_dir="services/omr-engine/dataset", output_dir="services/omr-engine/assets/models"):
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs("apps/mobile/assets/models", exist_ok=True)
    
    train_ds = BubbleDataset(dataset_dir, split="train")
    test_ds = BubbleDataset(dataset_dir, split="test")
    
    train_loader = DataLoader(train_ds, batch_size=64, shuffle=True)
    test_loader = DataLoader(test_ds, batch_size=64, shuffle=False)
    
    model = BubbleMicroCNN(num_classes=4)
    param_count = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"[+] Micro-CNN total parameters: {param_count:,} (Ultra-compact!)")
    
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=0.002, weight_decay=1e-4)
    
    epochs = 12
    print(f"\n[+] Starting training for {epochs} epochs on CPU...")
    start_time = time.time()
    
    for epoch in range(1, epochs + 1):
        model.train()
        total_loss = 0.0
        correct = 0
        total = 0
        
        for images, labels in train_loader:
            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()
            
            total_loss += loss.item() * images.size(0)
            preds = outputs.argmax(dim=1)
            correct += (preds == labels).sum().item()
            total += labels.size(0)
            
        train_acc = (correct / total) * 100.0
        
        # Validation
        model.eval()
        val_correct = 0
        val_total = 0
        with torch.no_grad():
            for images, labels in test_loader:
                outputs = model(images)
                preds = outputs.argmax(dim=1)
                val_correct += (preds == labels).sum().item()
                val_total += labels.size(0)
                
        val_acc = (val_correct / val_total) * 100.0
        print(f"  Epoch {epoch:02d}/{epochs:02d} | Train Loss: {total_loss/total:.4f} | Train Acc: {train_acc:.2f}% | Val Acc: {val_acc:.2f}%")
    
    elapsed = time.time() - start_time
    print(f"\n[+] Training completed in {elapsed:.2f}s! Final Test Accuracy: {val_acc:.2f}%")
    
    # 1. Save PyTorch state dict
    pt_path = os.path.join(output_dir, "bubble_classifier.pt")
    torch.save(model.state_dict(), pt_path)
    print(f"[+] Saved PyTorch model: {pt_path}")
    
    # 2. Export TorchScript Mobile model
    model.eval()
    scripted_model = torch.jit.script(model)
    script_path = os.path.join(output_dir, "bubble_classifier_mobile.pt")
    mobile_script_path = os.path.join("apps/mobile/assets/models", "bubble_classifier_mobile.pt")
    scripted_model.save(script_path)
    scripted_model.save(mobile_script_path)
    print(f"[+] Saved TorchScript Mobile model ({os.path.getsize(script_path)/1024:.1f} KB) to:")
    print(f"    - {script_path}")
    print(f"    - {mobile_script_path}")
    
    # 3. Export weights to portable JSON (for native pure-Dart / C++ fast convolution forward pass without any external runtime!)
    weights_dict = {}
    for name, param in model.state_dict().items():
        weights_dict[name] = param.detach().cpu().numpy().tolist()
    
    weights_json_path = os.path.join(output_dir, "bubble_classifier_weights.json")
    mobile_weights_json_path = os.path.join("apps/mobile/assets/models", "bubble_classifier_weights.json")
    with open(weights_json_path, "w") as f:
        json.dump(weights_dict, f)
    with open(mobile_weights_json_path, "w") as f:
        json.dump(weights_dict, f)
    print(f"[+] Exported portable weights JSON to {mobile_weights_json_path}")
    
    # 4. Optional ONNX export if onnx is available
    try:
        import onnx
        onnx_path = os.path.join(output_dir, "bubble_classifier.onnx")
        mobile_onnx_path = os.path.join("apps/mobile/assets/models", "bubble_classifier.onnx")
        dummy_input = torch.randn(1, 1, 32, 32, dtype=torch.float32)
        torch.onnx.export(
            model,
            dummy_input,
            onnx_path,
            export_params=True,
            opset_version=13,
            do_constant_folding=True,
            input_names=["input"],
            output_names=["output"]
        )
        import shutil
        shutil.copy(onnx_path, mobile_onnx_path)
        print(f"[+] Exported ONNX model ({os.path.getsize(onnx_path)/1024:.1f} KB)")
    except Exception as e:
        print(f"[-] Skipped ONNX export: {e}")

    return val_acc

if __name__ == "__main__":
    train_and_export()
