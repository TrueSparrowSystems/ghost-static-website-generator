#!/usr/bin/env bash

# Following ENV variables are required.
#   - GHOST_STATIC_CONTENT_DIR (set in Dockerfile)
#   - GHOST_HOSTED_URL (something like "https://content.yoursite.com/blog")
#   - GHOST_STATIC_HOST_URL (something like "https://yoursite.com/blog")
# Optional ENV variables:
#   - CUSTOM_REPLACE_KEYS (comma separated list of items that needs to be replaced from the items in CUSTOM_REPLACE_VALUES at the same index)
#   - CUSTOM_REPLACE_VALUES (associated values for the item in CUSTOM_REPLACE_KEYS)
#   - ROOT_INDEX_JSONLD (LD+JSON data that needs to be replaced in root index.html page)
#   - S3_BUCKET_NAME (S3 bucket name to upload static HTML files)
#   - AWS_ACCESS_KEY_ID
#   - AWS_SECRET_ACCESS_KEY
#   - AWS_DEFAULT_REGION

GHOST_HOSTED_DOMAIN_WITH_PATH=$(echo ${GHOST_HOSTED_URL} | cut -d '/' -f 3-)
GHOST_HOSTED_BLOG_PATH=$(echo ${GHOST_HOSTED_URL} | cut -d '/' -f 4-)
GHOST_STATIC_BLOG_DOMAIN=$(echo ${GHOST_STATIC_HOST_URL} | cut -d '/' -f 3- | cut -d '/' -f 1)
GHOST_STATIC_HOST=$(echo ${GHOST_STATIC_HOST_URL} | cut -d '/' -f 1-3)
GHOST_STATIC_BLOG_PATH=$(echo ${GHOST_STATIC_HOST_URL} | cut -d '/' -f 4-)

if [[ -z "${GHOST_HOSTED_URL}" ]]; then
    echo "Error: GHOST_HOSTED_URL is mandatory"
    exit 1
fi

if [[ -z "${GHOST_STATIC_HOST_URL}" ]]; then
    echo "Error: GHOST_STATIC_HOST_URL is mandatory"
    exit 1
fi

if [[ "${GHOST_HOSTED_BLOG_PATH}" != "${GHOST_STATIC_BLOG_PATH}" ]]; then
    echo "Error: Path mismatch. The ${GHOST_HOSTED_URL} and ${GHOST_STATIC_HOST_URL} should end with same path suffix."
    exit 1
fi

echo "###########################################################"
echo "GHOST_HOSTED_URL              : ${GHOST_HOSTED_URL}"
echo "GHOST_HOSTED_BLOG_PATH        : ${GHOST_HOSTED_BLOG_PATH}"
echo "GHOST_STATIC_HOST_URL         : ${GHOST_STATIC_HOST_URL}"
echo "GHOST_STATIC_BLOG_DOMAIN      : ${GHOST_STATIC_BLOG_DOMAIN}"
echo "GHOST_STATIC_HOST             : ${GHOST_STATIC_HOST}"
echo "GHOST_STATIC_BLOG_PATH        : ${GHOST_STATIC_BLOG_PATH}"
echo "###########################################################"

blog_dir="${GHOST_STATIC_CONTENT_DIR}"
s3_blog_path="s3://${S3_BUCKET_NAME}"
if [[ ! -z "${GHOST_STATIC_BLOG_PATH}" ]]; then
    blog_dir="${blog_dir}/${GHOST_STATIC_BLOG_PATH}"
    s3_blog_path="${s3_blog_path}/${GHOST_STATIC_BLOG_PATH}"
fi

if [[ -d ${blog_dir} ]]; then
    rm -rf ${blog_dir}/*
fi

echo " "
echo "***** Started fetching static HTML files *****"
WGET_PATHS=("/" "/sitemap.xml" "/sitemap.xsl" "/sitemap-authors.xml" "/sitemap-pages.xml" "/sitemap-posts.xml" "/sitemap-tags.xml" "/404/" "/public/ghost.css" "/public/ghost.min.css" "/public/404-ghost.png" "/public/404-ghost@2x.png")
for path in ${WGET_PATHS[@]}; do
    url="${GHOST_HOSTED_URL}${path}"
    echo "Generating static HTML files for url : ${url}"
    wget --mirror -p --no-host-directories --timestamping --restrict-file-name=unix --page-requisites --content-on-error --no-parent --directory-prefix ${GHOST_STATIC_CONTENT_DIR} ${url}
done
echo "***** Fetch complete for static HTML files  *****"

find ${GHOST_STATIC_CONTENT_DIR} -name '*?v=*' -exec bash -c 'mv $0 ${0/?v=*/}' {} \;

