"""Shared fixtures — mock MongoDB and ML model so tests run offline."""

from __future__ import annotations

from contextlib import ExitStack
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def mock_users_store():
    return {}


@pytest.fixture
def mock_diagnoses_store():
    return []


@pytest.fixture
def mock_inference_service():
    svc = MagicMock()
    svc.is_ready = True
    svc.classes = [
        "healthy",
        "tomato_early_blight",
        "tomato_late_blight",
        "potato_late_blight",
    ]
    svc.predict.return_value = {
        "healthy": 0.08,
        "tomato_early_blight": 0.12,
        "tomato_late_blight": 0.62,
        "potato_late_blight": 0.05,
    }
    return svc


@pytest.fixture
def client(mock_users_store, mock_diagnoses_store, mock_inference_service):
    users_col = MagicMock()

    async def find_one(query, *_args, **_kwargs):
        if "_id" in query:
            return mock_users_store.get(query["_id"])
        if "phone" in query:
            phone = query["phone"]
            for doc in mock_users_store.values():
                if doc.get("phone") == phone:
                    return doc
        return None

    async def insert_one(doc):
        mock_users_store[doc["_id"]] = doc
        return MagicMock(inserted_id=doc["_id"])

    users_col.find_one = AsyncMock(side_effect=find_one)
    users_col.insert_one = AsyncMock(side_effect=insert_one)

    diagnoses_col = MagicMock()
    diagnoses_col.insert_one = AsyncMock(
        side_effect=lambda doc: mock_diagnoses_store.append(doc)
    )

    farms_col = MagicMock()
    farms_col.find = MagicMock(
        return_value=MagicMock(
            to_list=AsyncMock(return_value=[]),
        )
    )

    patches = [
        patch("app.main.init_db", new_callable=AsyncMock),
        patch("app.main.ensure_demo_user", new_callable=AsyncMock),
        patch("app.main.close_db", new_callable=AsyncMock),
        patch("app.main.init_inference_service"),
        patch("app.database.init_db", new_callable=AsyncMock),
        patch("app.database.check_db", new_callable=AsyncMock, return_value=True),
        patch("app.database.users_col", return_value=users_col),
        patch("app.database.diagnoses_col", return_value=diagnoses_col),
        patch("app.database.farms_col", return_value=farms_col),
        patch("app.auth.users_col", return_value=users_col),
        patch("app.routers.auth.users_col", return_value=users_col),
        patch("app.routers.analyze.diagnoses_col", return_value=diagnoses_col),
        patch("app.routers.analyze.farms_col", return_value=farms_col),
        patch("app.routers.diagnoses.diagnoses_col", return_value=diagnoses_col),
        patch("app.routers.farms.farms_col", return_value=farms_col),
        patch("app.routers.farms.diagnoses_col", return_value=diagnoses_col),
        patch(
            "app.ml.inference.get_inference_service",
            return_value=mock_inference_service,
        ),
        patch(
            "app.routers.analyze.get_inference_service",
            return_value=mock_inference_service,
        ),
        patch(
            "app.routers.crops.get_inference_service",
            return_value=mock_inference_service,
        ),
    ]

    with ExitStack() as stack:
        for item in patches:
            stack.enter_context(item)
        from app.main import app

        with TestClient(app) as test_client:
            yield test_client
