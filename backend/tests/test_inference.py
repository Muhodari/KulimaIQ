"""Unit tests for crop-filtered disease label selection."""

from app.ml.inference import (
    filter_probs_by_crop,
    normalize_probs,
    pick_crop_label,
)


def test_filter_probs_by_crop_keeps_healthy_and_crop_diseases():
    raw = {
        "healthy": 0.1,
        "tomato_late_blight": 0.5,
        "tomato_early_blight": 0.2,
        "potato_late_blight": 0.2,
    }
    filtered = filter_probs_by_crop(raw, "tomato")
    assert set(filtered.keys()) == {
        "healthy",
        "tomato_late_blight",
        "tomato_early_blight",
    }
    assert filtered["tomato_late_blight"] == 0.5


def test_pick_crop_label_prefers_disease_when_healthy_not_confident():
    filtered = {
        "healthy": 0.08,
        "tomato_late_blight": 0.62,
        "tomato_early_blight": 0.12,
    }
    label, confidence = pick_crop_label(filtered)
    assert label == "tomato_late_blight"
    assert confidence == 0.62


def test_pick_crop_label_returns_healthy_when_clearly_confident():
    filtered = {
        "healthy": 0.82,
        "tomato_late_blight": 0.05,
        "tomato_early_blight": 0.04,
    }
    label, confidence = pick_crop_label(filtered)
    assert label == "healthy"
    assert confidence == 0.82


def test_normalize_probs_sums_to_one():
    filtered = {"healthy": 0.1, "tomato_late_blight": 0.3}
    normalized = normalize_probs(filtered)
    assert abs(sum(normalized.values()) - 1.0) < 1e-6


def test_renormalization_would_inflate_healthy_display_only():
    """Document why top-1 uses raw probs, not normalized display values."""
    filtered = {
        "healthy": 0.08,
        "tomato_late_blight": 0.04,
        "tomato_early_blight": 0.03,
    }
    label_raw, _ = pick_crop_label(filtered)
    top_normalized = max(
        normalize_probs(filtered).items(), key=lambda item: item[1]
    )[0]
    assert label_raw == "tomato_late_blight"
    assert top_normalized == "healthy"