echo " "
echo "***** Replace text with custom text started *****"
declare -A REPLACE_CONTENT=(
    ["${GHOST_HOSTED_URL}"]="${GHOST_STATIC_HOST_URL}"
    ["\"url\": \"${GHOST_STATIC_HOST_URL}/\""]="\"url\": \"${GHOST_STATIC_HOST}/\""
    ["\"@type\": \"WebSite\""]="\"@type\": \"WebPage\""
)

if [[ ! -z "${GHOST_STATIC_BLOG_PATH}" ]]; then
    REPLACE_CONTENT["${GHOST_STATIC_BLOG_DOMAIN}/${GHOST_STATIC_BLOG_PATH}\""]="${GHOST_STATIC_BLOG_DOMAIN}/${GHOST_STATIC_BLOG_PATH}/\""
fi

for rstring in "${!REPLACE_CONTENT[@]}"; do
    echo "Replace: ${rstring} -> ${REPLACE_CONTENT[${rstring}]}"
    find ${blog_dir} -type f -print0 | xargs -0 sed -i'' "s,${rstring},${REPLACE_CONTENT[${rstring}]},g"
    if [[ $? -ne 0 ]]; then
        echo "Error: Text replace failed"
        exit 1
    fi
done

IFS=',' read -r -a KEYS <<<"$CUSTOM_REPLACE_KEYS"
IFS=',' read -r -a VALUES <<<"$CUSTOM_REPLACE_VALUES"

if [[ ${#KEYS[@]} -ne ${#VALUES[@]} ]]; then
    echo "Error: Invalid environment variables CUSTOM_REPLACE_*. The number of comma separated items should be same in both the ENV variables."
    exit 1
fi

for i in "${!KEYS[@]}"; do
    key=$(echo -e ${KEYS[$i]} | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//')
    val=$(echo -e ${VALUES[$i]} | sed -e 's/^[[:space:]]*//' | sed -e 's/[[:space:]]*$//')
    echo "Custom Replace: ${key} -> ${val}"
    find ${blog_dir} -type f -print0 | xargs -0 sed -i'' "s,${key},${val},g"
    if [[ $? -ne 0 ]]; then
        echo "Error: Text replace failed"
        exit 1
    fi
done
echo "***** Text replace completed *****"

if [[ ! -z "${ROOT_INDEX_JSONLD}" ]]; then
    echo " "
    echo "***** Replace ld+json data in index.html *****"

    sed "/<script type=\"application\/ld+json/,/<\/script>/c\
    <script type=\"application/ld+json\">${ROOT_INDEX_JSONLD}</script>" ${blog_dir}/index.html >${blog_dir}/_index.html
    mv -f ${blog_dir}/_index.html ${blog_dir}/index.html

    echo "***** ld+json data replaced in index.html *****"
fi

if [[ ! -z ${S3_BUCKET_NAME} ]]; then
    echo " "
    echo "***** Started uploading files to S3 *****"
    aws s3 sync ${blog_dir} ${s3_blog_path} --exclude 'public/*' --exclude 'assets/*' --acl public-read --cache-control "no-store, no-cache, max-age=0, must-revalidate, post-check=0, pre-check=0" --delete
    if [[ $? -ne 0 ]]; then
        echo "Error: S3 upload error"
        exit 1
    fi
    aws s3 sync ${blog_dir}/public ${s3_blog_path}/public --acl public-read --cache-control "public, max-age=604800, must-revalidate" --delete
    aws s3 sync ${blog_dir}/assets ${s3_blog_path}/assets --acl public-read --cache-control "public, max-age=604800, must-revalidate" --delete
    echo "***** S3 upload complete *****"
else
    echo " "
    echo "If you want to upload the static site files to S3, provide following ENV variables: S3_BUCKET_NAME, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION"
fi

echo " "
echo "***** FINISHED SUCCESFULLY *****"

