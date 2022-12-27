resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "example" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://kubernetes.default.svc:443"
  kubernetes_ca_cert     = var.kubernetes_ca_cert
  token_reviewer_jwt     = var.kubernetes_jwt
  disable_iss_validation = true
}

resource "vault_kubernetes_auth_backend_role" "example" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "dev-role-k8s"
  bound_service_account_names      = ["*"]
  bound_service_account_namespaces = ["default"]
  token_ttl                        = 3600
  token_policies                   = ["default", "developer"]
  audience                         = "https://kubernetes.default.svc.cluster.local"
}

resource "vault_policy" "bla" {
  name = "developer"

  policy = <<EOT
path "kv/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_mount" "kvv2" {
  path        = "kv"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "secret" {
  mount                      = vault_mount.kvv2.path
  name                       = "creds"
  cas                        = 1
  delete_all_versions        = true
  data_json                  = jsonencode(
    {
      hello       = "world"
    }
  )
}