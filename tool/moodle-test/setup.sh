#!/usr/bin/env bash
# Starts the test site from an empty database, installs Moodle with the
# plugins and seeds it. Writes the fixture ids to build/fixture.json.
#
#   tool/moodle-test/setup.sh
set -euo pipefail
cd "$(dirname "$0")"

# eCourse2's versions: Moodle 4.5.3, and the upstream releases nearest the
# plugins it runs. CCU's mod_attendance is a fork of the July 2024 branch;
# its local_mail is the 1.x line, whose web service (get_index, get_menu,
# get_unread_count) the app calls and 2.x replaced.
moodle_tag=v4.5.3
plugins=("mod_attendance 2024072401 mod" "local_mail 2017121408 local")

if [[ ! -f build/moodle/version.php ]]; then
  mkdir -p build
  git clone --quiet --depth 1 --branch "$moodle_tag" https://github.com/moodle/moodle.git build/moodle
  for plugin in "${plugins[@]}"; do
    read -r name version dir <<< "$plugin"
    curl -fsSL -o "build/$name.zip" "https://marketplace.moodle.com/api/plugins/$name/versions/$version/download"
    unzip -q -o "build/$name.zip" -d "build/moodle/$dir"
  done
  # eCourse2 runs in Traditional Chinese, which the app's page parsing reads.
  curl -fsSL -o build/zh_tw.zip https://download.moodle.org/download.php/direct/langpack/4.5/zh_tw.zip
  unzip -q -o build/zh_tw.zip -d build/lang
fi

# The database and data folder are in memory: every run starts empty.
docker compose down --volumes --remove-orphans >/dev/null 2>&1 || true
docker compose up -d --wait
docker compose exec -T -u www-data web php admin/cli/install_database.php --agree-license \
  --adminuser=admin --adminpass='Admin1234!' --adminemail=admin@example.com \
  --fullname='eCourse2 test' --shortname=ecourse2 >/dev/null
docker compose exec -T -u www-data web php /var/www/tatccu-seed.php | tee build/fixture.json
