#!/bin/bash

function venv-activate {
source venv/bin/activate
}

function venv-create {
  python -m venv venv
}

function venv-activate-dbg {
source venv/bin/activate
# Needed for DAP
pip install debugpy
}
