"""
MixStyle — feature-statistics mixing for domain generalization.

Reference: Zhou et al., "Domain Generalization with MixStyle", ICLR 2021.

Intuition for KulimaIQ
──────────────────────
A leaf infected by the same disease looks different across agro-ecological
zones: highland light is cool and bright, lowland light is warm and hazy,
humid air lowers contrast, altitude changes colour saturation. These are
largely *style* differences (captured by per-channel feature mean/variance),
while the *content* — the lesion pattern that identifies the disease — stays
the same.

MixStyle mixes the channel-wise mean and standard deviation between different
samples in a batch during training. This synthesises new, unseen "location
styles" on the fly, forcing the network to rely on disease *content* rather
than location-specific *appearance*. The result is a model that stays accurate
in whatever location the leaf comes from — with no location input at all.

MixStyle has NO learnable parameters and is DISABLED at evaluation/inference,
so a model trained with it produces an ordinary MobileNetV2 state_dict.
"""

from __future__ import annotations

import torch
import torch.nn as nn


class MixStyle(nn.Module):
    def __init__(self, p: float = 0.5, alpha: float = 0.1, eps: float = 1e-6) -> None:
        """
        Args:
            p:      probability of applying MixStyle to a given batch.
            alpha:  Beta distribution parameter controlling the mix strength.
            eps:    numerical stability for the standard deviation.
        """
        super().__init__()
        self.p = p
        self.beta = torch.distributions.Beta(alpha, alpha)
        self.eps = eps
        self._activated = True

    def set_activated(self, flag: bool) -> None:
        self._activated = flag

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # Only active in training, only fires with probability p, needs a batch.
        if not self.training or not self._activated:
            return x
        if x.size(0) < 2 or torch.rand(1).item() > self.p:
            return x

        b = x.size(0)
        mu = x.mean(dim=[2, 3], keepdim=True)
        var = x.var(dim=[2, 3], keepdim=True)
        sig = (var + self.eps).sqrt()
        # Normalise (detach stats — we only want to transplant style, not
        # backprop through the statistics themselves).
        x_norm = (x - mu.detach()) / sig.detach()

        lam = self.beta.sample((b, 1, 1, 1)).to(x.device)
        perm = torch.randperm(b, device=x.device)
        mu2, sig2 = mu[perm], sig[perm]

        # Interpolate the style statistics between each sample and a shuffled
        # partner, then re-apply → a novel, synthetic "location style".
        mu_mix = lam * mu + (1 - lam) * mu2
        sig_mix = lam * sig + (1 - lam) * sig2
        return x_norm * sig_mix + mu_mix
