.PHONY: lite-init
lite-init: generate-secrets
	$(MAKE) download-default-certs
	$(MAKE) -B docker-compose.yml
	$(MAKE) pull
	mkdir -p $(CURDIR)/codebase

.PHONY: run-lite-migrations
## Runs migrations of islandora
.SILENT: run-lite-migrations
run-lite-migrations:
	#docker-compose exec -T drupal with-contenv bash -lc "for_all_sites import_islandora_migrations"
	# this line can be reverted when https://github.com/Islandora-Devops/isle-buildkit/blob/fae704f065435438828c568def2a0cc926cc4b6b/drupal/rootfs/etc/islandora/utilities.sh#L557
	# has been updated to match
	docker-compose exec -T drupal with-contenv bash -lc 'drush -l $(SITE) migrate:import islandora_tags'

.PHONY: lite_hydrate
.SILENT: lite_hydrate
## Reconstitute the site from environment variables.
lite_hydrate: update-settings-php update-config-from-environment solr-cores namespaces run-lite-migrations
	docker-compose exec -T drupal drush cr -y

.PHONY: lite_dev
## Make a local site with codebase directory bind mounted, using cloned starter site.
lite_dev: QUOTED_CURDIR = "$(CURDIR)"
lite_dev: generate-secrets
	$(MAKE) lite-init ENVIRONMENT=local
	if [ -z "$$(ls -A $(QUOTED_CURDIR)/codebase)" ]; then \
		docker container run --rm -v $(CURDIR)/codebase:/home/root $(REPOSITORY)/nginx:$(TAG) with-contenv bash -lc 'git clone https://github.com/digitalutsc/islandora-sandbox.git --branch 1.0.0-beta1 /home/root;'; \
	fi
	$(MAKE) set-files-owner SRC=$(CURDIR)/codebase ENVIRONMENT=local
	docker-compose up -d --remove-orphans

	# install imagemagick plugin
	docker-compose exec -T drupal apk --update add imagemagick
	docker-compose exec -T drupal apk add php7-imagick
	docker-compose restart drupal

	# install ffmpeg needed to create TNs
	docker-compose exec -T drupal apk --update add ffmpeg
	-docker-compose exec -T drupal drush -y config:set media_thumbnails_video.settings ffmpeg /usr/bin/ffmpeg
	-docker-compose exec -T drupal drush -y config:set media_thumbnails_video.settings ffprobe /usr/bin/ffprobe
	docker-compose restart drupal

	# install the site
	docker-compose exec -T drupal with-contenv bash -lc 'composer install'
	$(MAKE) lite-finalize ENVIRONMENT=local

.PHONY: lite-finalize
lite-finalize:
	docker-compose exec -T drupal with-contenv bash -lc 'chown -R nginx:nginx .'
	$(MAKE) drupal-database update-settings-php
	docker-compose exec -T drupal with-contenv bash -lc "drush si -y --existing-config minimal --account-pass '$(shell cat secrets/live/DRUPAL_DEFAULT_ACCOUNT_PASSWORD)'"
	MIGRATE_IMPORT_USER_OPTION=--userid=1 $(MAKE) lite_hydrate
	$(MAKE) login

