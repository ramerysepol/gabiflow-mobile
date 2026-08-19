#!/usr/bin/env bash
# Guarda a chave de assinatura Android do GabiFlow no cofre AWS:
#   - upload-keystore.jks  -> S3 (bucket privado, criptografado)
#   - key.properties       -> SSM Parameter Store (SecureString)
#
# Roda NO SERVIDOR 192.168.40.50 (perfil aws "gabiflow" válido lá).
# Uso (do seu Mac, dentro de gabiflow-mobile/):
#   ./scripts/guardar-keystore-aws.sh
set -euo pipefail

SERVER="iremar@192.168.40.50"
SSH_KEY="$HOME/.ssh/id_ed25519"
JKS="android/app/upload-keystore.jks"
PROPS="android/key.properties"

[ -f "$JKS" ] || { echo "ERRO: $JKS não encontrado (rode na raiz do gabiflow-mobile)"; exit 1; }
[ -f "$PROPS" ] || { echo "ERRO: $PROPS não encontrado"; exit 1; }

echo "[1/4] Enviando arquivos ao servidor (temporário, modo 600)..."
scp -i "$SSH_KEY" -q "$JKS" "$SERVER:/tmp/gf-upload-keystore.jks"
scp -i "$SSH_KEY" -q "$PROPS" "$SERVER:/tmp/gf-key.properties"

echo "[2/4] Guardando no S3 e SSM (no servidor)..."
ssh -i "$SSH_KEY" "$SERVER" bash -s <<'REMOTE'
set -euo pipefail
export AWS_PROFILE=gabiflow AWS_REGION=us-east-1
chmod 600 /tmp/gf-upload-keystore.jks /tmp/gf-key.properties

CONTA=$(aws sts get-caller-identity --query Account --output text)
BUCKET="gabiflow-cofre-${CONTA}"

# Bucket privado com criptografia (idempotente)
if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  aws s3api create-bucket --bucket "$BUCKET"
  aws s3api put-public-access-block --bucket "$BUCKET" \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
  aws s3api put-bucket-encryption --bucket "$BUCKET" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
  aws s3api put-bucket-versioning --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled
fi

aws s3 cp /tmp/gf-upload-keystore.jks "s3://$BUCKET/mobile/android/upload-keystore.jks" --sse aws:kms

# key.properties inteiro como SecureString (senha nunca aparece em tela)
aws ssm put-parameter \
  --name "/gabiflow/mobile/android-key-properties" \
  --type SecureString \
  --value "file:///tmp/gf-key.properties" \
  --overwrite >/dev/null

rm -f /tmp/gf-upload-keystore.jks /tmp/gf-key.properties
echo "OK: s3://$BUCKET/mobile/android/upload-keystore.jks + SSM /gabiflow/mobile/android-key-properties"
REMOTE

echo "[3/4] Limpando temporários... (já feito no servidor)"
echo "[4/4] Pronto. Para recuperar no futuro:"
echo "  aws s3 cp s3://gabiflow-cofre-<conta>/mobile/android/upload-keystore.jks ."
echo "  aws ssm get-parameter --name /gabiflow/mobile/android-key-properties --with-decryption --query Parameter.Value --output text > key.properties"
