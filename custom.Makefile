# islandora_lite
# Updates configuration from environment variables.
# Allow all commands to fail as the user may not have all the modules like matomo, etc.
.PHONY: hydrate-local-standard
.SILENT: hydrate-local-standard
 hydrate-local-standard:  update-settings-php solr-cores namespaces
	-docker-compose exec -T drupal with-contenv bash -lc "for_all_sites configure_search_api_solr_module"
	-docker-compose exec -T drupal drush -l $(SITE) -y pm:enable responsive_image syslog devel admin_toolbar pdf matomo restui controlled_access_terms_defaults jsonld field_group field_permissions features file_entity view_mode_switch replaywebpage islandora_defaults islandora_marc_countries fico fico_taxonomy_condition openseadragon ableplayer csvfile_formatter archive_list_contents islandora_iiif islandora_display advanced_search media_thumbnails media_thumbnails_pdf media_thumbnails_video media_library_edit migrate_source_csv migrate_tools basic_auth islandora_lite_solr_search islandora_mirador term_condition filemime views_flipped_table islandora_breadcrumbs rest_oai_pmh citation_select asset_injector better_social_sharing_buttons structure_sync islandora_search_processor facets_year_range views_nested_details
	-docker-compose exec -T drupal with-contenv bash -lc "for_all_sites create_solr_core_with_default_config"
	-docker-compose exec -T drupal with-contenv bash -lc "for_all_sites configure_islandora_default_module"
	-docker-compose exec -T drupal with-contenv bash -lc "for_all_sites configure_matomo_module"
	-docker-compose exec -T drupal with-contenv bash -lc "for_all_sites configure_openseadragon"
	-docker-compose exec -T drupal drush -l $(SITE) theme:enable olivero
	-docker-compose exec -T drupal drush -l $(SITE) config:set system.theme default olivero

#.SILENT: local-standard
## Make a local site with codebase directory bind mounted, modeled after sandbox.islandora.ca
local-standard: QUOTED_CURDIR = "$(CURDIR)"
local-standard: generate-secrets
	$(MAKE) download-default-certs ENVIRONMENT=local
	$(MAKE) -B docker-compose.yml ENVIRONMENT=local
	$(MAKE) pull ENVIRONMENT=local
	if [ -z "$$(ls -A $(QUOTED_CURDIR)/codebase)" ]; then \
		docker container run --rm -v $(CURDIR)/codebase:/home/root $(REPOSITORY)/nginx:$(TAG) with-contenv bash -lc 'git clone -b islandora_lite https://github.com/digitalutsc/islandora-sandbox /home/root;'; \
	fi
	$(MAKE) set-files-owner SRC=$(CURDIR)/codebase ENVIRONMENT=local
	docker-compose up -d --remove-orphans
	docker-compose exec -T drupal apk --update add imagemagick
	docker-compose exec -T drupal apk add php7-imagick
	docker-compose restart drupal
	docker-compose exec -T drupal with-contenv bash -lc 'composer install'
	$(MAKE) install ENVIRONMENT=local
	$(MAKE) hydrate-local-standard ENVIRONMENT=local
	docker-compose exec -T drupal with-contenv bash -lc 'drush -y migrate:import --group=islandora'

.PHONY: post-install-scripts
.SILENT: post-install-scripts
post-install-scripts:
	cd $(CURDIR)
	rm -rf  islandora_lite_installation
	git clone https://github.com/digitalutsc/islandora_lite_installation
	rm -rf codebase/islandora_lite_installation
	mv islandora_lite_installation codebase/islandora_lite_installation

	#add to fix issue of failure run Advanced Queue Runner
	docker-compose exec -T drupal apk --no-cache add procps

	-docker-compose exec -T drupal drush -l $(SITE) search-api-disable default_solr_index

	chmod +x codebase/islandora_lite_installation/scripts/*.*
	docker-compose exec -T drupal with-contenv bash -lc "islandora_lite_installation/scripts/post-processing.sh"
	docker-compose exec -T drupal with-contenv bash -lc "islandora_lite_installation/scripts/patches.sh"
	docker-compose exec -T drupal with-contenv bash -lc "islandora_lite_installation/scripts/micro_services.sh docker"
	docker-compose exec -T drupal with-contenv bash -lc "islandora_lite_installation/scripts/partial_config_sych.sh"

	# imagick does not come with the container
	docker-compose exec -T drupal apk --update add php7-imagick
	docker restart isle-dc_drupal_1
	-docker-compose exec -T drupal drush -l $(SITE) -y pm:enable media_thumbnails_tiff

	# ffmpeg needed to create TNs
	docker-compose exec -T drupal apk --update add ffmpeg
	-docker-compose exec -T drupal drush -y config:set media_thumbnails_video.settings ffmpeg /usr/bin/ffmpeg
	-docker-compose exec -T drupal drush -y config:set media_thumbnails_video.settings ffprobe /usr/bin/ffprobe

	# Kyle added: Run scripts for setting up access control
	#docker-compose exec -T drupal with-contenv bash -lc "islandora_lite_installation/scripts/access_control.sh"
