# configure document mimetypes
drush -y --input-format=yaml config:set file_entity.type.document mimetypes "
- text/plain
- application/msword
- application/vnd.ms-excel
- application/pdf
- application/vnd.ms-powerpoint
- application/vnd.oasis.opendocument.text
- application/vnd.oasis.opendocument.spreadsheet
- application/vnd.oasis.opendocument.presentation
- application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
- application/vnd.openxmlformats-officedocument.presentationml.presentation
- application/vnd.openxmlformats-officedocument.wordprocessingml.document
- text/csv
- text/vtt"

drush -y --input-format=yaml config:set file_entity.type.image mimetypes "
- image/*
- image/tiff
- image/tif
- image/jp2"


drush -y config:set field.field.media.document.field_media_document settings.file_extensions "txt rtf doc docx ppt pptx xls xlsx pdf odf odg odp ods odt fodt fods fodp fodg key numbers pages csv vtt"
drush -y config:set field.field.media.image.field_media_image settings.file_extensions "png gif jpg jpeg tif tiff jp2"
drush -y config:set field.field.media.audio.field_media_audio_file settings.file_extensions "mp3 wav aac m4a"

# not sure where to set this in isle-dc
drush -y config:set search_api.server.default_solr_server backend_config.connector_config.core ISLANDORA

# set front page
drush -y config:set system.site page.front "/collections"

drush -y --input-format=yaml config:set core.entity_form_display.media.audio.media_library content "
ableplayer_caption:
  type: file_generic
  weight: 1
  region: content
  settings:
    progress_indicator: throbber
  third_party_settings: {}
bleplayer_caption:
  type: file_generic
  weight: 7
  region: content
  settings:
    progress_indicator: throbber
  third_party_settings: {}
field_media_use:
  type: entity_reference_autocomplete
  weight: 2
  region: content
  settings:
    match_operator: CONTAINS
    match_limit: 10
    size: 60
    placeholder: ''
  third_party_settings: {}
name:
  type: string_textfield
  weight: 0
  region: content
  settings:
    size: 60
    placeholder: ''
  third_party_settings: {}"

drush -y --input-format=yaml config:set core.entity_form_display.media.document.media_library content "
field_media_use:
  type: entity_reference_autocomplete
  weight: 1
  region: content
  settings:
    match_operator: CONTAINS
    match_limit: 10
    size: 60
    placeholder: ''
  third_party_settings: {}
name:
  type: string_textfield
  weight: 0
  region: content
  settings:
    size: 60
    placeholder: ''
  third_party_settings: {}"

drush -y --input-format=yaml config:set core.entity_form_display.media.image.media_library content "
field_media_use:
  type: entity_reference_autocomplete
  weight: 1
  region: content
  settings:
    match_operator: CONTAINS
    match_limit: 10
    size: 60
    placeholder: ''
  third_party_settings: {}
name:
  type: string_textfield
  weight: 0
  region: content
  settings:
    size: 60
    placeholder: ''
  third_party_settings: {}"

drush -y --input-format=yaml config:set core.entity_form_display.media.video.media_library content "
ableplayer_caption:
  type: file_generic
  weight: 1
  region: content
  settings:
    progress_indicator: throbber
  third_party_settings: {}
field_media_use:
  type: entity_reference_autocomplete
  weight: 2
  region: content
  settings:
    match_operator: CONTAINS
    match_limit: 10
    size: 60
    placeholder: ''
  third_party_settings: {}
name:
  type: string_textfield
  weight: 0
  region: content
  settings:
    size: 60
    placeholder: ''
  third_party_settings: {}"
  
