"""
KulimaIQ disease-detection CNN — dynamic multi-class version.

Architecture: MobileNetV2 pretrained on ImageNet, final classifier replaced
with an N-class head where N is determined at training time from the dataset
folder structure.

Class labels (folder names) are saved inside the checkpoint so that the
inference service never needs to know them ahead of time.

Naming convention for class folders
─────────────────────────────────────
  {crop}_{condition}

  Examples:
    healthy              ← a single "healthy" bucket (all crops)
    cassava_mosaic       ← Cassava Mosaic Disease (CMD)
    maize_necrosis       ← Maize Lethal Necrosis (MLN)
    banana_wilt          ← Banana Xanthomonas Wilt (BXW)
    tomato_late_blight
    tomato_early_blight
    potato_late_blight
    bean_angular_spot
    coffee_leaf_rust
    rice_blast
    … (add as many as you have data for)
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models
from torchvision.models import MobileNet_V2_Weights

from .mixstyle import MixStyle

# Input size expected by MobileNetV2
INPUT_SIZE = 224


def build_model(num_classes: int, pretrained: bool = True,
                freeze_backbone: bool = False) -> nn.Module:
    """Return a MobileNetV2 with a custom N-class classifier head.

    Args:
        num_classes:      Number of output classes (determined from dataset).
        pretrained:       Load ImageNet weights for the backbone.
        freeze_backbone:  If True, only the classifier is trained.
    """
    weights = MobileNet_V2_Weights.DEFAULT if pretrained else None
    model = models.mobilenet_v2(weights=weights)

    if freeze_backbone:
        for param in model.features.parameters():
            param.requires_grad = False

    in_features = model.classifier[1].in_features
    model.classifier = nn.Sequential(
        nn.Dropout(p=0.3),
        nn.Linear(in_features, 512),
        nn.ReLU(),
        nn.Dropout(p=0.2),
        nn.Linear(512, num_classes),
    )
    return model


class MixStyleMobileNet(nn.Module):
    """MobileNetV2 with MixStyle inserted after early feature blocks.

    Used only for *training* the location-invariant model. Its parameters and
    module names (``features.*`` / ``classifier.*``) are identical to
    ``build_model`` output, so the checkpoint loads back into the plain model
    for inference — where MixStyle does not exist and therefore never fires.

    MixStyle is applied after early blocks (where feature statistics still
    encode low-level "style" such as colour/lighting/contrast) to simulate
    unseen agro-ecological location appearances during training.
    """

    def __init__(self, num_classes: int, pretrained: bool = True,
                 mixstyle_layers: tuple[int, ...] = (3, 6),
                 p: float = 0.5, alpha: float = 0.1) -> None:
        super().__init__()
        base = build_model(num_classes, pretrained=pretrained)
        self.features = base.features
        self.classifier = base.classifier
        self._mixstyle_layers = set(mixstyle_layers)
        self.mixstyle = MixStyle(p=p, alpha=alpha)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        for idx, block in enumerate(self.features):
            x = block(x)
            if idx in self._mixstyle_layers:
                x = self.mixstyle(x)
        x = F.adaptive_avg_pool2d(x, 1)
        x = torch.flatten(x, 1)
        return self.classifier(x)


def load_model(weights_path: str, device: str = "cpu"):
    """
    Load a trained model from a checkpoint file.

    Returns:
        model:   nn.Module in eval mode
        classes: list[str] — class labels in index order
    """
    state = torch.load(weights_path, map_location=device, weights_only=False)

    if isinstance(state, dict) and "classes" in state:
        classes: list[str] = state["classes"]
        model = build_model(num_classes=len(classes), pretrained=False)
        model.load_state_dict(state["model_state_dict"])
    else:
        # Legacy checkpoint (raw state_dict, 4 classes)
        classes = ["healthy", "cassava_mosaic", "maize_necrosis", "banana_wilt"]
        model = build_model(num_classes=len(classes), pretrained=False)
        model.load_state_dict(state)

    model.eval()
    return model, classes
