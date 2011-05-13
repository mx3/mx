# Content Licenses - for images and other content, this is the array of legal values, customize for your instance of mx
# Each key requires a corresponding partial in /views/content_licenses
CONTENT_LICENSES = {
  'by_nc_sa_3_0' => {
    :text => 'CC non-commercial, share-alike, with attribution - 3.0',
    :uri => 'http://creativecommons.org/licenses/by-nc-sa/3.0/'}
}

SEX = ['female', 'male', 'gynandromorph', 'queen', 'worker', 'clone', 'unknown', 'other', 'mixed series']
TYPE_TYPES =  ['holotype', 'paratype', 'syntype', 'lectotype', 'neotype', 'paralectotype']


SPECIES_PROFILE_CONTROLLED_VOCABULARY = YAML::load(File.open(File.expand_path('../../authority_files/species_profile_controlled_vocabulary.yml', __FILE__)))
BIOPORTAL_AUTOCOMPLETE_ONTOLOGIES = YAML::load(File.open(File.expand_path('../../authority_files/bioportal_autocomplete.yml', __FILE__)))



