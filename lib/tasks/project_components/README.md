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
- `IDENTIFIER` - a unique list of three words separated by dashes `-`. This will form the end of the URL for the `project` on the editor site. For example, a `project` with `IDENTIFIER` `python-emoji-example` will be available to view at `/projects/python-emoji-example` once the `project` has been entered into the database.
- `COMPONENTS` - a list of the non-image files associated with the project. There should be exactly one `main.py` per `project`. The entry corresponding to each file should include the following information:
  - `name` - name of the file without the extension
  - `extension` - file extension (without the `.`)
  - `location` - the path to the file within the `project`, generally `{name}.{extension}` since `project` subdirectories are not currently supported
  - `index` - an integer representing the position the file should take in the tabs above the editor, numbered from `0`. Generally `main.py` has been given `index: 0`.
  - `default` - a boolean which if `true`, the file is shown in the editor by default on page load. Only one file should be given `default: true` (generally `main.py`), with all other files in the `project` having `default: false`.
- `IMAGES` - a list of the names of the image files associated with the project, including their extensions. This property can be omitted if the `project` has no images.

An example `project_config.yml` with all of the above properties can be seen [here](https://github.com/RaspberryPiFoundation/editor-api/blob/main/lib/tasks/project_components/persuasive_data_presentation_iss_starter/project_config.yml)

## Getting the projects created in the database
Please commit the required changes to a branch in the [`editor-api` repository](https://github.com/RaspberryPiFoundation/editor-ui/) and create a pull request to merge your branch into `main`. Once merged, we will run the task to create your `project`s in the database.

## Amending existing projects
Existing `project`s can be ammended by updating the content in the directory corresponding to that `project`. Please create a pull request with the required changes as described above and we will ensure they are applied once the pull request has been merged.
