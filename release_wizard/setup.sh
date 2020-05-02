#!/bin/bash

python -m venv venv

. ./venv/bin/activate

pip install --upgrade pip

pip install -r release_wizard/requirements.txt
