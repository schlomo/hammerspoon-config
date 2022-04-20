#!/bin/bash -eu
# see https://schlomo.schapiro.org/2017/06/working-with-iam-roles-in-amazon-aws.html
die() { echo 1>&2 "ERROR: $*"  ; exit 1 ; }
info() { echo 1>&2 "INFO: $*" ; }

test "${1:-}" || die "Usage: $0 <role-name | role ARN> [<role-name | role ARN> ...]"

while test "${1:-}" ; do
  role="$1"
  shift

  if [[ "$role" != */* ]] ; then
    role=arn:aws:iam::$(aws sts get-caller-identity --output text --query Account):role/"$role" || \
      die "Could not get your AWS account ID"
  fi
  read -r \
    AWS_ACCESS_KEY_ID \
    AWS_SECRET_ACCESS_KEY \
    AWS_SESSION_TOKEN \
    < <(
      aws sts assume-role --role-arn "$role" --role-session-name "$USER@$HOSTNAME" \
        --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text
      ) \
    || \
      die "Could not assume role $role"
  info "Switched to role $role"
  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
done
echo AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
echo AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN"
echo AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
