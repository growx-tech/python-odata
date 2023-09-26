.PHONY: authenticate development deploy_new_version clean lint

#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
CODE_ARTIFACT_URL := $(aws codeartifact get-repository-endpoint --domain growx  --format pypi --query repositoryEndpoint --output text --repository growx-data)
CODE_ARTIFACT_USER = aws
CODE_ARTIFACT_TOKEN := $(shell aws codeartifact get-authorization-token --domain growx --query authorizationToken --output text)

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Authenticate poetry (after awsume role)
authenticate:
	poetry config http-basic.growx-data aws $(CODE_ARTIFACT_TOKEN) --local
	poetry config http-basic.codeartifact $(CODE_ARTIFACT_USER) $(CODE_ARTIFACT_TOKEN)
	poetry config repositories.codeartifact $(CODE_ARTIFACT_URL)

## Install development environment
development:
	poetry config http-basic.growx-data aws $(CODE_ARTIFACT_TOKEN) --local
	poetry install
	poetry run pre-commit install

## Upload a new version to code artifact
deploy_new_version:
	poetry build
	poetry publish -r codeartifact --skip-existing

## Cleanup python generated files.
clean:
	rm -rf `find . -name __pycache__`
	rm -rf `find . -name .pytest_cache`
	rm -rf `find . -name *.egg-info`
	rm -f `find . -type f -name '*.py[co]' `
	rm -f `find . -type f -name '*~' `
	rm -f `find . -type f -name '.*~' `
	rm -f `find . -type f -name '@*' `
	rm -f `find . -type f -name '#*#' `
	rm -f `find . -type f -name '*.orig' `
	rm -f `find . -type f -name '*.rej' `
	rm -f .coverage*
	rm -rf coverage
	rm -rf coverage.xml
	rm -rf htmlcov
	rm -rf build
	rm -rf cover
	rm -rf dist

## Lint all python code using flake8
lint:
	flake8 src tests


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
