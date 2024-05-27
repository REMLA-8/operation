from typing import Generator
import httpx
from  httpx import Client
import pytest

MODEL_SERVICE_URL = "http://10.10.10.0/api"

@pytest.fixture
def service_client() -> Generator[Client, None, None]:
    yield Client(base_url=MODEL_SERVICE_URL)

def test_service(service_client: Client):
    r = service_client.post("/predict", json={'url': 'tudelft.nl'})
    assert r.status_code == 200
    result_json = r.json()
    assert 'score' in result_json
    assert isinstance(result_json['score'], list)
    assert len(result_json['score']) == 1

def test_service_two(service_client: Client):
    r = service_client.post("/predict", json={'url': ['tudelft.nl', 'google.com']})
    assert r.status_code == 200
    result_json = r.json()
    assert 'score' in result_json
    assert isinstance(result_json['score'], list)
    assert len(result_json['score']) == 2