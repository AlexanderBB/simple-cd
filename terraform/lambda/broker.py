import os

import boto3

codebuild = boto3.client('codebuild')


def copy_to_temporary_location(bucket: str, key: str):
    s3_client = boto3.client("s3")

    last_version = s3_client.list_object_versions(
        Bucket=bucket,
        Prefix=key
    )["Versions"][0]["VersionId"]

    new_key = f"tmp/{key}"
    response = s3_client.copy_object(
        ACL="bucket-owner-full-control",
        Bucket=bucket,
        CopySource={"Bucket": bucket, "Key": key, "VersionId": last_version},
        Key=new_key
    )
    return bucket, new_key


def lambda_handler(event, context):
    for record in event["Records"]:
        event_name = record["eventName"]
        bucket_name = record["s3"]["bucket"]["name"]
        object_key = record["s3"]["object"]["key"]

        action = "apply"
        if event_name.startswith("ObjectRemoved"):
            action = "destroy"

        with open(f"buildspecs/{action}.yml") as fh:
            buildspec = fh.read()

        parameters = {
            "projectName": os.environ["CODEBUILD_NAME"],
            "sourceTypeOverride": "S3",
            "sourceLocationOverride": f"{bucket_name}/{object_key}",
            "buildspecOverride": buildspec,
            "sourceVersion": "",
            "environmentVariablesOverride": [
                {
                    "name": "STATE_BUCKET",
                    "value": os.environ["STATE_BUCKET"],
                    "type": "PLAINTEXT"
                },
                {
                    "name": "STATE_KEY_OBJECT",
                    "value": f'{os.environ["TERRAFORM_STATE_PREFIX"]}/'
                             f'{str(object_key).replace(".zip", "")}/'
                             'terraform.tfstate',
                    "type": "PLAINTEXT"
                }
            ]
        }
        if action == "destroy":
            bucket_name, object_key = copy_to_temporary_location(bucket_name, object_key)
            parameters.update({
                "sourceLocationOverride": f"{bucket_name}/{object_key}",
            })

        codebuild.start_build(**parameters)
        print(f"CodeBuild project triggered with buildspec: {buildspec}")
