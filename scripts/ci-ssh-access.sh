#!/usr/bin/env bash
# Ouvre / ferme un accès SSH temporaire pour le runner CI sur le Security Group web.
#
#   scripts/ci-ssh-access.sh open  <env> <cidr>
#   scripts/ci-ssh-access.sh close <env> <cidr>
#
# Le pipeline appelle « open » avant de lancer Ansible et « close » dans une étape
# de nettoyage toujours exécutée : l'IP du runner ne reste jamais autorisée.
set -euo pipefail

ACTION="${1:?usage: $0 open|close <env> <cidr>}"
ENV_NAME="${2:?missing environment (dev|prod)}"
CIDR="${3:?missing CIDR (x.x.x.x/32)}"
PROJECT="${PROJECT_NAME:-ansible-aws-automation}"
REGION="${AWS_REGION:-eu-west-3}"

SG_ID="$(aws ec2 describe-security-groups \
  --region "$REGION" \
  --filters "Name=group-name,Values=${PROJECT}-${ENV_NAME}-web-sg" \
  --query 'SecurityGroups[0].GroupId' --output text)"

if [[ -z "$SG_ID" || "$SG_ID" == "None" ]]; then
  echo "Security group not found yet (first provisioning?) - nothing to do."
  exit 0
fi

PERMISSION="IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=${CIDR},Description=ci-runner-temporary}]"

case "$ACTION" in
  open)
    aws ec2 authorize-security-group-ingress --region "$REGION" --group-id "$SG_ID" \
      --ip-permissions "$PERMISSION" >/dev/null 2>&1 || echo "Rule already present."
    echo "SSH opened for ${CIDR} on ${SG_ID}"
    ;;
  close)
    aws ec2 revoke-security-group-ingress --region "$REGION" --group-id "$SG_ID" \
      --ip-permissions "$PERMISSION" >/dev/null 2>&1 || echo "Rule already absent."
    echo "SSH closed for ${CIDR} on ${SG_ID}"
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    exit 1
    ;;
esac
