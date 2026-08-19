#!/usr/bin/env bash
# Guarda a chave de assinatura Android do GabiFlow no cofre AWS:
#   - upload-keystore.jks -> S3 pagmeia-v2-prod-files/cofre/gabiflow-mobile/ (criptografado)
#   - key.properties      -> SSM Parameter Store (SecureString)
#
# Conta 600301049827 (mesma do PagMeia). Perfil local: pagmeia-admin.
# Uso (na raiz do gabiflow-mobile): ./scripts/guardar-keystore-aws.sh
set -euo pipefail

export AWS_PROFILE=pagmeia-admin
JKS="android/app/upload-keystore.jks"
PROPS="android/key.properties"
BUCKET="pagmeia-v2-prod-files"

[ -f "$JKS" ] || { echo "ERRO: $JKS não encontrado (rode na raiz do gabiflow-mobile)"; exit 1; }
[ -f "$PROPS" ] || { echo "ERRO: $PROPS não encontrado"; exit 1; }

echo "[1/2] Keystore -> S3 (criptografado)..."
aws s3 cp "$JKS" "s3://$BUCKET/cofre/gabiflow-mobile/upload-keystore.jks" \
  --region sa-east-1 --sse AES256

echo "[2/2] key.properties -> SSM (SecureString, senha nunca aparece na tela)..."
aws ssm put-parameter \
  --region sa-east-1 \
  --name "/gabiflow/mobile/android-key-properties" \
  --type SecureString \
  --value "file://$PROPS" \
  --overwrite >/dev/null

echo ""
echo "Pronto. Para recuperar em outra máquina:"
echo "  aws s3 cp s3://$BUCKET/cofre/gabiflow-mobile/upload-keystore.jks android/app/ --region sa-east-1"
echo "  aws ssm get-parameter --region sa-east-1 --name /gabiflow/mobile/android-key-properties \\"
echo "    --with-decryption --query Parameter.Value --output text > android/key.properties"
