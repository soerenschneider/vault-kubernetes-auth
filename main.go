package main

import (
	"context"
	"fmt"
	vault "github.com/hashicorp/vault/api"
	auth "github.com/hashicorp/vault/api/auth/kubernetes"
	"log"
	"time"
)

var vaultRole = "dev-role-k8s"

func main() {
	path := "/var/run/secrets/kubernetes.io/serviceaccount/token"
	secret, err := getSecretWithKubernetesAuth(path)
	if err != nil {
		log.Printf("Error authenticating: %v\n", err)
	} else {
		log.Println("Vault auth succeeded!")
	}

	log.Printf("Read secret from vault hello=%s\n", secret)

	time.Sleep(5 * time.Minute)
}

func getSecretWithKubernetesAuth(serviceAccountTokenFile string) (string, error) {
	config := vault.DefaultConfig()

	client, err := vault.NewClient(config)
	if err != nil {
		return "", fmt.Errorf("unable to initialize Vault client: %w", err)
	}

	k8sAuth, err := auth.NewKubernetesAuth(
		vaultRole,
		auth.WithServiceAccountTokenPath(serviceAccountTokenFile),
	)
	if err != nil {
		return "", fmt.Errorf("unable to initialize Kubernetes auth method: %w", err)
	}

	authInfo, err := client.Auth().Login(context.TODO(), k8sAuth)
	if err != nil {
		return "", fmt.Errorf("unable to log in with Kubernetes auth: %w", err)
	}
	if authInfo == nil {
		return "", fmt.Errorf("no auth info was returned after login")
	}

	secret, err := client.KVv2("kv").Get(context.Background(), "creds")
	if err != nil {
		return "", fmt.Errorf("unable to read secret: %w", err)
	}

	value, ok := secret.Data["hello"].(string)
	if !ok {
		return "", fmt.Errorf("value type assertion failed: %T %#v", secret.Data["hello"], secret.Data["hello"])
	}

	return value, nil
}
