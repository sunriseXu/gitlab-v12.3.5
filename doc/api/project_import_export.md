# Project import/export API

> [Introduced][ce-41899] in GitLab 10.6.

See also the [project import/export documentation](../user/project/settings/import_export.md).

## Schedule an export

Start a new export.

The endpoint also accepts an `upload` param. This param is a hash that contains
all the necessary information to upload the exported project to a web server or
to any S3-compatible platform. At the moment we only support binary
data file uploads to the final server.

If the `upload` params is present, `upload[url]` param is required.
 (**Note:** This feature was introduced in GitLab 10.7)

```text
POST /projects/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `description`      | string | no | Overrides the project description |
| `upload`      | hash | no | Hash that contains the information to upload the exported project to a web server |
| `upload[url]`      | string | yes      | The URL to upload the project |
| `upload[http_method]`      | string | no      | The HTTP method to upload the exported project. Only `PUT` and `POST` methods allowed. Default is `PUT` |

```sh
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/export \
    --data "upload[http_method]=PUT" \
    --data-urlencode "upload[url]=https://example-bucket.s3.eu-west-3.amazonaws.com/backup?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIMBJHN2O62W8IELQ%2F20180312%2Feu-west-3%2Fs3%2Faws4_request&X-Amz-Date=20180312T110328Z&X-Amz-Expires=900&X-Amz-SignedHeaders=host&X-Amz-Signature=8413facb20ff33a49a147a0b4abcff4c8487cc33ee1f7e450c46e8f695569dbd"
```

```json
{
  "message": "202 Accepted"
}
```

## Export status

Get the status of export.

```text
GET /projects/:id/export
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/export
```

Status can be one of `none`, `started`, `after_export_action` or `finished`. The
`after_export_action` state represents that the export process has been completed successfully and
the platform is performing some actions on the resulted file. For example, sending
an email notifying the user to download the file, uploading the exported file
to a web server, etc.

`_links` are only present when export has finished.

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "export_status": "finished",
  "_links": {
    "api_url": "https://gitlab.example.com/api/v4/projects/1/export/download",
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/download_export",
  }
}
```

## Export download

Download the finished export.

```text
GET /projects/:id/export/download
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" --remote-header-name --remote-name https://gitlab.example.com/api/v4/projects/5/export/download
```

```sh
ls *export.tar.gz
2017-12-05_22-11-148_namespace_project_export.tar.gz
```

## Import a file

```text
POST /projects/import
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `namespace` | integer/string | no | The ID or path of the namespace that the project will be imported to. Defaults to the current user's namespace |
| `file` | string | yes | The file to be uploaded |
| `path` | string | yes | Name and path for new project |
| `overwrite` | boolean | no | If there is a project with the same path the import will overwrite it. Default to false |
| `override_params` | Hash | no | Supports all fields defined in the [Project API](projects.md) |

The override params passed will take precedence over all values defined inside the export file.

To upload a file from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to a file on your file system and be preceded
by `@`. For example:

```sh
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "path=api-project" --form "file=@/path/to/file" https://gitlab.example.com/api/v4/projects/import
```

cURL doesn't support posting a file from a remote server. Importing a project from a remote server can be accomplished through something like the following:

```python
import requests
import urllib
import json
import sys

s3_file = urllib.urlopen(presigned_url)

url =  'https://gitlab.example.com/api/v4/projects/import'
files = {'file': s3_file}
data = {
    "path": "example-project",
    "namespace": "example-group"
}
headers = {
    'Private-Token': "<your_access_token>"
}

requests.post(url, headers=headers, data=data, files=files)
```

```json
{
  "id": 1,
  "description": null,
  "name": "api-project",
  "name_with_namespace": "Administrator / api-project",
  "path": "api-project",
  "path_with_namespace": "root/api-project",
  "created_at": "2018-02-13T09:05:58.023Z",
  "import_status": "scheduled"
}
```

## Import status

Get the status of an import.

```text
GET /projects/:id/import
```

| Attribute | Type           | Required | Description                              |
| --------- | -------------- | -------- | ---------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/import
```

Status can be one of `none`, `scheduled`, `failed`, `started`, or `finished`.

If the status is `failed`, it will include the import error message under `import_error`.

```json
{
  "id": 1,
  "description": "Itaque perspiciatis minima aspernatur corporis consequatur.",
  "name": "Gitlab Test",
  "name_with_namespace": "Gitlab Org / Gitlab Test",
  "path": "gitlab-test",
  "path_with_namespace": "gitlab-org/gitlab-test",
  "created_at": "2017-08-29T04:36:44.383Z",
  "import_status": "started"
}
```

[ce-41899]: https://gitlab.com/gitlab-org/gitlab-foss/issues/41899
