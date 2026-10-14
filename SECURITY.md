# Politique de sécurité

## Signaler une vulnérabilité

Merci de **ne pas ouvrir d'issue publique** pour une faille de sécurité.
Utilisez l'onglet **Security → Report a vulnerability** du dépôt (signalement privé GitHub).
Une réponse sera apportée dans les meilleurs délais.

## Principes appliqués dans ce dépôt

- **Aucun secret dans le code** : secrets dans AWS SSM Parameter Store (KMS) ou Ansible Vault ;
  scan gitleaks en CI et en pre-commit.
- **Aucune clé AWS longue durée** : la CI s'authentifie par OIDC avec un rôle IAM à privilèges minimaux
  ([docs/iam/](docs/iam/)).
- **Chaîne d'approvisionnement** : actions GitHub épinglées par SHA de commit et mises à jour par
  Dependabot, binaires vérifiés par checksum SHA-256 ou signature GPG, dépendances Python épinglées.
- **Moindre privilège** : jeton GitHub en lecture seule par défaut, rôle IAM EC2 limité à CloudWatch
  et SSM, application exécutée par un utilisateur dédié dans un service systemd sandboxé.
- **Accès SSH** : par clé uniquement, limité aux IP d'administration au niveau du Security Group ;
  l'IP du runner CI n'est autorisée que pendant le déploiement.

## Bonnes pratiques pour les contributeurs

- Activer les hooks : `pre-commit install` (détection de clés privées, d'identifiants AWS et de secrets).
- Ne jamais committer `vault.yml` non chiffré, `.vault_pass`, une clé `*.pem` / `id_*` ou un fichier `.env`.
- Ne jamais ouvrir SSH à `0.0.0.0/0` : le rôle `aws_infra` le refuse volontairement.
