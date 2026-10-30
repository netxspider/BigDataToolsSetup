# ==============================================================================
# Makefile - BigDataToolsSetup Developer Automation
# Provides quick shortcuts for managing the stack and running MapReduce jobs.
# ==============================================================================

.PHONY: help up down status ps logs shell build run output clean-output test

help:
	@echo "Available commands:"
	@echo "  make up               - Start all Docker containers in background"
	@echo "  make down             - Stop all containers (preserves volume data)"
	@echo "  make status (or ps)   - Show status of running containers"
	@echo "  make logs             - View logs of hadoop-master"
	@echo "  make shell            - Open an interactive bash shell in hadoop-master"
	@echo "  make build            - Compile and package WordCount MapReduce JAR"
	@echo "  make run              - Run WordCount MapReduce job on Hadoop YARN"
	@echo "  make output           - Display WordCount results from HDFS"
	@echo "  make test             - Complete end-to-end build, run, and output test"

up:
	docker compose up -d

down:
	docker compose down

status ps:
	docker compose ps

logs:
	docker compose logs -f hadoop-master

shell:
	docker compose exec hadoop-master bash

build:
	docker compose exec hadoop-master bash /workspace/projects/WordCount/build.sh

run:
	docker compose exec hadoop-master bash /workspace/projects/WordCount/run.sh

output:
	docker compose exec hadoop-master hdfs dfs -cat /wordcount/output/part-*

test: build run output
