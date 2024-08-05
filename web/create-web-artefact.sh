#!/usr/bin/env bash
rm ../web-artefact.zip
zip -r ../web-artefact.zip . -x "./*/\.terraform*" -x "./*/*\.tfstate*" -x "*/*.tfvars"
ls -asl
