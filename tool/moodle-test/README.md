# eCourse2 test site

A local Moodle that stands in for eCourse2, so the app's reads and writes can
be tested end to end: forum posts, submission comments, mail and attendance
check-in included.

Versions follow eCourse2:

| Part | Version | Note |
| --- | --- | --- |
| Moodle | 4.5.3 (Build: 20250317) | Same build as eCourse2 |
| mod_attendance | 2024072401 | Upstream release nearest CCU's fork |
| local_mail | 1.9.13 | The 1.x web service the app calls |
| Language | zh_tw | The app parses Chinese attendance pages |

## Running

Requires Docker; OrbStack serves the site at
`https://ecourse2.tatccu.orb.local` with a certificate the Mac trusts.

```bash
tool/moodle-test/setup.sh
```

```bash
flutter test test/moodle_site
```

`setup.sh` downloads Moodle and the plugins into `build/` once, then starts
the site from an empty database, installs it and runs `seed.php`. The
database and data folder live in memory, so every run starts the same. The
fixture ids go to `build/fixture.json`, which the tests read; without it
they are skipped.

`seed.php` creates:

- **Accounts:** `student` and `teacher`, password `Test1234!`.
- **Courses:** two this semester, with the `schedule` and `room` fields, and one last semester.
- **Course content:**
  - an announcement and a discussion;
  - an assignment due in three days, with submission comments on;
  - a quiz and a grade.
- **Mail:** one message to the student.
- **Attendance:** a session open now. Its QR link checks the student in, as
  scanning the classroom code does.

```bash
docker compose -f tool/moodle-test/docker-compose.yml down
```

## Not covered

- **CCU's sign-in:** the real sign-in goes through CAS and Turnstile. The
  tests take a token from `login/token.php`, as the launch flow would hand
  over.
- **CCU's own changes:** changes to mod_attendance and the custom
  mod_absenceform still need checking on eCourse2.
- **The campus systems:** the systems outside Moodle are not part of this
  site.
