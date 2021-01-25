#!/bin/bash
#Download a WP website to a full static version and upload it to the S3 Bucket
#Be sure this file have correct permission (chmod u+r+x wp2static_s3_upload.sh)
#Launch using ./wp2static_s3_upload.sh"

#LOCAL CONFIGURATION (remember to keep the final slash to store all to the relative "date" subdir)
LOCAL_DOWNLOAD_PATH="/home/static_wp/";

#DOMAIN CONFIGURATION
DOMAIN="g20.org";

#WGET PARAMS
EXCLUDED_PATHS="wp-includes,wp-json,/it/wp-json";

#S3 CONFIGURATION
S3_BUCKET_NAME="bucket-name";
S3_FOLDER="/public_html";

#START
clear
echo "WP2Static download a WP website to a full static version and upload it to the S3 Bucket";
echo "";
#CHECK HTTP STATUS CODE (IF WP website have errors the process will abort)
FULL_DOMAIN="https://"$DOMAIN;
echo "1) Check "$FULL_DOMAIN" response";
HTTP_STATUS_CODE_ERR=$(wget --server-response --no-check-certificate --spider --content-on-error=off $FULL_DOMAIN 2>&1 | awk '/^  HTTP/{print $2}');
echo "HTTP Status code: "$HTTP_STATUS_CODE_ERR;
if [ $HTTP_STATUS_CODE_ERR == "200" ] ; then
  echo "Status code is OK";
else 
    echo "Status code is "$HTTP_STATUS_CODE_ERR", exit from script";
    exit 1;
fi
echo "";
#PREPARE DATE AND DIR
DATE=$(date +%d/%m/%Y);
DATE_PATH=$(date +%y%m%d);
STATIC_DOWNLOAD_PATH=$LOCAL_DOWNLOAD_PATH$DATE_PATH;
echo "2) Prepare date(today is "$DATE" so the subdir will be "$DATE_PATH") and the full destination dir ("$STATIC_DOWNLOAD_PATH")";
rm -r $STATIC_DOWNLOAD_PATH;
mkdir -p -v -m755 $STATIC_DOWNLOAD_PATH;
#START DOWNLOAD
echo "";
echo "3) Being download the WP version of "$DOMAIN" to a fully html static version (storing to: "$STATIC_DOWNLOAD_PATH")";
echo "_______________________________________________________________________________________________________________";
echo "";
REFERER="www."$DOMAIN;
WGET_RESULT=$(wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0" --no-check-certificate --restrict-file-names=windows --header "Referer: $REFERER" --domains $DOMAIN -p -x -nH -P $STATIC_DOWNLOAD_PATH -np -k -R php -E -X $EXCLUDED_PATHS -m $FULL_DOMAIN -q --show-progress);
#Recursively empty S3 Bucket
S3_BUCKET_NAME="s3://"$S3_BUCKET_NAME;
S3_FULL_PATH=$S3_BUCKET_NAME$S3_FOLDER;
echo "";
echo "4) Recursively empty S3 Bucket ("$S3_BUCKET_NAME")";
echo "";
aws s3 rm $S3_BUCKET_NAME --recursive
#Upload static version to S3 Bucket
echo "";
echo "5) Uploading "$STATIC_DOWNLOAD_PATH" to "$S3_FULL_PATH"";
echo "";
aws s3 cp $STATIC_DOWNLOAD_PATH $S3_FULL_PATH --acl public-read
echo "";
echo "Script end";
echo "";