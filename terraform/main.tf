terraform {
  required_version = ">= 1.5.7"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "> 2.23.0"
    }
  }
}

provider "kubernetes" {
  config_path = "C:/Users/owner/.kube/config"  # Ensure this points to your Minikube kubeconfig
}

# Create a Kubernetes namespace for the final project
resource "kubernetes_namespace" "final_project" {
  metadata {
    name = "final-project-devsecops"
  }
}

# Create a deployment with 2 replicas (scalable containers/pods) for the final project
resource "kubernetes_deployment" "final_project_app" {
  metadata {
    name      = "final-project-app"
    namespace = kubernetes_namespace.final_project.metadata[0].name
    labels = {
      app = "final-project-app"
    }
  }

  spec {
    replicas = 2  # Number of containers/pods to run

    selector {
      match_labels = {
        app = "final-project-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "final-project-app"
        }
      }

      spec {
        container {
          name  = "final-project-container"
          image = "oliviertremblaynoel/log8100-projet"
          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

# Create a service to expose the final project app with load balancing
resource "kubernetes_service" "final_project_app" {
  metadata {
    name      = "final-project-service"
    namespace = kubernetes_namespace.final_project.metadata[0].name
  }

  spec {
    selector = {
      app = "final-project-app"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

## ConfigMap pour prometheus.yml
resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.final_project.metadata[0].name
  }

  data = {
    "prometheus.yml" = <<EOT
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "kubernetes-pods"
    static_configs:
      - targets: ["localhost:8080"]

  - job_name: "kube-state-metrics"
    static_configs:
      - targets: ["kube-state-metrics.final-project-devsecops.svc.cluster.local:8080"]
EOT
  }
}

# CHANGEMENT : Ajout du déploiement de Prometheus
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus" # Nom du déploiement
    namespace = kubernetes_namespace.final_project.metadata[0].name
    labels = {
      app = "prometheus" # Étiquette pour identifier les pods
    }
  }

  spec {
    replicas = 1 # Un seul pod pour Prometheus

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          name  = "prometheus" # Nom du conteneur
          image = "prom/prometheus:latest" # Image Docker de Prometheus
          port {
            container_port = 9090 # Port utilisé par Prometheus
          }
          volume_mount { # AJOUTÉ
            name       = "prometheus-config-volume" # AJOUTÉ
            mount_path = "/etc/prometheus/prometheus.yml" # AJOUTÉ
            sub_path   = "prometheus.yml" # AJOUTÉ
          } # AJOUTÉ
        }
        volume { # AJOUTÉ
          name = "prometheus-config-volume" # AJOUTÉ

          config_map { # AJOUTÉ
            name = kubernetes_config_map.prometheus_config.metadata[0].name # AJOUTÉ
          } # AJOUTÉ
        } # AJOUTÉ
      }
    }
  }
}

# CHANGEMENT : Service pour exposer Prometheus
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus-service" # Nom du service
    namespace = kubernetes_namespace.final_project.metadata[0].name
  }

  spec {
    selector = {
      app = "prometheus" # Lie le service au déploiement via l'étiquette
    }

    port {
      port        = 9090 # Port exposé par le service
      target_port = 9090 # Port du conteneur Prometheus
    }

    type = "LoadBalancer" # Permet un accès externe
  }
}

# CHANGEMENT : Ajout du déploiement de Grafana
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana" # Nom du déploiement
    namespace = kubernetes_namespace.final_project.metadata[0].name
    labels = {
      app = "grafana" # Étiquette pour identifier les pods
    }
  }

  spec {
    replicas = 1 # Un seul pod pour Grafana

    selector {
      match_labels = {
        app = "grafana"
      }
    }

    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }

      spec {
        container {
          name  = "grafana" # Nom du conteneur
          image = "grafana/grafana:latest" # Image Docker de Grafana
          port {
            container_port = 3000 # Port utilisé par Grafana
          }
        }
      }
    }
  }
}

# CHANGEMENT : Service pour exposer Grafana
resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana-service" # Nom du service
    namespace = kubernetes_namespace.final_project.metadata[0].name
  }

  spec {
    selector = {
      app = "grafana" # Lie le service au déploiement via l'étiquette
    }

    port {
      port        = 3000 # Port exposé par le service
      target_port = 3000 # Port du conteneur Grafana
    }

    type = "LoadBalancer" # Permet un accès externe
  }
}
