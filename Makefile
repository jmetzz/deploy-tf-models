.PHONY: clean lint create_env erase_env reset_env sync_data_to_s3 sync_data_from_s3 sync_data_to_gcp sync_data_from_gcp

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
S3_BUCKET = [OPTIONAL] your-bucket-for-syncing-data (do not include 's3://')
S3_PROFILE = default
GCP_PROJECT = [OPTIONAL] your-GCP-project-name
GCP_BUCKET = [OPTIONAL] your-bucket-for-syncing-data (do not include 'gs://')

PROJECT_NAME = deploy-tf-models
PYTHON_INTERPRETER = python3.7
PROFILE = default



ifeq (,$(shell which virtualenv))
HAS_VIRTUALENV=False
else
HAS_VIRTUALENV=True
endif

ifneq ($(wildcard .venv),)
EXIST_VENV=True
else
EXIST_VENV=False
endif


#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Install Python Dependencies
create_env:
ifeq (False,$(HAS_VIRTUALENV))
	@echo "virtualenv not installed yet. Installing ..."
	$(PYTHON_INTERPRETER) -m pip install virtualenv
	@echo ">>> virtualenv installed."
else
	@echo ">>> virtualenv available"
endif
ifeq (False,$(EXIST_VENV))
	@echo ">>> Creating virtualenv for project..."
	$(PYTHON_INTERPRETER) -m venv .venv
endif
	@echo ">>> Activating environment ..."
	@which $(PYTHON_INTERPRETER)
	. .venv/bin/activate && $(PYTHON_INTERPRETER) -m pip install -U pip setuptools wheel
	. .venv/bin/activate && $(PYTHON_INTERPRETER) -m pip install -r requirements.txt


## Remove current virtual environment
erase_env:
	rm -rf .venv

## Re-create and virtual environment and install all dependencies
reset_env: erase_env create_env
	@echo "New environment prepared."


## Delete all compiled Python files
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete

## Lint using flake8
lint:
	flake8 src

## Upload Data to S3
sync_data_to_s3:
ifeq (default,$(PROFILE))
	aws s3 sync data/ s3://$(BUCKET)/data/
else
	aws s3 sync data/ s3://$(BUCKET)/data/ --profile $(PROFILE)
endif

## Download Data from S3
sync_data_from_s3:
ifeq (default,$(PROFILE))
	aws s3 sync s3://$(S3_BUCKET)/data/ data/
else
	aws s3 sync s3://$(S3_BUCKET)/data/ data/ --profile $(PROFILE)
endif


## Upload Data to GCP Storage Bucket
sync_data_to_gcp:
ifeq (default,$(PROFILE))
	gsutil sync data/ gs://$(BUCKET)/data/
else
	gsutil sync data/ -p $(GCP_PROJECT) gs://$(BUCKET)/data/
endif

## Download Data from GCP Storage Bucket
sync_data_from_gcp:
ifeq (default,$(PROFILE))
	gsutil sync gs://$(GCP_BUCKET)/data/ data/
else
	gsutil sync -p $(GCP_PROJECT) gs://$(GCP_BUCKET)/data/ data/
endif



#################################################################################
# PROJECT RULES                                                                 #
#################################################################################



#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
