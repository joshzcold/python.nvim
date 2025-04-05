import requests


def test_request():
    req = requests.get("https://neovim.io")
    assert "neovim" in req.text


def test_request_fail():
    req = requests.get("https://neovim.io")
    assert "neovim" not in req.text
