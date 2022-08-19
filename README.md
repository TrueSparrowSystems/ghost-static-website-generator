# Ghost Static Site Generator

Generate static HTML files for the custom ghost hosting and publishing them on S3 static website bucket.
To host the static blog site under a path `/blog` (`https://yourdomain.com/blog`), then the ghost needs to be hosted with the same path like `https://content.yourdomain.com/blog`.

If your blog is hosted under `https://content.yourdomain.com` and you want to host the static site under `https://yourdomain.com/blog`, this is not possible. Same applies for the other way around.

## Inputs

## `ghost_hosted_url`

**Required** Ghost hosted URL endpoint. (`ex: https://content.yourdomain.com/blog`)

## `ghost_static_host_url`

**Required** URL endpoint where static files needs to be hosted. (`ex: https://yourdomain.com/blog`)

## `custom_replace_keys`

**Optional** Comma separated list of items that needs to be replaced from the items in custom_replace_values at the same index.

## `custom_replace_values`

**Optional** Comma separated associated values for the item in custom_replace_keys.

## `root_index_jsonld`

**Optional** ld+json data for the root index file.

## `s3_bucket_name`

**Optional** S3 bucket name to upload static HTML files.

## `aws_access_key_id`

**Optional** AWS access key Id.

## `aws_secret_access_key`

**Optional** AWS secret access key.

## `aws_region`

**Optional** AWS region.

## Example usage

```yaml
name: Publish blog posts
uses: bala007/ghost-static-site-generator@main
with:
  ghost_hosted_url: "https://content.yourdomain.com/blog"
  ghost_static_host_url: "https://yourdomain.com/blog"
  s3_bucket_name: "your-s3-bucket-name"
  aws_access_key_id: ${{ secrets.AWS_ACCESS_KEY_ID }} # Accessing it from the gihub secrets
  aws_secret_access_key: ${{ secrets.AWS_SECRET_ACCESS_KEY }} # Accessing it from the gihub secrets
  aws_region: "us-east-1"
  custom_replace_keys: "key_1, key_2, key_n"
  custom_replace_values: "value_1, value_2, value_n"
```

### _Locally build and run with docker_

```bash
docker build -t ghost-ssg .
docker run -it --env-file .env.sample ghost-ssg
```

> Make appropriate chnages to the `.env.sample` file.
> To Persist the generated HTML files in local (host system) directory, use bind mount option with `docker run` command, For example: `-v /path/to/local/dir:/src/content`
