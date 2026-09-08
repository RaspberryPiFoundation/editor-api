# Adding projects to the Editor Site database

## Background
Currently, `project`s can be added to the editor site database by running an automated task. This task iterates through the subdirectories of `/project_components`, creating one `project` in the database for each directory. Each subdirectory of `/project_components` contains a combination of `python`, `text`, `csv` and image files as appropriate to the `project`, along with a `project_config.yml` file that specifies metadata related to the `project`.

### Terminology in this document
Please note that in this document, to avoid confusion, `project` refers to an entry in the projects table in the editor database, whereas 'project' refers to a project from the Projects site which could have many associated `project`s, for example, a starter and some finished examples.

## Creating the project directory
Each version of a Projects site 'project' such as a starter or finished example needs its own directory in `/project_components` as they will form separate `project`s in the database. Although the naming of these directories is inconsequential, at the moment they are roughly named in the form `{project_name}_starter` and `{project_name}_example` for the sake of consistency.

Each directory for a `project` should contain copies of the `python` files and any `text`, `csv` and image files that the `project` should contain. Any content reused across multiple `project`s should be duplicated in the relevant directory for each `project`.

### Populating `project_config.yml`
Every directory representing a `project` must contain a `project_config.yml`. This should include the following information:

- `NAME` - the name of the project to be displayed in the header bar on the editor site
- `IDENTIFIER` - words separated by dashes `-`, conventionally three, though the format is not enforced and some existing `project`s use more (for example `editor-scratch-testing-starter`). It must be unique per locale. This will form the end of the URL for the `project` on the editor site. For example, a `project` with `IDENTIFIER` `python-emoji-example` will be available to view at `/projects/python-emoji-example` once the `project` has been entered into the database. Where a `project` also exists in production, use the same `IDENTIFIER` as production so the local and deployed data match.
- `COMPONENTS` - a list of the non-image files associated with the project. There should be exactly one `main.py` per `project`. The entry corresponding to each file should include the following information:
  - `name` - name of the file without the extension
  - `extension` - file extension (without the `.`)
  - `location` - the path to the file within the `project`, generally `{name}.{extension}` since `project` subdirectories are not currently supported
  - `index` - an integer representing the position the file should take in the tabs above the editor, numbered from `0`. Generally `main.py` has been given `index: 0`.
  - `default` - a boolean which if `true`, the file is shown in the editor by default on page load. Only one file should be given `default: true` (generally `main.py`), with all other files in the `project` having `default: false`.
- `IMAGES` - a list of the names of the image files associated with the project, including their extensions. This property can be omitted if the `project` has no images.

An example `project_config.yml` with all of the above properties can be seen [here](https://github.com/RaspberryPiFoundation/editor-api/blob/main/lib/tasks/project_components/persuasive_data_presentation_iss_starter/project_config.yml).

## Scratch (Blocks) projects

Scratch `project`s work differently and need much less configuration. The directory should contain **exactly two files**: the `.sb3` and a `project_config.yml` with three keys.

```yaml
NAME: "Neil the Seal starter"
IDENTIFIER: "neil-the-seal-starter"
TYPE: "code_editor_scratch"
```

Notes:

- Omit `COMPONENTS` and `IMAGES`. The importer discovers the `.sb3` by file extension, and the `.sb3` already contains all of the project's costumes and sounds — they are extracted into shared Scratch assets automatically.
- `TYPE` must be exactly `code_editor_scratch`. Do not use `scratch`, which is reserved for Experience CS projects and is deliberately excluded from the Scratch API endpoints.
- The `.sb3` filename is not significant, but `main.sb3` matches the convention used elsewhere in this directory.
- Keep the directory to just those two files. Any extra file must still be a type the importer recognises, and a stray file such as `.DS_Store` will fail the whole import run rather than just this `project`.

### ⚠️ Do not copy `project_config.yml` from a content repository

Content repositories in `raspberrypilearning` also contain a `project_config.yml` next to their `.sb3`, but it is a **different format**, read by a different code path (the GitHub webhook and `UploadJob`). It uses **lowercase** keys and an extra `build` key:

```yaml
name: "Neil the Seal starter"
identifier: "neil-the-seal-starter"
type: 'code_editor_scratch'
build: true
```

The seeding task in this directory reads **uppercase** keys only. Copying the content-repo version verbatim parses without error, but leaves `NAME`/`IDENTIFIER` unset (and defaults `TYPE` to `python`), so the import will fail validation — retype it in the uppercase form above and drop `build`.

The `.sb3` itself can be copied straight across. For Neil the Seal it came from [`raspberrypilearning/editor-neil-the-seal`](https://github.com/raspberrypilearning/editor-neil-the-seal) at `en/code/neil-the-seal-starter/neil-the-seal-starter.sb3`.

### Making a Scratch project reachable from the Code Club Projects site

projects-ui only opens the editor when the projects-admin record for a 'project' has `direct_to_editor` set and `editor_starter_project` pointing at the `IDENTIFIER` used here. For local development that link is seeded in the projects-admin repository at `db/seeds/006_editor_blocks_projects.rb`. If you add a Scratch `project` here that needs to be reachable through the projects site, it needs a matching entry there.

## Getting the projects created in the database
Please commit the required changes to a branch in the [`editor-api` repository](https://github.com/RaspberryPiFoundation/editor-api/) and create a pull request to merge your branch into `main`. Once merged, we will run the task to create your `project`s in the database.

## Amending existing projects
Existing `project`s can be ammended by updating the content in the directory corresponding to that `project`. Please create a pull request with the required changes as described above and we will ensure they are applied once the pull request has been merged.
