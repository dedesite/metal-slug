#!/usr/bin/env -S v run

import os

sprites_ids := map{
	/* Characters */
	'Marco Rossi': 11225,
	'Tarma Roving': 11254,
	/* Slugs */
	'Metal slug': 32521,
	'Wrecked Metal Slugs': 103197,
	// Ennemies
	'Rebel Soldier (Bazooka)': 53578,
	// Backgrounds
	'Mission 1': 36639,
	// Miscellaneous
	'HUD': 29719,
	'Time numbers': 103408,
	'System setup': 23018,
	'Blood': 32528
}

sprites_dir := './sprites'
if !os.exists(sprites_dir) {
	os.mkdir(sprites_dir) ?
}

println("Downloading Sprites from spriters-resource.com")

wget_cmd := 'wget --content-disposition --timestamping --directory-prefix=$sprites_dir'
download_url := 'https://www.spriters-resource.com/download'
for name, download_id in sprites_ids {
	print('\033[0m$name : ')
	res := os.execute('$wget_cmd $download_url/$download_id/')
	if res.exit_code == 0 {
		println('\033[92m✓')
	} else {
		println('\033[91m𐄂')
	}
}
