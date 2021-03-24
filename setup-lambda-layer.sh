#!/bin/bash

PWD=$(pwd)
LAMBDA_DIRECTORY="$PWD/terraform-aws-maskopy/lambda"
LAYER_DIRECTORY="$PWD/terraform-aws-maskopy/lambda_layer_payload/"
mkdir -p "${LAYER_DIRECTORY}"

python -m pip install -r "${LAMBDA_DIRECTORY}/requirements.txt" -t "${LAYER_DIRECTORY}"